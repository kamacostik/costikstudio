-- SaaS Database Schema for CostikStudio IPTV
-- Secure multi-tenant schema: customer clients can only read their own data.
-- Billing writes must be done by trusted backend/RPC/Edge Function/service-role flows.

-- Helper trigger for updated_at columns
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- 1. Profiles Table (User details)
create table if not exists public.profiles (
  id uuid not null primary key references auth.users(id) on delete cascade,
  full_name text null,
  company_name text null,
  phone text null,
  role text not null default 'customer',
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;

create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);

create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

create policy "Users can insert own profile" on public.profiles
  for insert with check (auth.uid() = id);


-- 2. Licences Table (IPTV Device Licences)
create table if not exists public.licences (
  id uuid not null default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  start_date timestamp with time zone null default now(),
  expired_date timestamp with time zone null,
  device_count integer null default 0,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone default now()
);

alter table public.licences enable row level security;

drop policy if exists "Users can view own licences" on public.licences;
drop policy if exists "Users can insert own licences" on public.licences;
drop policy if exists "Users can update own licences" on public.licences;

create policy "Users can view own licences" on public.licences
  for select using (auth.uid() = user_id);


-- 3. Wallets Table (User Balance)
create table if not exists public.wallets (
  id uuid not null default gen_random_uuid() primary key,
  user_id uuid not null unique references auth.users(id) on delete cascade,
  balance numeric(15, 2) not null default 0 check (balance >= 0),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

alter table public.wallets enable row level security;

drop policy if exists "Users can view own wallet" on public.wallets;
drop policy if exists "Users can update own wallet" on public.wallets;
drop policy if exists "Users can insert own wallet" on public.wallets;

create policy "Users can view own wallet" on public.wallets
  for select using (auth.uid() = user_id);


-- 4. Products Table (Global Read-Only Catalog)
create table if not exists public.products (
  id text not null primary key,
  name text not null,
  tagline text null,
  price_per_device numeric(15, 2) not null default 20000,
  created_at timestamp with time zone default now()
);

alter table public.products enable row level security;

drop policy if exists "Anyone authenticated can view products" on public.products;

create policy "Anyone authenticated can view products" on public.products
  for select using (auth.role() = 'authenticated');


-- 5. Subscriptions Table (IPTV Subscriptions)
create table if not exists public.subscriptions (
  id uuid not null default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null references public.products(id),
  licence_id uuid null references public.licences(id) on delete set null,
  device_count integer not null default 1,
  billing_cycle_months integer not null default 1,
  total_amount numeric(15, 2) not null default 0,
  status text not null default 'active',
  starts_at timestamp with time zone default now(),
  expires_at timestamp with time zone not null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

alter table public.subscriptions enable row level security;

drop policy if exists "Users can view own subscriptions" on public.subscriptions;
drop policy if exists "Users can insert own subscriptions" on public.subscriptions;
drop policy if exists "Users can update own subscriptions" on public.subscriptions;

create policy "Users can view own subscriptions" on public.subscriptions
  for select using (auth.uid() = user_id);


-- 6. Wallet Transactions Table (Top-Up & Payment History)
create table if not exists public.wallet_transactions (
  id uuid not null default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null, -- 'topup', 'subscription_payment', 'renew'
  amount numeric(15, 2) not null,
  description text null,
  status text not null default 'completed',
  created_at timestamp with time zone default now()
);

alter table public.wallet_transactions enable row level security;

drop policy if exists "Users can view own transactions" on public.wallet_transactions;
drop policy if exists "Users can insert own transactions" on public.wallet_transactions;

create policy "Users can view own transactions" on public.wallet_transactions
  for select using (auth.uid() = user_id);


-- 7. Invoices Table (Billing Invoices)
create table if not exists public.invoices (
  id uuid not null default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  transaction_id uuid null references public.wallet_transactions(id) on delete cascade,
  invoice_number text not null unique,
  amount numeric(15, 2) not null,
  status text not null default 'paid',
  issued_at timestamp with time zone default now()
);

alter table public.invoices enable row level security;

drop policy if exists "Users can view own invoices" on public.invoices;
drop policy if exists "Users can insert own invoices" on public.invoices;

create policy "Users can view own invoices" on public.invoices
  for select using (auth.uid() = user_id);


-- Automatically create profile and wallet upon signup.
-- Runs as security definer, so it can insert into profiles/wallets even though customers cannot.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, new.raw_user_meta_data->>'full_name', 'customer')
  on conflict (id) do nothing;

  insert into public.wallets (user_id, balance)
  values (new.id, 0)
  on conflict (user_id) do nothing;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
