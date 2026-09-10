-- Trusted RPC for customer top-up requests/testing.
-- Keeps wallet writes out of direct Flutter table access.

create or replace function public.request_wallet_topup(
  amount numeric,
  description text default 'Top up saldo IPTV'
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
  current_user_id uuid := auth.uid();
  current_balance numeric;
  inserted_transaction_id uuid;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if amount is null or amount <= 0 then
    raise exception 'Amount must be greater than zero';
  end if;

  insert into public.wallets (user_id, balance)
  values (current_user_id, 0)
  on conflict (user_id) do nothing;

  select wallets.balance
    into current_balance
  from public.wallets
  where wallets.user_id = current_user_id
  for update;

  update public.wallets
  set
    balance = current_balance + amount,
    updated_at = now()
  where user_id = current_user_id;

  insert into public.wallet_transactions (
    user_id,
    type,
    amount,
    description,
    status
  ) values (
    current_user_id,
    'topup',
    amount,
    description,
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
    'TOPUP-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || left(inserted_transaction_id::text, 8),
    amount,
    'paid',
    now()
  );

  return query
  select inserted_transaction_id, current_balance + amount;
end;
$$;

revoke all on function public.request_wallet_topup(numeric, text) from public;
grant execute on function public.request_wallet_topup(numeric, text) to authenticated;
