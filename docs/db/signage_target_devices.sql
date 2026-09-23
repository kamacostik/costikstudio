-- Add target_device_ids to filter playlists and events per device
alter table public.sg_playlists
add column if not exists target_device_ids text[];

alter table public.sg_event_lists
add column if not exists target_device_ids text[];
