-- Costik Signage device pairing RPCs
-- Run after docs/db/signage_schema.sql and core billing/subscription schema.

create extension if not exists pgcrypto;

alter table public.sg_devices
add column if not exists pairing_code text,
add column if not exists device_token_hash text,
add column if not exists pairing_expires_at timestamptz,
add column if not exists activated_at timestamptz,
add column if not exists device_info jsonb not null default '{}'::jsonb;

create index if not exists sg_devices_pairing_expires_at_idx
on public.sg_devices (pairing_expires_at);

create or replace function public.create_signage_device_pairing(
  p_device_name text default null,
  p_platform text default 'android-tv'
)
returns table (
  device_id text,
  pairing_code text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_tenant_id uuid;
  v_device_limit integer;
  v_active_devices integer;
  v_device_id text;
  v_pairing_code text;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select tenant_id
    into v_tenant_id
  from public.sg_profiles
  where id = v_user_id
  limit 1;

  if v_tenant_id is null then
    raise exception 'Tenant Signage belum tersedia.';
  end if;

  select coalesce(max(s.device_count), 0)
    into v_device_limit
  from public.subscriptions as s
  where s.user_id = v_user_id
    and s.product_id = 'costik-signage'
    and s.status = 'active'
    and s.expires_at > now();

  if coalesce(v_device_limit, 0) <= 0 then
    raise exception 'Subscription Costik Signage belum aktif.';
  end if;

  select count(*)
    into v_active_devices
  from public.sg_devices as d
  where d.tenant_id = v_tenant_id
    and (
      (d.is_active = true and d.activated_at is not null)
      or (d.activated_at is null and d.pairing_code is not null and d.pairing_expires_at > now())
    );

  if v_active_devices >= v_device_limit then
    raise exception 'Kuota device Signage sudah penuh. Upgrade device untuk menambah layar.';
  end if;

  v_device_id := 'sg-' || replace(gen_random_uuid()::text, '-', '');
  v_pairing_code := lpad((floor(random() * 1000000))::int::text, 6, '0');

  while exists (
    select 1 from public.sg_devices as d
    where d.pairing_code = v_pairing_code
      and d.pairing_expires_at > now()
  ) loop
    v_pairing_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
  end loop;

  insert into public.sg_devices (
    id,
    tenant_id,
    nama_device,
    pairing_code,
    pairing_expires_at,
    platform,
    is_active
  ) values (
    v_device_id,
    v_tenant_id,
    coalesce(nullif(trim(p_device_name), ''), 'Android TV'),
    v_pairing_code,
    now() + interval '10 minutes',
    coalesce(nullif(trim(p_platform), ''), 'android-tv'),
    false
  );

  return query
  select v_device_id, v_pairing_code, now() + interval '10 minutes';
end;
$$;

create or replace function public.activate_signage_device(
  p_pairing_code text,
  p_device_info jsonb default '{}'::jsonb
)
returns table (
  device_id text,
  device_token text,
  tenant_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_device public.sg_devices%rowtype;
  v_device_token text;
begin
  select d.*
    into v_device
  from public.sg_devices as d
  where d.pairing_code = trim(p_pairing_code)
    and d.pairing_expires_at > now()
    and d.activated_at is null
  order by d.created_at desc
  limit 1;

  if v_device.id is null then
    raise exception 'Kode pairing tidak valid atau sudah expired.';
  end if;

  v_device_token := encode(gen_random_bytes(32), 'hex');

  update public.sg_devices
  set pairing_code = null,
      pairing_expires_at = null,
      is_active = true,
      activated_at = now(),
      last_seen_at = now(),
      device_token_hash = encode(digest(v_device_token, 'sha256'), 'hex'),
      device_info = coalesce(p_device_info, '{}'::jsonb)
  where id = v_device.id;

  return query
  select v_device.id, v_device_token, v_device.tenant_id;
end;
$$;


create or replace function public.regenerate_signage_device_pairing(
  p_device_id text
)
returns table (
  device_id text,
  pairing_code text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_tenant_id uuid;
  v_device public.sg_devices%rowtype;
  v_pairing_code text;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select p.tenant_id
    into v_tenant_id
  from public.sg_profiles as p
  where p.id = v_user_id
  limit 1;

  if v_tenant_id is null then
    raise exception 'Tenant Signage belum tersedia.';
  end if;

  select d.*
    into v_device
  from public.sg_devices as d
  where d.id = p_device_id
    and d.tenant_id = v_tenant_id
  limit 1;

  if v_device.id is null then
    raise exception 'Device tidak ditemukan.';
  end if;

  if v_device.activated_at is not null then
    raise exception 'Device sudah terhubung. Tidak perlu membuat kode pairing lagi.';
  end if;

  v_pairing_code := lpad((floor(random() * 1000000))::int::text, 6, '0');

  while exists (
    select 1 from public.sg_devices as d
    where d.pairing_code = v_pairing_code
      and d.pairing_expires_at > now()
      and d.id <> v_device.id
  ) loop
    v_pairing_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
  end loop;

  update public.sg_devices as d
  set pairing_code = v_pairing_code,
      pairing_expires_at = now() + interval '10 minutes',
      is_active = false
  where d.id = v_device.id;

  return query
  select v_device.id, v_pairing_code, now() + interval '10 minutes';
end;
$$;

grant execute on function public.create_signage_device_pairing(text, text) to authenticated;
grant execute on function public.activate_signage_device(text, jsonb) to anon, authenticated;
grant execute on function public.regenerate_signage_device_pairing(text) to authenticated;
