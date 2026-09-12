-- Costik Signage Supabase schema
-- Apply this whole file in Supabase SQL Editor.
-- Safe to re-run: most objects use IF NOT EXISTS / DROP POLICY IF EXISTS.

create extension if not exists pgcrypto;

-- Updated-at trigger helper
create or replace function public.sg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Tenant/company/hotel owner namespace
create table if not exists public.sg_tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Supabase Auth user -> tenant mapping for Admin app users.
create table if not exists public.sg_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  tenant_id uuid not null references public.sg_tenants(id) on delete cascade,
  role text not null default 'admin' check (role in ('owner', 'admin', 'staff')),
  full_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Hotel/profile content shown by Admin and Client.
create table if not exists public.sg_hotel_profiles (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.sg_tenants(id) on delete cascade,
  nama_hotel text,
  alamat_hotel text,
  keterangan_hotel text,
  logo_hotel text,
  logo_hotel_1 text,
  logo_hotel_2 text,
  durasi double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id)
);

-- Signage player/device config.
-- IMPORTANT: id is TEXT because the Client uses Android/iOS/Windows device id.
create table if not exists public.sg_devices (
  id text primary key,
  tenant_id uuid not null references public.sg_tenants(id) on delete cascade,
  nama_device text,
  pairing_code text unique,
  platform text,
  is_video boolean not null default true,
  is_promo boolean not null default true,
  promo_duration double precision not null default 7,
  table_column integer not null default 4,
  event_slide_duration_seconds integer not null default 7,
  app_mode text not null default 'daily_event'
    check (app_mode in ('daily_event', 'video_player')),
  is_active boolean not null default true,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Media uploaded by Admin. Storage objects live in bucket signage-media.
create table if not exists public.sg_media (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.sg_tenants(id) on delete cascade,
  bucket text not null default 'signage-media',
  storage_path text not null,
  file_name text not null,
  mime_type text,
  size_bytes bigint,
  media_type text check (media_type in ('video', 'image', 'other')),
  public_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (bucket, storage_path)
);

-- Playlist rows. Client joins sg_media to get playable URL.
create table if not exists public.sg_playlists (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.sg_tenants(id) on delete cascade,
  nama_playlist text not null,
  media_id uuid references public.sg_media(id) on delete set null,
  path_playlist text,
  is_enabled boolean not null default true,
  start_date timestamptz,
  end_date timestamptz,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Event/meeting-room info shown by Client.
create table if not exists public.sg_event_lists (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.sg_tenants(id) on delete cascade,
  event_name text,
  meeting_room text,
  floor text,
  direction text,
  start_date timestamptz,
  end_date timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Compatibility adjustment if an older draft created sg_event_lists.is_enabled.
alter table public.sg_event_lists
add column if not exists is_active boolean not null default true;

-- Indexes
create index if not exists sg_profiles_tenant_id_idx on public.sg_profiles (tenant_id);
create index if not exists sg_hotel_profiles_tenant_id_idx on public.sg_hotel_profiles (tenant_id);
create index if not exists sg_devices_tenant_id_idx on public.sg_devices (tenant_id);
create index if not exists sg_devices_pairing_code_idx on public.sg_devices (pairing_code);
create index if not exists sg_media_tenant_id_idx on public.sg_media (tenant_id);
create index if not exists sg_playlists_tenant_id_idx on public.sg_playlists (tenant_id);
create index if not exists sg_event_lists_tenant_id_idx on public.sg_event_lists (tenant_id);

-- Updated-at triggers
drop trigger if exists sg_tenants_set_updated_at on public.sg_tenants;
create trigger sg_tenants_set_updated_at before update on public.sg_tenants
for each row execute function public.sg_set_updated_at();

drop trigger if exists sg_profiles_set_updated_at on public.sg_profiles;
create trigger sg_profiles_set_updated_at before update on public.sg_profiles
for each row execute function public.sg_set_updated_at();

drop trigger if exists sg_hotel_profiles_set_updated_at on public.sg_hotel_profiles;
create trigger sg_hotel_profiles_set_updated_at before update on public.sg_hotel_profiles
for each row execute function public.sg_set_updated_at();

drop trigger if exists sg_devices_set_updated_at on public.sg_devices;
create trigger sg_devices_set_updated_at before update on public.sg_devices
for each row execute function public.sg_set_updated_at();

drop trigger if exists sg_media_set_updated_at on public.sg_media;
create trigger sg_media_set_updated_at before update on public.sg_media
for each row execute function public.sg_set_updated_at();

drop trigger if exists sg_playlists_set_updated_at on public.sg_playlists;
create trigger sg_playlists_set_updated_at before update on public.sg_playlists
for each row execute function public.sg_set_updated_at();

drop trigger if exists sg_event_lists_set_updated_at on public.sg_event_lists;
create trigger sg_event_lists_set_updated_at before update on public.sg_event_lists
for each row execute function public.sg_set_updated_at();

-- Tenant helpers for RLS
create or replace function public.sg_current_tenant_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select tenant_id
  from public.sg_profiles
  where id = auth.uid()
  limit 1
$$;

create or replace function public.sg_is_tenant_member(target_tenant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.sg_profiles
    where id = auth.uid()
      and tenant_id = target_tenant_id
  )
$$;

-- Enable RLS
alter table public.sg_tenants enable row level security;
alter table public.sg_profiles enable row level security;
alter table public.sg_hotel_profiles enable row level security;
alter table public.sg_devices enable row level security;
alter table public.sg_media enable row level security;
alter table public.sg_playlists enable row level security;
alter table public.sg_event_lists enable row level security;

-- Profiles: users can read profiles in their tenant; users can update their own profile.
drop policy if exists sg_profiles_read_tenant on public.sg_profiles;
create policy sg_profiles_read_tenant on public.sg_profiles
for select to authenticated
using (public.sg_is_tenant_member(tenant_id));

drop policy if exists sg_profiles_update_self on public.sg_profiles;
create policy sg_profiles_update_self on public.sg_profiles
for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- Tenants: members can read their tenant.
drop policy if exists sg_tenants_read_member on public.sg_tenants;
create policy sg_tenants_read_member on public.sg_tenants
for select to authenticated
using (public.sg_is_tenant_member(id));

-- Generic tenant policies for app data.
drop policy if exists sg_hotel_profiles_member_all on public.sg_hotel_profiles;
create policy sg_hotel_profiles_member_all on public.sg_hotel_profiles
for all to authenticated
using (public.sg_is_tenant_member(tenant_id))
with check (public.sg_is_tenant_member(tenant_id));

drop policy if exists sg_devices_member_all on public.sg_devices;
create policy sg_devices_member_all on public.sg_devices
for all to authenticated
using (public.sg_is_tenant_member(tenant_id))
with check (public.sg_is_tenant_member(tenant_id));

drop policy if exists sg_media_member_all on public.sg_media;
create policy sg_media_member_all on public.sg_media
for all to authenticated
using (public.sg_is_tenant_member(tenant_id))
with check (public.sg_is_tenant_member(tenant_id));

drop policy if exists sg_playlists_member_all on public.sg_playlists;
create policy sg_playlists_member_all on public.sg_playlists
for all to authenticated
using (public.sg_is_tenant_member(tenant_id))
with check (public.sg_is_tenant_member(tenant_id));

drop policy if exists sg_event_lists_member_all on public.sg_event_lists;
create policy sg_event_lists_member_all on public.sg_event_lists
for all to authenticated
using (public.sg_is_tenant_member(tenant_id))
with check (public.sg_is_tenant_member(tenant_id));

-- Storage bucket. Private by default; app creates signed URLs during upload.
insert into storage.buckets (id, name, public)
values ('signage-media', 'signage-media', false)
on conflict (id) do nothing;

-- Storage policies: tenant members can manage objects under <tenant_id>/...
drop policy if exists sg_media_storage_read on storage.objects;
create policy sg_media_storage_read on storage.objects
for select to authenticated
using (
  bucket_id = 'signage-media'
  and public.sg_is_tenant_member((storage.foldername(name))[1]::uuid)
);

drop policy if exists sg_media_storage_insert on storage.objects;
create policy sg_media_storage_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'signage-media'
  and public.sg_is_tenant_member((storage.foldername(name))[1]::uuid)
);

drop policy if exists sg_media_storage_update on storage.objects;
create policy sg_media_storage_update on storage.objects
for update to authenticated
using (
  bucket_id = 'signage-media'
  and public.sg_is_tenant_member((storage.foldername(name))[1]::uuid)
)
with check (
  bucket_id = 'signage-media'
  and public.sg_is_tenant_member((storage.foldername(name))[1]::uuid)
);

drop policy if exists sg_media_storage_delete on storage.objects;
create policy sg_media_storage_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'signage-media'
  and public.sg_is_tenant_member((storage.foldername(name))[1]::uuid)
);
