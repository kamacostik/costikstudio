-- Seed CostikStudio Digital Signage product catalog.
-- Safe to run multiple times.

insert into public.products (
  id,
  name,
  tagline,
  price_per_device
) values (
  'costik-signage',
  'Costik Signage',
  'Digital signage and screen content management for hotels and businesses.',
  20000
)
on conflict (id) do update set
  name = excluded.name,
  tagline = excluded.tagline,
  price_per_device = excluded.price_per_device;
