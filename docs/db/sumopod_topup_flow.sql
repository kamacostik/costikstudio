-- Sumopod payment gateway support for wallet top-up orders.
-- Keep Sumopod API keys in n8n / backend, never in Flutter.
-- Flutter only creates a pending order and reads payment_url after a trusted worker fills it.

alter table public.payment_orders
  add column if not exists currency text not null default 'IDR',
  add column if not exists gateway_payment_id text null,
  add column if not exists payment_method_type_code text null default 'QRIS',
  add column if not exists expires_at timestamp with time zone null;

create index if not exists payment_orders_gateway_payment_id_idx
  on public.payment_orders (gateway_payment_id);

create or replace function public.create_sumopod_topup_order(
  amount numeric,
  payment_method_type_code text default 'QRIS'
)
returns table (
  order_id uuid,
  external_reference text,
  order_status text,
  order_amount numeric,
  payment_url text,
  currency text,
  payment_method text,
  expires_at timestamp with time zone
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  inserted_order public.payment_orders%rowtype;
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
    status,
    currency,
    payment_method_type_code,
    expires_at
  ) values (
    current_user_id,
    'sumopod',
    'wallet_topup',
    amount,
    'pending',
    'IDR',
    payment_method_type_code,
    now() + interval '24 hours'
  ) returning * into inserted_order;

  return query
  select
    inserted_order.id,
    inserted_order.external_reference,
    inserted_order.status,
    inserted_order.amount,
    inserted_order.payment_url,
    inserted_order.currency,
    inserted_order.payment_method_type_code,
    inserted_order.expires_at;
end;
$$;

-- Called by n8n/backend after Sumopod create-payment API returns payment_url/payment id.
-- Do not grant this to authenticated users.
create or replace function public.attach_sumopod_payment_url(
  target_external_reference text,
  target_gateway_payment_id text,
  target_payment_url text,
  raw_payload jsonb default '{}'::jsonb
)
returns public.payment_orders
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_order public.payment_orders%rowtype;
begin
  update public.payment_orders
  set
    gateway_payment_id = target_gateway_payment_id,
    provider_order_id = coalesce(target_gateway_payment_id, provider_order_id),
    payment_url = target_payment_url,
    raw_payload = attach_sumopod_payment_url.raw_payload,
    updated_at = now()
  where external_reference = target_external_reference
    and provider = 'sumopod'
    and status = 'pending'
  returning * into updated_order;

  if updated_order.id is null then
    raise exception 'Pending Sumopod payment order not found';
  end if;

  return updated_order;
end;
$$;

revoke all on function public.create_sumopod_topup_order(numeric, text) from public;
grant execute on function public.create_sumopod_topup_order(numeric, text) to authenticated;

revoke all on function public.attach_sumopod_payment_url(text, text, text, jsonb) from public;
-- Intentionally no authenticated grant. Use only from trusted n8n/backend/service role.
