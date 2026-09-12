-- Auto-renew flag for SaaS subscriptions (IPTV + Signage).
-- Run this in Supabase SQL Editor AFTER schema_iptv.sql,
-- iptv_subscription_rpc.sql, and signage_subscription_rpc.sql.
-- Checkout forms send p_auto_renew; billing dashboard can toggle it
-- later via set_subscription_auto_renew. Actual monthly charging still
-- needs a scheduler (pg_cron / edge function) reading this flag.

alter table public.subscriptions
  add column if not exists auto_renew boolean not null default false;

-- IPTV checkout with auto-renew flag (3-arg overload).
create or replace function public.checkout_iptv_subscription(
  device_count integer,
  billing_cycle_months integer default 1,
  p_auto_renew boolean default false
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
  current_balance numeric;
  total_amount numeric;
  inserted_licence_id uuid;
  inserted_subscription_id uuid;
  inserted_transaction_id uuid;
  inserted_invoice_id uuid;
  subscription_expires_at timestamp with time zone;
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

  insert into public.wallets (user_id, balance)
  values (current_user_id, 0)
  on conflict (user_id) do nothing;

  select wallets.balance
    into current_balance
  from public.wallets
  where wallets.user_id = current_user_id
  for update;

  total_amount := product.price_per_device * device_count * billing_cycle_months;

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
    auto_renew,
    status,
    starts_at,
    expires_at
  ) values (
    current_user_id,
    product.id,
    inserted_licence_id,
    device_count,
    billing_cycle_months,
    total_amount,
    coalesce(p_auto_renew, false),
    'active',
    now(),
    subscription_expires_at
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
    'Costik IPTV subscription checkout',
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

-- Backwards-compatible IPTV checkout wrapper (existing 2-arg callers).
create or replace function public.checkout_iptv_subscription(
  device_count integer,
  billing_cycle_months integer default 1
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
begin
  return query
  select *
  from public.checkout_iptv_subscription(
    checkout_iptv_subscription.device_count,
    checkout_iptv_subscription.billing_cycle_months,
    false
  );
end;
$$;

-- Signage checkout with auto-renew flag (3-arg overload).
create or replace function public.checkout_signage_subscription(
  device_count integer,
  billing_cycle_months integer default 1,
  p_auto_renew boolean default false
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
  current_balance numeric;
  total_amount numeric;
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
    auto_renew,
    status,
    starts_at,
    expires_at
  ) values (
    current_user_id,
    product.id,
    device_count,
    billing_cycle_months,
    total_amount,
    coalesce(p_auto_renew, false),
    'active',
    now(),
    subscription_expires_at
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

-- Backwards-compatible Signage checkout wrapper (existing 2-arg callers).
create or replace function public.checkout_signage_subscription(
  device_count integer,
  billing_cycle_months integer default 1
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
begin
  return query
  select *
  from public.checkout_signage_subscription(
    checkout_signage_subscription.device_count,
    checkout_signage_subscription.billing_cycle_months,
    false
  );
end;
$$;

-- Toggle auto-renew on an existing subscription (owner only).
create or replace function public.set_subscription_auto_renew(
  target_subscription_id uuid,
  enable_auto_renew boolean default true
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if target_subscription_id is null then
    raise exception 'Subscription id is required';
  end if;

  update public.subscriptions
  set
    auto_renew = coalesce(enable_auto_renew, false),
    updated_at = now()
  where id = target_subscription_id
    and user_id = current_user_id;

  if not found then
    raise exception 'Subscription not found for current user';
  end if;
end;
$$;

revoke all on function public.checkout_iptv_subscription(integer, integer, boolean) from public;
grant execute on function public.checkout_iptv_subscription(integer, integer, boolean) to authenticated;
revoke all on function public.checkout_iptv_subscription(integer, integer) from public;
grant execute on function public.checkout_iptv_subscription(integer, integer) to authenticated;
revoke all on function public.checkout_signage_subscription(integer, integer, boolean) from public;
grant execute on function public.checkout_signage_subscription(integer, integer, boolean) to authenticated;
revoke all on function public.checkout_signage_subscription(integer, integer) from public;
grant execute on function public.checkout_signage_subscription(integer, integer) to authenticated;
revoke all on function public.set_subscription_auto_renew(uuid, boolean) from public;
grant execute on function public.set_subscription_auto_renew(uuid, boolean) to authenticated;
