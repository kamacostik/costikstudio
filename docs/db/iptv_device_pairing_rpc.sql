-- Costik IPTV device pairing RPCs using existing public.devices table.
-- Run after the existing IPTV devices table and subscription/licence schema.
-- This keeps admin_iptv and iptv client on the old devices table while adopting
-- the Costik Signage pairing pattern: admin generates a 6-digit code, client
-- activates once, then stores a device token for future heartbeat checks.

create extension if not exists pgcrypto;

alter table public.devices
add column if not exists device_token_hash text,
add column if not exists pairing_expires_at timestamptz,
add column if not exists activated_at timestamptz,
add column if not exists device_info jsonb not null default '{}'::jsonb;

create index if not exists devices_pairing_expires_at_idx
on public.devices (pairing_expires_at);

create index if not exists devices_activation_code_idx
on public.devices (activation_code);

create or replace function public.create_iptv_device_pairing(
  p_device_name text default null,
  p_platform text default 'android-tv'
)
returns table (
  id integer,
  pairing_code text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_device_limit integer;
  v_used_devices integer;
  v_pairing_code text;
  v_inserted_id integer;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select coalesce(max(s.device_count), 0)
    into v_device_limit
  from public.subscriptions as s
  where s.user_id = v_user_id
    and s.product_id = 'costik-iptv'
    and s.status = 'active'
    and s.expires_at > now();

  if coalesce(v_device_limit, 0) <= 0 then
    raise exception 'Subscription Costik IPTV belum aktif.';
  end if;

  select count(*)
    into v_used_devices
  from public.devices as d
  where d.client_id = v_user_id
    and (
      (d.activated = true and d.activated_at is not null)
      or (d.activated_at is null and d.activation_code is not null and d.pairing_expires_at > now())
    );

  if v_used_devices >= v_device_limit then
    raise exception 'Kuota device IPTV sudah penuh. Upgrade device untuk menambah perangkat.';
  end if;

  v_pairing_code := lpad((floor(random() * 1000000))::int::text, 6, '0');

  while exists (
    select 1 from public.devices as d
    where d.activation_code = v_pairing_code
      and d.pairing_expires_at > now()
  ) loop
    v_pairing_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
  end loop;

  insert into public.devices (
    client_id,
    name,
    activation_code,
    pairing_expires_at,
    activated,
    device_info
  ) values (
    v_user_id,
    coalesce(nullif(trim(p_device_name), ''), 'Android TV'),
    v_pairing_code,
    now() + interval '10 minutes',
    false,
    jsonb_build_object('platform', coalesce(nullif(trim(p_platform), ''), 'android-tv'))
  ) returning devices.id into v_inserted_id;

  return query
  select v_inserted_id, v_pairing_code, now() + interval '10 minutes';
end;
$$;

create or replace function public.activate_iptv_device(
  p_pairing_code text,
  p_device_id text,
  p_device_info jsonb default '{}'::jsonb
)
returns table (
  id integer,
  device_id text,
  device_token text,
  client_id uuid
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_device public.devices%rowtype;
  v_device_token text;
begin
  if p_device_id is null or trim(p_device_id) = '' then
    raise exception 'Device ID tidak valid.';
  end if;

  select d.*
    into v_device
  from public.devices as d
  where d.activation_code = trim(p_pairing_code)
    and d.pairing_expires_at > now()
    and d.activated_at is null
  order by d.id desc
  limit 1;

  if v_device.id is null then
    raise exception 'Kode pairing tidak valid atau sudah expired.';
  end if;

  v_device_token := encode(gen_random_bytes(32), 'hex');

  update public.devices
  set activation_code = null,
      pairing_expires_at = null,
      activated = true,
      activated_at = now(),
      last_seen = now(),
      device_id = trim(p_device_id),
      device_token_hash = encode(digest(v_device_token, 'sha256'), 'hex'),
      device_info = coalesce(p_device_info, '{}'::jsonb),
      ip_address = coalesce(p_device_info->>'ip_address', ip_address),
      app_version = coalesce(p_device_info->>'app_version', app_version),
      ram_status = coalesce(p_device_info->>'ram_status', ram_status),
      storage_status = coalesce(p_device_info->>'storage_status', storage_status),
      fcm_token = coalesce(p_device_info->>'fcm_token', fcm_token)
  where devices.id = v_device.id;

  return query
  select v_device.id, trim(p_device_id), v_device_token, v_device.client_id;
end;
$$;

create or replace function public.touch_iptv_device(
  p_device_id text,
  p_device_token text,
  p_device_info jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_device public.devices%rowtype;
  v_token_hash text;
begin
  if p_device_id is null or trim(p_device_id) = '' then
    raise exception 'Perangkat belum terhubung.';
  end if;
  if p_device_token is null or trim(p_device_token) = '' then
    raise exception 'Token perangkat tidak valid.';
  end if;

  select d.*
    into v_device
  from public.devices as d
  where d.device_id = trim(p_device_id)
  limit 1;

  if v_device.id is null or v_device.activated is not true or v_device.activated_at is null then
    raise exception 'Perangkat belum terhubung.';
  end if;

  v_token_hash := encode(digest(trim(p_device_token), 'sha256'), 'hex');
  if v_device.device_token_hash is null or v_device.device_token_hash <> v_token_hash then
    raise exception 'Token perangkat tidak valid.';
  end if;

  update public.devices as d
  set last_seen = now(),
      device_info = coalesce(p_device_info, d.device_info),
      ip_address = coalesce(p_device_info->>'ip_address', d.ip_address),
      app_version = coalesce(p_device_info->>'app_version', d.app_version),
      ram_status = coalesce(p_device_info->>'ram_status', d.ram_status),
      storage_status = coalesce(p_device_info->>'storage_status', d.storage_status),
      fcm_token = coalesce(p_device_info->>'fcm_token', d.fcm_token)
  where d.id = v_device.id;

  return true;
end;
$$;

revoke all on function public.create_iptv_device_pairing(text, text) from public;
revoke all on function public.activate_iptv_device(text, text, jsonb) from public;
revoke all on function public.touch_iptv_device(text, text, jsonb) from public;

grant execute on function public.create_iptv_device_pairing(text, text) to authenticated;
grant execute on function public.activate_iptv_device(text, text, jsonb) to anon, authenticated;
grant execute on function public.touch_iptv_device(text, text, jsonb) to anon, authenticated;
