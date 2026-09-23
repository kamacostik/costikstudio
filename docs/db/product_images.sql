-- Product gallery images for Costik Studio member product cards/details.
-- Admin can manage images from web admin; members can read active images.

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update set public = excluded.public;

-- Gallery product ids must match the public app catalog ids exactly.
-- Safe to run repeatedly; this prevents FK upload failures when adding images
-- from the web admin before the billing/subscription seed has created products.
insert into public.products (
  id,
  name,
  tagline,
  price_per_device,
  metadata
) values
  (
    'costik-iptv',
    'Costik IPTV',
    'Hotel IPTV, live TV, and guest information system.',
    20000,
    jsonb_build_object('gallery_upload_enabled', true)
  ),
  (
    'digital-signage',
    'Digital Signage',
    'Event schedule board and fullscreen video signage for hotels.',
    20000,
    jsonb_build_object('gallery_upload_enabled', true, 'billing_product_id', 'costik-signage')
  ),
  (
    'adb-manager',
    'ADB Manager',
    'Desktop tool for managing Android TV devices via ADB.',
    0,
    jsonb_build_object('gallery_upload_enabled', true)
  )
on conflict (id) do update set
  name = excluded.name,
  tagline = excluded.tagline,
  price_per_device = excluded.price_per_device,
  metadata = coalesce(public.products.metadata, '{}'::jsonb) || excluded.metadata;

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id text not null references public.products(id) on delete cascade,
  image_url text not null,
  title text,
  alt_text text,
  sort_order bigint not null default 0,
  is_cover boolean not null default false,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create index if not exists product_images_product_id_sort_order_idx
  on public.product_images (product_id, sort_order, created_at);

-- Migration for databases created before sort_order became bigint:
-- upload timestamps (milliseconds since epoch) exceed integer range.
alter table public.product_images
  alter column sort_order type bigint;

create unique index if not exists product_images_single_cover_idx
  on public.product_images (product_id)
  where is_cover and is_active;

alter table public.product_images enable row level security;

drop policy if exists "product images are readable" on public.product_images;
drop policy if exists "product images are publicly readable" on public.product_images;
create policy "product images are publicly readable"
  on public.product_images
  for select
  to anon, authenticated
  using (is_active = true);

-- Admin accounts are identified by public.profiles.role = 'admin'.
drop policy if exists "product images are admin manageable" on public.product_images;
create policy "product images are admin manageable"
  on public.product_images
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

create or replace function public.set_product_images_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists product_images_set_updated_at on public.product_images;
create trigger product_images_set_updated_at
  before update on public.product_images
  for each row
  execute function public.set_product_images_updated_at();

-- Storage policies for the public product image bucket.
drop policy if exists "product images storage is readable" on storage.objects;
drop policy if exists "product images storage is publicly readable" on storage.objects;
create policy "product images storage is publicly readable"
  on storage.objects
  for select
  to anon, authenticated
  using (bucket_id = 'product-images');

drop policy if exists "product images storage is admin insertable" on storage.objects;
create policy "product images storage is admin insertable"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'product-images'
    and exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role = 'admin'
    )
  );

drop policy if exists "product images storage is admin updatable" on storage.objects;
create policy "product images storage is admin updatable"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'product-images'
    and exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role = 'admin'
    )
  )
  with check (
    bucket_id = 'product-images'
    and exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role = 'admin'
    )
  );
