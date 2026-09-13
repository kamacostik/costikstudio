-- Seed CostikStudio IPTV product catalog.
-- Safe to run multiple times.

insert into public.products (
  id,
  name,
  tagline,
  price_per_device,
  metadata
) values (
  'costik-iptv',
  'Costik IPTV',
  'Live TV and guest room entertainment flow for hotels and hospitality businesses.',
  20000,
  jsonb_build_object(
    'media_storage_limit_mb', 500,
    'image_upload_enabled', true,
    'video_upload_enabled', false,
    'video_max_file_size_mb', 30,
    'video_max_duration_seconds', 30,
    'video_active_limit', 0
  )
)
on conflict (id) do update set
  name = excluded.name,
  tagline = excluded.tagline,
  price_per_device = excluded.price_per_device,
  metadata = coalesce(public.products.metadata, '{}'::jsonb) || excluded.metadata;
