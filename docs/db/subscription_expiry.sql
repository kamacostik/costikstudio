-- Subscription expiry maintenance for CostikStudio.
-- Run after core billing schema/RPC files.
-- Keeps historical data, but marks elapsed active subscriptions as expired.

create or replace function public.mark_expired_subscriptions()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
begin
  update public.subscriptions
  set
    status = 'expired',
    updated_at = now()
  where status = 'active'
    and expires_at <= now();

  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

revoke all on function public.mark_expired_subscriptions() from public;
grant execute on function public.mark_expired_subscriptions() to authenticated;

-- Optional manual run:
-- select public.mark_expired_subscriptions();
