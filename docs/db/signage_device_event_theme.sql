-- Add per-device Daily Event theme selector for Digital Signage.
-- Run AFTER docs/db/signage_schema.sql on existing databases.

alter table public.sg_devices
add column if not exists event_theme text not null default 'classic';

-- Selalu drop constraint yang lama agar bisa direplace dengan update terbaru
alter table public.sg_devices drop constraint if exists sg_devices_event_theme_check;

alter table public.sg_devices
  add constraint sg_devices_event_theme_check
  check (event_theme in (
    'classic',
    'modern_dark',
    'hotel_elegant',
    'minimal_light',
    'conference_board',
    'flight_board'
  ));
