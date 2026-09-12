-- Dedicated Daily Event slide duration for Signage devices.
-- Run AFTER docs/db/signage_schema.sql on existing databases.
-- promo_duration/table_column stay reserved for the legacy promo slideshow.
alter table public.sg_devices
add column if not exists event_slide_duration_seconds integer not null default 7;
