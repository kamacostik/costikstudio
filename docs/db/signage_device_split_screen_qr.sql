-- Migration to add Smart QR Overlay and Split Screen mode

alter table public.sg_devices drop constraint if exists sg_devices_app_mode_check;
alter table public.sg_devices add constraint sg_devices_app_mode_check check (app_mode in ('daily_event', 'video_player', 'split_screen'));

alter table public.sg_devices add column if not exists qr_url text;
alter table public.sg_devices add column if not exists qr_enabled boolean not null default false;
