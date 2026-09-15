-- Product gallery images for Costik Studio member product cards/details.
-- Admin can manage images from web admin; members can read active images.

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id text not null references public.products(id) on delete cascade,
  image_url text not null,
  title text,
  alt_text text,
  sort_order integer not null default 0,
  is_cover boolean not null default false,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create index if not exists product_images_product_id_sort_order_idx
  on public.product_images (product_id, sort_order, created_at);

create unique index if not exists product_images_single_cover_idx
  on public.product_images (product_id)
  where is_cover and is_active;

alter table public.product_images enable row level security;

drop policy if exists "product images are readable" on public.product_images;
create policy "product images are readable"
  on public.product_images
  for select
  to authenticated
  using (is_active = true);

-- Assumes existing admin role helper/table policies are enforced by the admin app.
-- Adjust the predicate if the production project uses a different admin-role helper.
drop policy if exists "product images are admin manageable" on public.product_images;
create policy "product images are admin manageable"
  on public.product_images
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.admin_profiles ap
      where ap.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.admin_profiles ap
      where ap.user_id = auth.uid()
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
