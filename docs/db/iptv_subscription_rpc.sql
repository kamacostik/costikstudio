-- Trusted RPC for IPTV subscription checkout.
-- Customer calls this after wallet balance has been funded by payment gateway webhook.
-- Function validates balance, calculates volume/voucher discounts, deducts wallet,
-- creates licence, subscription, transaction, invoice, and promo redemption atomically.

create or replace function public.checkout_iptv_subscription(
  device_count integer,
  billing_cycle_months integer default 1,
  p_auto_renew boolean default false,
  p_include_video_addon boolean default false,
  p_voucher_code text default null
)
returns table (
  subscription_id uuid,
  licence_id uuid,
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
  base_subtotal numeric;
  volume_discount_percent numeric := 0;
  volume_discount_amount numeric := 0;
  subtotal_after_volume numeric;
  voucher_discount_percent numeric := 0;
  voucher_discount_amount numeric := 0;
  addon_total numeric := 0;
  total_amount numeric;
  promo_redemption_count integer := 0;
  user_redemption_count integer := 0;
  user_paid_subscription_count integer := 0;
  inserted_licence_id uuid;
  inserted_subscription_id uuid;
  inserted_transaction_id uuid;
  inserted_invoice_id uuid;
  subscription_expires_at timestamp with time zone;
  iptv_media_limits jsonb := jsonb_build_object(
    'media_storage_limit_mb', 500,
    'image_upload_enabled', true,
    'video_upload_enabled', false,
    'video_max_file_size_mb', 30,
    'video_max_duration_seconds', 30,
    'video_active_limit', 0
  );
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

  select *
    into product
  from public.products
  where id = 'costik-iptv';

  if product.id is null then
    raise exception 'Costik IPTV product is not configured';
  end if;

  iptv_media_limits := iptv_media_limits || coalesce(product.metadata, '{}'::jsonb);

  select coalesce(pvd.discount_percent, 0)
    into volume_discount_percent
  from public.product_volume_discounts pvd
  where pvd.product_id = product.id
    and pvd.is_active = true
    and pvd.min_quantity <= device_count
  order by pvd.min_quantity desc
  limit 1;

  volume_discount_percent := coalesce(volume_discount_percent, 0);
  base_subtotal := product.price_per_device * device_count * billing_cycle_months;
  volume_discount_amount := round(base_subtotal * volume_discount_percent / 100);
  subtotal_after_volume := base_subtotal - volume_discount_amount;

  if p_include_video_addon then
    addon_total := 50000 * billing_cycle_months;
    iptv_media_limits := iptv_media_limits || jsonb_build_object(
      'media_storage_limit_mb', 2000,
      'image_upload_enabled', true,
      'video_upload_enabled', true,
      'video_max_file_size_mb', 100,
      'video_max_duration_seconds', 120,
      'video_active_limit', 2
    );
  end if;

  if normalized_voucher is not null then
    select *
      into promo
    from public.promo_codes pc
    where pc.code = normalized_voucher
      and pc.is_active = true
      and (pc.product_id is null or pc.product_id = product.id)
      and (pc.starts_at is null or pc.starts_at <= now())
      and (pc.ends_at is null or pc.ends_at >= now())
    limit 1;

    if promo.id is null then
      raise exception 'Voucher code is invalid or expired';
    end if;

    select count(*)
      into promo_redemption_count
    from public.promo_redemptions pr
    where pr.promo_code_id = promo.id;

    if promo.max_redemptions is not null
       and promo_redemption_count >= promo.max_redemptions then
      raise exception 'Voucher redemption limit reached';
    end if;

    select count(*)
      into user_redemption_count
    from public.promo_redemptions pr
    where pr.promo_code_id = promo.id
      and pr.user_id = current_user_id;

    if user_redemption_count >= promo.max_redemptions_per_user then
      raise exception 'Voucher has already been used';
    end if;

    if promo.new_customer_only then
      select count(*)
        into user_paid_subscription_count
      from public.subscriptions s
      where s.user_id = current_user_id
        and s.product_id = product.id
        and s.status in ('active', 'expired', 'cancelled');

      if user_paid_subscription_count > 0 then
        raise exception 'Voucher is only available for new customers';
      end if;
    end if;

    voucher_discount_percent := promo.discount_percent;
    voucher_discount_amount := round(subtotal_after_volume * voucher_discount_percent / 100);
  end if;

  total_amount := subtotal_after_volume - voucher_discount_amount + addon_total;

  insert into public.wallets (user_id, balance)
  values (current_user_id, 0)
  on conflict (user_id) do nothing;

  select wallets.balance
    into current_balance
  from public.wallets
  where wallets.user_id = current_user_id
  for update;

  if current_balance < total_amount then
    raise exception 'Insufficient wallet balance';
  end if;

  subscription_expires_at := now() + make_interval(months => billing_cycle_months);

  update public.wallets
  set
    balance = current_balance - total_amount,
    updated_at = now()
  where user_id = current_user_id;

  insert into public.licences (
    user_id,
    start_date,
    expired_date,
    device_count
  ) values (
    current_user_id,
    now(),
    subscription_expires_at,
    device_count
  ) returning id into inserted_licence_id;

  insert into public.subscriptions (
    user_id,
    product_id,
    licence_id,
    device_count,
    billing_cycle_months,
    total_amount,
    status,
    starts_at,
    expires_at,
    auto_renew,
    media_limits
  ) values (
    current_user_id,
    product.id,
    inserted_licence_id,
    device_count,
    billing_cycle_months,
    total_amount,
    'active',
    now(),
    subscription_expires_at,
    p_auto_renew,
    iptv_media_limits || jsonb_build_object(
      'pricing', jsonb_build_object(
        'base_subtotal', base_subtotal,
        'volume_discount_percent', volume_discount_percent,
        'volume_discount_amount', volume_discount_amount,
        'voucher_code', normalized_voucher,
        'voucher_discount_percent', voucher_discount_percent,
        'voucher_discount_amount', voucher_discount_amount,
        'addon_total', addon_total,
        'final_total', total_amount
      )
    )
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
    'Costik IPTV subscription checkout' ||
      case when normalized_voucher is null then '' else ' voucher ' || normalized_voucher end,
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
    'IPTV-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || left(inserted_subscription_id::text, 8),
    total_amount,
    'paid',
    now()
  ) returning id into inserted_invoice_id;

  if promo.id is not null then
    insert into public.promo_redemptions (
      promo_code_id,
      user_id,
      product_id,
      subscription_id,
      invoice_id,
      discount_amount
    ) values (
      promo.id,
      current_user_id,
      product.id,
      inserted_subscription_id,
      inserted_invoice_id,
      voucher_discount_amount
    );
  end if;

  return query
  select
    inserted_subscription_id,
    inserted_licence_id,
    inserted_transaction_id,
    inserted_invoice_id,
    current_balance - total_amount,
    subscription_expires_at;
end;
$$;

revoke all on function public.checkout_iptv_subscription(integer, integer, boolean, boolean, text) from public;
grant execute on function public.checkout_iptv_subscription(integer, integer, boolean, boolean, text) to authenticated;
