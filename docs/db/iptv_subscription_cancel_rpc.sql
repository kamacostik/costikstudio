-- Trusted RPC for cancelling an active Costik IPTV subscription.
-- Updates subscription status to 'cancelled'.

create or replace function cancel_iptv_subscription(
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

  update subscriptions
  set status = 'cancelled',
      updated_at = now()
  where id = target_subscription_id
    and user_id = v_user_id;

  if not found then
    raise exception 'Subscription not found or not owned by user';
  end if;
end;
$$;

grant execute on function cancel_iptv_subscription(uuid) to authenticated;
