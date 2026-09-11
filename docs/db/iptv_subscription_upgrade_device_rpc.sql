-- Trusted RPC for upgrading/adding devices to an active Costik IPTV subscription.
-- Charges customer wallet based on additional devices x Rp15.000 x current billing cycle months.
-- Updates subscription.device_count, inserts wallet_transactions and invoices atomically.

create or replace function public.upgrade_iptv_subscription_devices(
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
  v_device_count int;
  v_billing_cycle_months int;
  v_unit_price numeric := 15000;
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

  select device_count, billing_cycle_months
  into v_device_count, v_billing_cycle_months
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
      and product_id = 'costik-iptv'
  ) then
    raise exception 'Selected subscription is not Costik IPTV';
  end if;

  if not exists (
    select 1
    from public.subscriptions
    where id = target_subscription_id
      and user_id = v_user_id
      and status = 'active'
  ) then
    raise exception 'Only active IPTV subscriptions can be upgraded';
  end if;

  v_total_amount := additional_device_count * v_unit_price * v_billing_cycle_months;

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
    'Costik IPTV device upgrade: +' || additional_device_count::text || ' device',
    'completed'
  ) returning id into v_transaction_id;

  v_invoice_number := 'IPTV-UPGRADE-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || left(target_subscription_id::text, 8);

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
    total_amount = v_total_amount,
    updated_at = now()
  where id = target_subscription_id
    and user_id = v_user_id;
end;
$$;

revoke all on function public.upgrade_iptv_subscription_devices(uuid, int) from public;
grant execute on function public.upgrade_iptv_subscription_devices(uuid, int) to authenticated;
