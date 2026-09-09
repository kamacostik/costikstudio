-- Schema for IPTV license management
create table public.licences (
  id uuid not null default gen_random_uuid (),
  user_id uuid null,
  start_date timestamp with time zone null default now(),
  expired_date timestamp with time zone null,
  device_count integer null default 0,
  created_at timestamp with time zone null default now(),
  constraint licences_pkey primary key (id),
  constraint licences_user_id_fkey foreign KEY (user_id) references auth.users (id)
) TABLESPACE pg_default;
