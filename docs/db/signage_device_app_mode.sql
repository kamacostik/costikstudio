-- Per-device app mode for Signage devices: Daily Event board vs Video Player.
-- Run AFTER docs/db/signage_schema.sql on existing databases.
alter table public.sg_devices
add column if not exists app_mode text not null default 'daily_event';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'sg_devices_app_mode_check'
  ) then
    alter table public.sg_devices
      add constraint sg_devices_app_mode_check
      check (app_mode in ('daily_event', 'video_player'));
  end if;
end
$$;
