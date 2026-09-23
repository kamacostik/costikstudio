create table if not exists public.tutorial_videos (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  video_id text not null,
  description text,
  sort_order bigint not null default 0,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

alter table public.tutorial_videos enable row level security;

drop policy if exists "tutorial videos are readable by authenticated" on public.tutorial_videos;
create policy "tutorial videos are readable by authenticated"
  on public.tutorial_videos
  for select
  to authenticated
  using (is_active = true);

drop policy if exists "tutorial videos are admin manageable" on public.tutorial_videos;
create policy "tutorial videos are admin manageable"
  on public.tutorial_videos
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role = 'admin'
    )
  )
  with check (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role = 'admin'
    )
  );

create or replace function public.set_tutorial_videos_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists tutorial_videos_set_updated_at on public.tutorial_videos;
create trigger tutorial_videos_set_updated_at
  before update on public.tutorial_videos
  for each row
  execute function public.set_tutorial_videos_updated_at();

-- Insert default dummy data to populate the grid initially
insert into public.tutorial_videos (title, video_id, description, sort_order) values
('Konfigurasi DCO (Device Owner)', 'dQw4w9WgXcQ', 'Panduan lengkap cara mengaktifkan dan mengonfigurasi Device Owner pada STB/TV via ADB Manager.', 1),
('Instalasi Aplikasi via Jaringan', 'dQw4w9WgXcQ', 'Cara melakukan install dan update aplikasi IPTV secara massal melalui jaringan.', 2),
('Penggunaan Web Admin IPTV', 'dQw4w9WgXcQ', 'Panduan navigasi Web Admin untuk mengatur channel, VOD, dan layanan tamu hotel.', 3);
