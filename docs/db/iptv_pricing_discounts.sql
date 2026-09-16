-- Costik IPTV pricing: base price, volume discounts, and launch vouchers.
-- Run after products table exists and costik-iptv product has been seeded.

update public.products
set price_per_device = 50000
where id = 'costik-iptv';

create table if not exists public.product_volume_discounts (
  id uuid primary key default gen_random_uuid(),
  product_id text not null references public.products(id) on delete cascade,
  min_quantity integer not null,
  discount_percent numeric not null default 0,
  label text,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint product_volume_discounts_min_quantity_check check (min_quantity > 0),
  constraint product_volume_discounts_percent_check check (
    discount_percent >= 0 and discount_percent <= 100
  ),
  unique (product_id, min_quantity)
);

create index if not exists product_volume_discounts_product_idx
  on public.product_volume_discounts (product_id, min_quantity desc)
  where is_active = true;

create table if not exists public.promo_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  product_id text references public.products(id) on delete cascade,
  discount_percent numeric not null default 0,
  starts_at timestamp with time zone,
  ends_at timestamp with time zone,
  max_redemptions integer,
  max_redemptions_per_user integer not null default 1,
  new_customer_only boolean not null default true,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint promo_codes_code_upper_check check (code = upper(trim(code))),
  constraint promo_codes_percent_check check (
    discount_percent >= 0 and discount_percent <= 100
  ),
  constraint promo_codes_max_redemptions_check check (
    max_redemptions is null or max_redemptions > 0
  ),
  constraint promo_codes_per_user_check check (max_redemptions_per_user > 0)
);

create index if not exists promo_codes_product_idx
  on public.promo_codes (product_id, code)
  where is_active = true;

create table if not exists public.promo_redemptions (
  id uuid primary key default gen_random_uuid(),
  promo_code_id uuid not null references public.promo_codes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null references public.products(id) on delete cascade,
  subscription_id uuid,
  invoice_id uuid,
  discount_amount numeric not null default 0,
  redeemed_at timestamp with time zone not null default now(),
  constraint promo_redemptions_discount_amount_check check (discount_amount >= 0)
);

create index if not exists promo_redemptions_code_idx
  on public.promo_redemptions (promo_code_id);

create unique index if not exists promo_redemptions_user_code_idx
  on public.promo_redemptions (user_id, promo_code_id);

alter table public.product_volume_discounts enable row level security;
alter table public.promo_codes enable row level security;
alter table public.promo_redemptions enable row level security;

drop policy if exists "pricing discounts are publicly readable" on public.product_volume_discounts;
create policy "pricing discounts are publicly readable"
  on public.product_volume_discounts for select
  to anon, authenticated
  using (is_active = true);

drop policy if exists "promo codes are publicly readable" on public.promo_codes;
create policy "promo codes are publicly readable"
  on public.promo_codes for select
  to anon, authenticated
  using (is_active = true);

drop policy if exists "customers can read own promo redemptions" on public.promo_redemptions;
create policy "customers can read own promo redemptions"
  on public.promo_redemptions for select
  to authenticated
  using (user_id = auth.uid());

insert into public.product_volume_discounts (
  product_id,
  min_quantity,
  discount_percent,
  label
) values
  ('costik-iptv', 1, 0, '1–9 device'),
  ('costik-iptv', 10, 10, '10+ device'),
  ('costik-iptv', 50, 30, '50+ device'),
  ('costik-iptv', 100, 60, '100+ device')
on conflict (product_id, min_quantity) do update
set discount_percent = excluded.discount_percent,
    label = excluded.label,
    is_active = true,
    updated_at = now();

insert into public.promo_codes (
  code,
  product_id,
  discount_percent,
  new_customer_only,
  max_redemptions_per_user,
  is_active
) values
  ('WELCOME20', 'costik-iptv', 20, true, 1, true),
  ('LAUNCH30', 'costik-iptv', 30, true, 1, true)
on conflict (code) do update
set product_id = excluded.product_id,
    discount_percent = excluded.discount_percent,
    new_customer_only = excluded.new_customer_only,
    max_redemptions_per_user = excluded.max_redemptions_per_user,
    is_active = true,
    updated_at = now();
