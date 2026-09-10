-- Trusted RPC for IPTV subscription checkout.
-- Customer calls this after wallet balance has been funded by payment gateway webhook.
-- Function validates balance, deducts wallet, creates licence, subscription, transaction, and invoice atomically.

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

revoke all on function public.checkout_iptv_subscription(integer, integer) from public;
grant execute on function public.checkout_iptv_subscription(integer, integer) to authenticated;
