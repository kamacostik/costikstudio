-- Seed CostikStudio IPTV product catalog.
-- Safe to run multiple times.

insert into public.products (
  id,
  name,
  tagline,
  price_per_device
) values (
  'costik-iptv',
  'Costik IPTV',
  'Live TV and guest room entertainment flow for hotels and hospitality businesses.',
  20000
)
on conflict (id) do update set
  name = excluded.name,
  tagline = excluded.tagline,
  price_per_device = excluded.price_per_device;
