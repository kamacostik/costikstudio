-- IPTV video upload add-on activation.
-- Enables video upload limits on an active Costik IPTV subscription and charges wallet.

create or replace function public.activate_iptv_video_addon(
  target_subscription_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  v_wallet_balance numeric;
  v_addon_price numeric := 25000;
  v_subscription public.subscriptions%rowtype;
  v_transaction_id uuid;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  select *
    into v_subscription
  from public.subscriptions
  where id = target_subscription_id
    and user_id = current_user_id
    and product_id = 'costik-iptv'
  for update;

  if v_subscription.id is null then
    raise exception 'IPTV subscription not found';
  end if;

  if v_subscription.status <> 'active' or v_subscription.expires_at <= now() then
    raise exception 'IPTV subscription must be active';
  end if;

  if coalesce((v_subscription.media_limits->>'video_upload_enabled')::boolean, false) then
    raise exception 'Video add-on is already active';
  end if;

  insert into public.wallets (user_id, balance)
  values (current_user_id, 0)
  on conflict (user_id) do nothing;

  select balance
    into v_wallet_balance
  from public.wallets
  where user_id = current_user_id
  for update;

  if v_wallet_balance < v_addon_price then
    raise exception 'Insufficient wallet balance';
  end if;

  update public.wallets
  set balance = v_wallet_balance - v_addon_price,
      updated_at = now()
  where user_id = current_user_id;

  update public.subscriptions
  set media_limits = coalesce(media_limits, '{}'::jsonb) || jsonb_build_object(
        'media_storage_limit_mb', 1000,
        'image_upload_enabled', true,
        'video_upload_enabled', true,
        'video_max_file_size_mb', 30,
        'video_max_duration_seconds', 30,
        'video_active_limit', 5
      ),
      updated_at = now()
  where id = target_subscription_id;

  insert into public.wallet_transactions (
    user_id,
    type,
    amount,
    description,
    status
  ) values (
    current_user_id,
    'purchase',
    v_addon_price,
    'Costik IPTV video upload add-on',
    'completed'
  ) returning id into v_transaction_id;

  insert into public.invoices (
    user_id,
    transaction_id,
    invoice_number,
    amount,
    status,
    issued_at
  ) values (
    current_user_id,
    v_transaction_id,
    'IPTV-VIDEO-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || left(target_subscription_id::text, 8),
    v_addon_price,
    'paid',
    now()
  );
end;
$$;

revoke all on function public.activate_iptv_video_addon(uuid) from public;
grant execute on function public.activate_iptv_video_addon(uuid) to authenticated;
