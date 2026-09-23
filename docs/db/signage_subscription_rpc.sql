-- Trusted RPC for Costik Signage subscription checkout.
-- Customer calls this after wallet balance has been funded.
-- Function validates balance, deducts wallet, creates subscription, transaction, invoice,
-- and provisions the user's Signage tenant/profile in one transaction.

create or replace function public.checkout_signage_subscription(
  device_count integer,
  billing_cycle_months integer default 1,
  p_auto_renew boolean default false,
  p_voucher_code text default null
)
returns table (
  subscription_id uuid,
  tenant_id uuid,
  transaction_id uuid,
  invoice_id uuid,
  new_balance numeric,
  expires_at timestamp with time zone
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  product public.products%rowtype;
  promo public.promo_codes%rowtype;
  normalized_voucher text := nullif(upper(trim(coalesce(p_voucher_code, ''))), '');
  current_balance numeric;
  total_amount numeric;
  voucher_discount_amount numeric := 0;
  promo_redemption_count integer := 0;
  user_redemption_count integer := 0;
  inserted_subscription_id uuid;
  inserted_transaction_id uuid;
  inserted_invoice_id uuid;
  subscription_expires_at timestamp with time zone;
  profile_company text;
  profile_name text;
  current_tenant_id uuid;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if device_count is null or device_count <= 0 then
    raise exception 'Device count must be greater than zero';
  end if;

  if billing_cycle_months is null or billing_cycle_months <= 0 then
    raise exception 'Billing cycle must be greater than zero';
  end if;

  if exists (
    select 1
    from public.subscriptions s
    where s.user_id = current_user_id
      and s.product_id = 'costik-signage'
      and s.status in ('active', 'cancelled')
  ) then
    raise exception 'Costik Signage subscription already exists';
  end if;

  select *
    into product
  from public.products
  where id = 'costik-signage';

  if product.id is null then
    raise exception 'Costik Signage product is not configured';
  end if;

  insert into public.wallets (user_id, balance)
  values (current_user_id, 0)
  on conflict (user_id) do nothing;

  select wallets.balance
    into current_balance
  from public.wallets
  where wallets.user_id = current_user_id
  for update;

  total_amount := product.price_per_device * device_count * billing_cycle_months;

  if normalized_voucher is not null then
    select *
      into promo
    from public.promo_codes pc
    where pc.code = normalized_voucher
      and pc.is_active = true
      and (pc.starts_at is null or pc.starts_at <= now())
      and (pc.ends_at is null or pc.ends_at >= now());

    if promo.id is null then
      raise exception 'Voucher code is invalid or expired';
    end if;

    if promo.product_id != 'costik-signage' then
      raise exception 'Voucher code is not valid for this product';
    end if;

    select count(*)
      into promo_redemption_count
    from public.promo_redemptions pr
    where pr.promo_code_id = promo.id;

    if promo.max_redemptions is not null
       and promo_redemption_count >= promo.max_redemptions then
      raise exception 'Voucher code redemption limit reached';
    end if;

    select count(*)
      into user_redemption_count
    from public.promo_redemptions pr
    where pr.promo_code_id = promo.id
      and pr.user_id = current_user_id;

    if user_redemption_count >= promo.max_redemptions_per_user then
      raise exception 'You have reached the maximum redemptions for this voucher';
    end if;

    -- For HITAINTIM specific rule or generally checking fixed_price vs percentage
    if promo.fixed_price is not null then
      if device_count != 1 or billing_cycle_months != 12 then
        raise exception 'Voucher code is only valid for 1 device and 12 months billing cycle';
      end if;
      voucher_discount_amount := total_amount - promo.fixed_price;
      if voucher_discount_amount < 0 then
        voucher_discount_amount := 0;
      end if;
    else
      voucher_discount_amount := round(total_amount * promo.discount_percent / 100);
    end if;
  end if;

  total_amount := total_amount - voucher_discount_amount;

  if current_balance < total_amount then
    raise exception 'Insufficient wallet balance';
  end if;

  subscription_expires_at := now() + make_interval(months => billing_cycle_months);

  select p.company_name, p.full_name
    into profile_company, profile_name
  from public.profiles p
  where p.id = current_user_id;

  select sp.tenant_id
    into current_tenant_id
  from public.sg_profiles sp
  where sp.id = current_user_id;

  if current_tenant_id is null then
    insert into public.sg_tenants (name)
    values (coalesce(nullif(profile_company, ''), nullif(profile_name, ''), 'Costik Signage Tenant'))
    returning id into current_tenant_id;

    insert into public.sg_profiles (id, tenant_id, role, full_name)
    values (
      current_user_id,
      current_tenant_id,
      'owner',
      coalesce(nullif(profile_name, ''), nullif(profile_company, ''), 'Costik Signage Owner')
    );
  end if;

  update public.wallets
  set
    balance = current_balance - total_amount,
    updated_at = now()
  where user_id = current_user_id;

  insert into public.subscriptions (
    user_id,
    product_id,
    device_count,
    billing_cycle_months,
    total_amount,
    status,
    starts_at,
    expires_at,
    auto_renew
  ) values (
    current_user_id,
    product.id,
    device_count,
    billing_cycle_months,
    total_amount,
    'active',
    now(),
    subscription_expires_at,
    p_auto_renew
  ) returning id into inserted_subscription_id;

  insert into public.wallet_transactions (
    user_id,
    type,
    amount,
    description,
    status
  ) values (
    current_user_id,
    'purchase',
    total_amount,
    'Costik Signage subscription checkout',
    'completed'
  ) returning id into inserted_transaction_id;

  insert into public.invoices (
    user_id,
    transaction_id,
    invoice_number,
    amount,
    status,
    issued_at
  ) values (
    current_user_id,
    inserted_transaction_id,
    'SIGNAGE-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || left(inserted_subscription_id::text, 8),
    total_amount,
    'paid',
    now()
  ) returning id into inserted_invoice_id;

  if promo.id is not null then
    insert into public.promo_redemptions (
      user_id,
      promo_code_id,
      product_id,
      subscription_id,
      invoice_id,
      discount_amount
    ) values (
      current_user_id,
      promo.id,
      product.id,
      inserted_subscription_id,
      inserted_invoice_id,
      voucher_discount_amount
    );
  end if;

  return query
  select
    inserted_subscription_id,
    current_tenant_id,
    inserted_transaction_id,
    inserted_invoice_id,
    current_balance - total_amount,
    subscription_expires_at;
end;
$$;

revoke all on function public.checkout_signage_subscription(integer, integer, boolean, text) from public;
grant execute on function public.checkout_signage_subscription(integer, integer, boolean, text) to authenticated;
