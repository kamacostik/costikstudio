-- Multi-video playlist items for Signage.
-- Run AFTER docs/db/signage_schema.sql on existing databases.
-- One playlist can now hold many videos in play order; the legacy
-- sg_playlists.media_id single-video column stays as fallback.
create table if not exists public.sg_playlist_items (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.sg_tenants(id) on delete cascade,
  playlist_id uuid not null references public.sg_playlists(id) on delete cascade,
  media_id uuid references public.sg_media(id) on delete set null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists sg_playlist_items_playlist_id_idx
  on public.sg_playlist_items (playlist_id);
create index if not exists sg_playlist_items_tenant_id_idx
  on public.sg_playlist_items (tenant_id);

drop trigger if exists sg_playlist_items_set_updated_at on public.sg_playlist_items;
create trigger sg_playlist_items_set_updated_at before update on public.sg_playlist_items
for each row execute function public.sg_set_updated_at();

alter table public.sg_playlist_items enable row level security;

drop policy if exists sg_playlist_items_member_all on public.sg_playlist_items;
create policy sg_playlist_items_member_all on public.sg_playlist_items
for all to authenticated
using (public.sg_is_tenant_member(tenant_id))
with check (public.sg_is_tenant_member(tenant_id));
