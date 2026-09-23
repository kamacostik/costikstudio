-- Migration to add dynamic promo cards for Split Screen mode
alter table public.sg_devices add column if not exists promo_cards jsonb default '[]'::jsonb;
