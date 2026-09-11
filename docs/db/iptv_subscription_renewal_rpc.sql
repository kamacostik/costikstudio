-- Trusted RPC for renewing/extending an active Costik IPTV subscription.
-- Customer pays from wallet balance; function extends expiry, writes wallet transaction and invoice atomically.

create or replace function public.renew_iptv_subscription(
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
    and product_id = 'costik-iptv'
  for update;

  if target_subscription.id is null then
    raise exception 'Active IPTV subscription not found';
  end if;

  if target_subscription.status <> 'active' then
    raise exception 'Only active IPTV subscriptions can be renewed';
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
    billing_cycle_months = renew_iptv_subscription.billing_cycle_months,
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
    'Costik IPTV subscription renewal',
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
    'IPTV-RENEW-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || left(target_subscription.id::text, 8),
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

revoke all on function public.renew_iptv_subscription(uuid, integer) from public;
grant execute on function public.renew_iptv_subscription(uuid, integer) to authenticated;
