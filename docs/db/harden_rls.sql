-- Harden existing CostikStudio IPTV RLS policies.
-- Run this in Supabase SQL Editor after schema_iptv.sql if the earlier permissive policies were already applied.
-- Customer clients keep read-only access to their own billing/licence data.
-- Billing mutations must be handled by trusted backend/RPC/Edge Function/service-role flows.

alter table public.profiles enable row level security;
alter table public.licences enable row level security;
alter table public.wallets enable row level security;
alter table public.products enable row level security;
alter table public.subscriptions enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.invoices enable row level security;

-- Profiles: users may manage only their own profile.
drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;

create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);

create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

create policy "Users can insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

-- Licences: user can only read own licence. No client insert/update/delete.
drop policy if exists "Users can view own licences" on public.licences;
drop policy if exists "Users can insert own licences" on public.licences;
drop policy if exists "Users can update own licences" on public.licences;

create policy "Users can view own licences" on public.licences
  for select using (auth.uid() = user_id);

-- Wallets: user can only read own wallet. No client insert/update/delete.
drop policy if exists "Users can view own wallet" on public.wallets;
drop policy if exists "Users can update own wallet" on public.wallets;
drop policy if exists "Users can insert own wallet" on public.wallets;

create policy "Users can view own wallet" on public.wallets
  for select using (auth.uid() = user_id);

-- Products: authenticated read-only catalog.
drop policy if exists "Anyone authenticated can view products" on public.products;

create policy "Anyone authenticated can view products" on public.products
  for select using (auth.role() = 'authenticated');

-- Subscriptions: user can only read own subscription. No client insert/update/delete.
drop policy if exists "Users can view own subscriptions" on public.subscriptions;
drop policy if exists "Users can insert own subscriptions" on public.subscriptions;
drop policy if exists "Users can update own subscriptions" on public.subscriptions;

create policy "Users can view own subscriptions" on public.subscriptions
  for select using (auth.uid() = user_id);

-- Wallet transactions: user can only read own transactions. No client insert/update/delete.
drop policy if exists "Users can view own transactions" on public.wallet_transactions;
drop policy if exists "Users can insert own transactions" on public.wallet_transactions;

create policy "Users can view own transactions" on public.wallet_transactions
  for select using (auth.uid() = user_id);

-- Invoices: user can only read own invoices. No client insert/update/delete.
drop policy if exists "Users can view own invoices" on public.invoices;
drop policy if exists "Users can insert own invoices" on public.invoices;

create policy "Users can view own invoices" on public.invoices
  for select using (auth.uid() = user_id);
