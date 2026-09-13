-- IPTV media limits for subscription/package enforcement.
-- Run this in the shared Supabase database before enforcing upload rules in admin_iptv.

alter table if exists public.products
  add column if not exists metadata jsonb not null default '{}'::jsonb;

alter table if exists public.subscriptions
  add column if not exists media_limits jsonb not null default '{}'::jsonb;

comment on column public.products.metadata is
  'Product-level defaults and feature limits such as IPTV media upload quota.';

comment on column public.subscriptions.media_limits is
  'Snapshot of media/upload limits granted when the subscription was created or updated.';

update public.products
set metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
  'media_storage_limit_mb', 500,
  'image_upload_enabled', true,
  'video_upload_enabled', false,
  'video_max_file_size_mb', 30,
  'video_max_duration_seconds', 30,
  'video_active_limit', 0
)
where id = 'costik-iptv';

update public.subscriptions
set media_limits = coalesce(media_limits, '{}'::jsonb) || jsonb_build_object(
  'media_storage_limit_mb', 500,
  'image_upload_enabled', true,
  'video_upload_enabled', false,
  'video_max_file_size_mb', 30,
  'video_max_duration_seconds', 30,
  'video_active_limit', 0
)
where product_id = 'costik-iptv'
  and coalesce(media_limits, '{}'::jsonb) = '{}'::jsonb;
