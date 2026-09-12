-- Make signage media bucket public for TV/browser clients.
-- Run this on existing databases that already created the signage-media bucket.

insert into storage.buckets (id, name, public)
values ('signage-media', 'signage-media', true)
on conflict (id) do update set public = true;
