-- Trusted RPC for reactivating a cancelled Costik IPTV subscription.
-- No wallet charge is applied here; renewal/upgrade remain separate paid actions.

create or replace function public.reactivate_iptv_subscription(
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

  if target_subscription.product_id <> 'costik-iptv' then
    raise exception 'Selected subscription is not Costik IPTV';
  end if;

  if target_subscription.status = 'active' then
    return;
  end if;

  if target_subscription.status <> 'cancelled' then
    raise exception 'Only cancelled IPTV subscriptions can be reactivated';
  end if;

  update public.subscriptions
  set
    status = 'active',
    updated_at = now()
  where id = target_subscription.id;
end;
$$;

revoke all on function public.reactivate_iptv_subscription(uuid) from public;
grant execute on function public.reactivate_iptv_subscription(uuid) to authenticated;
