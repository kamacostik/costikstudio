-- Trusted RPCs for Costik Signage subscription lifecycle.
-- Mirrors docs/db/iptv_subscription_{renewal,upgrade_device,cancel,reactivate}_rpc.sql
-- but scoped to product_id = 'costik-signage' and its 20rb/device pricing
-- (read from products.price_per_device, seeded by seed_signage_product.sql).

-- 1) Renew / extend an active Signage subscription.
create or replace function public.renew_signage_subscription(
  target_subscription_id uuid,
  billing_cycle_months integer default 1
)
returns table (
  subscription_id uuid,
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
  target_subscription public.subscriptions%rowtype;
  product public.products%rowtype;
  current_balance numeric;
  total_amount numeric;
  inserted_transaction_id uuid;
  inserted_invoice_id uuid;
  next_expires_at timestamp with time zone;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if target_subscription_id is null then
    raise exception 'Subscription id is required';
  end if;

  if billing_cycle_months is null or billing_cycle_months <= 0 then
    raise exception 'Billing cycle must be greater than zero';
  end if;

  select *
    into target_subscription
  from public.subscriptions
  where id = target_subscription_id
    and user_id = current_user_id
  for update;

  if target_subscription.id is null then
    raise exception 'Subscription not found for current user';
  end if;

  if target_subscription.product_id <> 'costik-signage' then
    raise exception 'Selected subscription is not Costik Signage';
  end if;

  if target_subscription.status <> 'active' then
    raise exception 'Only active Signage subscriptions can be renewed';
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

  total_amount := product.price_per_device * target_subscription.device_count * billing_cycle_months;

  if current_balance < total_amount then
    raise exception 'Insufficient wallet balance';
  end if;

  next_expires_at := greatest(target_subscription.expires_at, now()) + make_interval(months => billing_cycle_months);

  update public.wallets
  set
    balance = current_balance - total_amount,
    updated_at = now()
  where user_id = current_user_id;

  update public.subscriptions
  set
    billing_cycle_months = renew_signage_subscription.billing_cycle_months,
    total_amount = total_amount,
    status = 'active',
    expires_at = next_expires_at,
    updated_at = now()
  where id = target_subscription.id;

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
    'Costik Signage subscription renewal',
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
    'SIGNAGE-RENEW-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || left(target_subscription.id::text, 8),
    total_amount,
    'paid',
    now()
  ) returning id into inserted_invoice_id;

  return query
  select
    target_subscription.id,
    inserted_transaction_id,
    inserted_invoice_id,
    current_balance - total_amount,
    next_expires_at;
end;
$$;

revoke all on function public.renew_signage_subscription(uuid, integer) from public;
grant execute on function public.renew_signage_subscription(uuid, integer) to authenticated;

-- 2) Upgrade / add screens, prorated by remaining active days.
create or replace function public.upgrade_signage_subscription_devices(
  target_subscription_id uuid,
  additional_device_count int
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_product public.products%rowtype;
  v_device_count int;
  v_expires_at timestamp with time zone;
  v_remaining_days int;
  v_total_amount numeric;
  v_wallet_balance numeric;
  v_new_balance numeric;
  v_transaction_id uuid;
  v_invoice_number text;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'User not authenticated';
  end if;

  if additional_device_count is null or additional_device_count <= 0 then
    raise exception 'Additional device count must be greater than zero';
  end if;

  select device_count, expires_at
  into v_device_count, v_expires_at
  from public.subscriptions
  where id = target_subscription_id
    and user_id = v_user_id;

  if not found then
    raise exception 'Subscription not found for current user';
  end if;

  if not exists (
    select 1
    from public.subscriptions
    where id = target_subscription_id
      and user_id = v_user_id
      and product_id = 'costik-signage'
  ) then
    raise exception 'Selected subscription is not Costik Signage';
  end if;

  if not exists (
    select 1
    from public.subscriptions
    where id = target_subscription_id
      and user_id = v_user_id
      and status = 'active'
  ) then
    raise exception 'Only active Signage subscriptions can be upgraded';
  end if;

  select *
    into v_product
  from public.products
  where id = 'costik-signage';

  if v_product.id is null then
    raise exception 'Costik Signage product is not configured';
  end if;

  v_remaining_days := greatest(1, ceil(extract(epoch from (v_expires_at - now())) / 86400)::int);
  v_total_amount := ceil(additional_device_count * v_product.price_per_device * v_remaining_days / 30);

  select balance into v_wallet_balance
  from public.wallets
  where user_id = v_user_id
  for update;

  if v_wallet_balance is null then
    raise exception 'Wallet not found';
  end if;

  if v_wallet_balance < v_total_amount then
    raise exception 'Insufficient wallet balance';
  end if;

  v_new_balance := v_wallet_balance - v_total_amount;

  update public.wallets
  set balance = v_new_balance,
      updated_at = now()
  where user_id = v_user_id;

  insert into public.wallet_transactions (
    user_id,
    type,
    amount,
    description,
    status
  ) values (
    v_user_id,
    'purchase',
    v_total_amount,
    'Costik Signage device upgrade: +' || additional_device_count::text || ' layar, prorata ' || v_remaining_days::text || ' hari',
    'completed'
  ) returning id into v_transaction_id;

  v_invoice_number := 'SIGNAGE-UPGRADE-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || left(target_subscription_id::text, 8);

  insert into public.invoices (
    user_id,
    transaction_id,
    invoice_number,
    amount,
    status,
    issued_at
  ) values (
    v_user_id,
    v_transaction_id,
    v_invoice_number,
    v_total_amount,
    'paid',
    now()
  );

  update public.subscriptions
  set
    device_count = v_device_count + additional_device_count,
    updated_at = now()
  where id = target_subscription_id
    and user_id = v_user_id;
end;
$$;

revoke all on function public.upgrade_signage_subscription_devices(uuid, int) from public;
grant execute on function public.upgrade_signage_subscription_devices(uuid, int) to authenticated;

-- 3) Cancel an active Signage subscription.
create or replace function public.cancel_signage_subscription(
  target_subscription_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'User not authenticated';
  end if;

  update public.subscriptions
  set status = 'cancelled',
      updated_at = now()
  where id = target_subscription_id
    and user_id = v_user_id
    and product_id = 'costik-signage';

  if not found then
    raise exception 'Signage subscription not found or not owned by user';
  end if;
end;
$$;

revoke all on function public.cancel_signage_subscription(uuid) from public;
grant execute on function public.cancel_signage_subscription(uuid) to authenticated;

-- 4) Reactivate a cancelled Signage subscription (no charge).
create or replace function public.reactivate_signage_subscription(
  target_subscription_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target_subscription public.subscriptions%rowtype;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if target_subscription_id is null then
    raise exception 'Subscription id is required';
  end if;

  select *
    into target_subscription
  from public.subscriptions
  where id = target_subscription_id
    and user_id = current_user_id
  for update;

  if target_subscription.id is null then
    raise exception 'Subscription not found for current user';
  end if;

  if target_subscription.product_id <> 'costik-signage' then
    raise exception 'Selected subscription is not Costik Signage';
  end if;

  if target_subscription.status = 'active' then
    return;
  end if;

  if target_subscription.status <> 'cancelled' then
    raise exception 'Only cancelled Signage subscriptions can be reactivated';
  end if;

  update public.subscriptions
  set
    status = 'active',
    updated_at = now()
  where id = target_subscription.id;
end;
$$;

revoke all on function public.reactivate_signage_subscription(uuid) from public;
grant execute on function public.reactivate_signage_subscription(uuid) to authenticated;
