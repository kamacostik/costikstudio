-- Costik Signage client payload RPCs (Android TV pairing clients).
-- Run AFTER docs/db/signage_schema.sql and docs/db/signage_device_pairing_rpc.sql.
--
-- TV devices authenticate with (device_id, device_token) issued by
-- public.activate_signage_device(). The anon key is safe here because the
-- raw token is verified (sha256) inside SECURITY DEFINER functions, and the
-- raw token is only ever returned once, at activation time.
-- Every successful call refreshes last_seen_at so Web Admin can tell which
-- devices are online.

-- pgcrypto ships in the extensions schema on Supabase (not public), so the
-- functions below set search_path = public, extensions to reach digest().
create extension if not exists pgcrypto;

-- Full tenant payload for one paired device: device config, hotel profile,
-- enabled playlists (with media URLs) and active/upcoming events.
create or replace function public.get_signage_device_payload(
  p_device_id text,
  p_device_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_device public.sg_devices%rowtype;
  v_token_hash text;
  v_hotel jsonb;
  v_playlists jsonb;
  v_events jsonb;
begin
  if p_device_id is null or trim(p_device_id) = '' then
    raise exception 'Perangkat belum terhubung.';
  end if;
  if p_device_token is null or trim(p_device_token) = '' then
    raise exception 'Token perangkat tidak valid.';
  end if;

  select d.*
    into v_device
  from public.sg_devices as d
  where d.id = trim(p_device_id)
  limit 1;

  if v_device.id is null
    or v_device.is_active is not true
    or v_device.activated_at is null
  then
    raise exception 'Perangkat belum terhubung.';
  end if;

  v_token_hash := encode(digest(trim(p_device_token), 'sha256'), 'hex');
  if v_device.device_token_hash is null
    or v_device.device_token_hash <> v_token_hash
  then
    raise exception 'Token perangkat tidak valid.';
  end if;

  update public.sg_devices as d
  set last_seen_at = now(),
      updated_at = now()
  where d.id = v_device.id;

  select to_jsonb(h)
    into v_hotel
  from public.sg_hotel_profiles as h
  where h.tenant_id = v_device.tenant_id
  limit 1;

  select coalesce(
    jsonb_agg(to_jsonb(pl) order by pl.sort_order, pl.created_at),
    '[]'::jsonb
  )
    into v_playlists
  from (
    select
      p.id,
      p.nama_playlist,
      p.path_playlist,
      p.is_enabled,
      p.start_date,
      p.end_date,
      p.sort_order,
      p.created_at,
      m.public_url as media_url,
      m.storage_path as media_storage_path,
      m.file_name as media_file_name,
      m.mime_type as media_mime_type
    from public.sg_playlists as p
    left join public.sg_media as m on m.id = p.media_id
    where p.tenant_id = v_device.tenant_id
      and p.is_enabled = true
    order by p.sort_order, p.created_at
    limit 500
  ) as pl;

  select coalesce(
    jsonb_agg(to_jsonb(ev) order by ev.start_date nulls last),
    '[]'::jsonb
  )
    into v_events
  from (
    select
      e.id,
      e.event_name,
      e.meeting_room,
      e.floor,
      e.direction,
      e.start_date,
      e.end_date,
      to_char(e.start_date, 'HH24:MI') as start_time,
      to_char(e.end_date, 'HH24:MI') as end_time
    from public.sg_event_lists as e
    where e.tenant_id = v_device.tenant_id
      and e.is_active = true
      and (e.end_date is null or e.end_date::date >= current_date)
    order by e.start_date nulls last
    limit 200
  ) as ev;

  return jsonb_build_object(
    'device', jsonb_build_object(
      'id', v_device.id,
      'tenant_id', v_device.tenant_id,
      'nama_device', v_device.nama_device,
      'is_video', v_device.is_video,
      'is_promo', v_device.is_promo,
      'promo_duration', v_device.promo_duration,
      'table_column', v_device.table_column
    ),
    'tenant_id', v_device.tenant_id,
    'hotel', coalesce(v_hotel, 'null'::jsonb),
    'playlists', v_playlists,
    'events', v_events,
    'fetched_at', now()
  );
end;
$$;

-- Lightweight online heartbeat for paired devices (no payload).
create or replace function public.touch_signage_device(
  p_device_id text,
  p_device_token text
)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_device public.sg_devices%rowtype;
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
  from public.sg_devices as d
  where d.id = trim(p_device_id)
  limit 1;

  if v_device.id is null
    or v_device.is_active is not true
    or v_device.activated_at is null
  then
    raise exception 'Perangkat belum terhubung.';
  end if;

  v_token_hash := encode(digest(trim(p_device_token), 'sha256'), 'hex');
  if v_device.device_token_hash is null
    or v_device.device_token_hash <> v_token_hash
  then
    raise exception 'Token perangkat tidak valid.';
  end if;

  update public.sg_devices as d
  set last_seen_at = now(),
      updated_at = now()
  where d.id = v_device.id;

  return true;
end;
$$;

grant execute on function public.get_signage_device_payload(text, text) to anon, authenticated;
grant execute on function public.touch_signage_device(text, text) to anon, authenticated;
