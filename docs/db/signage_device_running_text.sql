-- Add per-device running text/ticker settings for Digital Signage.
alter table public.sg_devices
add column if not exists running_text_enabled boolean not null default false;

alter table public.sg_devices
add column if not exists running_text text;
