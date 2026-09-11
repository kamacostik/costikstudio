-- Admin Trusted RPC for managing IPTV Subscriptions.
-- Allows admin/backoffice users to bypass customer wallet charging for manual extension or device quota adjustments.

create or replace function admin_extend_iptv_subscription(
  target_subscription_id uuid,
  additional_months int
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_current_expires_at timestamptz;
  v_new_expires_at timestamptz;
begin
  if additional_months is null or additional_months <= 0 then
    raise exception 'Additional months must be greater than zero';
  end if;

  select expires_at into v_current_expires_at
  from subscriptions
  where id = target_subscription_id;

  if not found then
    raise exception 'Subscription not found';
  end if;

  v_new_expires_at := greatest(v_current_expires_at, now()) + (additional_months || ' months')::interval;

  update subscriptions
  set expires_at = v_new_expires_at,
      status = 'active',
      updated_at = now()
  where id = target_subscription_id;
end;
$$;

create or replace function admin_update_iptv_device_count(
  target_subscription_id uuid,
  new_device_count int
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if new_device_count is null or new_device_count <= 0 then
    raise exception 'Device count must be greater than zero';
  end if;

  update subscriptions
  set device_count = new_device_count,
      updated_at = now()
  where id = target_subscription_id;

  if not found then
    raise exception 'Subscription not found';
  end if;
end;
$$;

grant execute on function admin_extend_iptv_subscription(uuid, int) to authenticated;
grant execute on function admin_update_iptv_device_count(uuid, int) to authenticated;
