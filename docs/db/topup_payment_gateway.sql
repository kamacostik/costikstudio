-- Payment gateway-ready top-up flow.
-- Flutter creates a pending payment order. A trusted webhook marks it paid and applies wallet balance.

create table if not exists public.payment_orders (
  id uuid not null default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null default 'manual',
  provider_order_id text null unique,
  external_reference text not null unique default gen_random_uuid()::text,
  type text not null default 'wallet_topup',
  amount numeric(15, 2) not null check (amount > 0),
  status text not null default 'pending',
  payment_url text null,
  raw_payload jsonb null,
  created_at timestamp with time zone default now(),
  paid_at timestamp with time zone null,
  updated_at timestamp with time zone default now()
);

alter table public.payment_orders enable row level security;

drop policy if exists "Users can view own payment orders" on public.payment_orders;
drop policy if exists "Users can insert own payment orders" on public.payment_orders;
drop policy if exists "Users can update own payment orders" on public.payment_orders;

create policy "Users can view own payment orders" on public.payment_orders
  for select using (auth.uid() = user_id);

-- Customer creates only pending top-up orders from Flutter.
-- Wallet balance is NOT updated here.
create or replace function public.create_topup_order(
  amount numeric,
  provider text default 'manual'
)
returns table (
  order_id uuid,
  external_reference text,
  order_status text,
  order_amount numeric,
  payment_url text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  inserted_order_id uuid;
  inserted_external_reference text;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if amount is null or amount <= 0 then
    raise exception 'Amount must be greater than zero';
  end if;

  insert into public.payment_orders (
    user_id,
    provider,
    type,
    amount,
    status
  ) values (
    current_user_id,
    provider,
    'wallet_topup',
    amount,
    'pending'
  ) returning id, external_reference into inserted_order_id, inserted_external_reference;

  return query
  select inserted_order_id, inserted_external_reference, 'pending'::text, amount, null::text;
end;
$$;

-- Trusted apply function for webhook/backend only.
-- Do not grant this function to authenticated users.
create or replace function public.apply_paid_topup_order(
  target_external_reference text,
  provider_order_id text default null,
  raw_payload jsonb default '{}'::jsonb
)
returns table (
  transaction_id uuid,
  new_balance numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  target_order public.payment_orders%rowtype;
  current_balance numeric;
  inserted_transaction_id uuid;
begin
  select *
    into target_order
  from public.payment_orders
  where external_reference = target_external_reference
  for update;

  if target_order.id is null then
    raise exception 'Payment order not found';
  end if;

  if target_order.status = 'paid' then
    select wallets.balance
      into current_balance
    from public.wallets
    where wallets.user_id = target_order.user_id;

    return query
    select null::uuid, current_balance;
    return;
  end if;

  if target_order.status <> 'pending' then
    raise exception 'Payment order is not pending';
  end if;

  insert into public.wallets (user_id, balance)
  values (target_order.user_id, 0)
  on conflict (user_id) do nothing;

  select wallets.balance
    into current_balance
  from public.wallets
  where wallets.user_id = target_order.user_id
  for update;

  update public.wallets
  set
    balance = current_balance + target_order.amount,
    updated_at = now()
  where user_id = target_order.user_id;

  update public.payment_orders
  set
    status = 'paid',
    paid_at = now(),
    provider_order_id = coalesce(apply_paid_topup_order.provider_order_id, payment_orders.provider_order_id),
    raw_payload = apply_paid_topup_order.raw_payload,
    updated_at = now()
  where id = target_order.id;

  insert into public.wallet_transactions (
    user_id,
    type,
    amount,
    description,
    status
  ) values (
    target_order.user_id,
    'topup',
    target_order.amount,
    'Top up wallet via payment gateway',
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
    target_order.user_id,
    inserted_transaction_id,
    'TOPUP-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || left(inserted_transaction_id::text, 8),
    target_order.amount,
    'paid',
    now()
  );

  return query
  select inserted_transaction_id, current_balance + target_order.amount;
end;
$$;

revoke all on function public.create_topup_order(numeric, text) from public;
grant execute on function public.create_topup_order(numeric, text) to authenticated;

revoke all on function public.apply_paid_topup_order(text, text, jsonb) from public;
-- Intentionally no authenticated grant. Call only from trusted webhook/backend/service role.
