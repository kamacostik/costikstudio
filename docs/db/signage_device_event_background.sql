-- Per-device Daily Event empty-state background.
-- Run AFTER docs/db/signage_schema.sql on existing databases.

alter table public.sg_devices
add column if not exists event_background_url text;
