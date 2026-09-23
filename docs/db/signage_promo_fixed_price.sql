-- 1. Add fixed_price to promo_codes
alter table public.promo_codes
add column if not exists fixed_price numeric;

alter table public.promo_codes drop constraint if exists promo_codes_discount_type_check;

alter table public.promo_codes
add constraint promo_codes_discount_type_check check (
  (discount_percent > 0 and fixed_price is null) or
  (discount_percent = 0 and fixed_price is not null) or
  (discount_percent = 0 and fixed_price is null)
);

-- 2. Insert HITAINTIM promo code for costik-signage
insert into public.promo_codes (
  code,
  product_id,
  fixed_price,
  max_redemptions,
  max_redemptions_per_user,
  new_customer_only,
  is_active
) values (
  'HITAINTIM',
  'costik-signage',
  10000,
  50,
  1,
  false,
  true
) on conflict (code) do update
set product_id = excluded.product_id,
    fixed_price = excluded.fixed_price,
    max_redemptions = excluded.max_redemptions,
    max_redemptions_per_user = excluded.max_redemptions_per_user,
    new_customer_only = excluded.new_customer_only,
    is_active = true,
    updated_at = now();