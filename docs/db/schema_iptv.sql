-- SaaS Database Schema for CostikStudio IPTV
-- Includes Row Level Security (RLS) policies so users can only access their own data.

-- Enable Row Level Security & helper triggers
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

create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);

create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id);

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

create policy "Users can view own licences" on public.licences
  for select using (auth.uid() = user_id);

create policy "Users can insert own licences" on public.licences
  for insert with check (auth.uid() = user_id);

create policy "Users can update own licences" on public.licences
  for update using (auth.uid() = user_id);


-- 3. Wallets Table (User Balance)
create table if not exists public.wallets (
  id uuid not null default gen_random_uuid() primary key,
  user_id uuid not null unique references auth.users(id) on delete cascade,
  balance numeric(15, 2) not null default 0 check (balance >= 0),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

alter table public.wallets enable row level security;

create policy "Users can view own wallet" on public.wallets
  for select using (auth.uid() = user_id);

create policy "Users can update own wallet" on public.wallets
  for update using (auth.uid() = user_id);

create policy "Users can insert own wallet" on public.wallets
  for insert with check (auth.uid() = user_id);


-- 4. Products Table (Global Read-Only Catalog)
create table if not exists public.products (
  id text not null primary key,
  name text not null,
  tagline text null,
  price_per_device numeric(15, 2) not null default 15000,
  created_at timestamp with time zone default now()
);

alter table public.products enable row level security;

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

create policy "Users can view own subscriptions" on public.subscriptions
  for select using (auth.uid() = user_id);

create policy "Users can insert own subscriptions" on public.subscriptions
  for insert with check (auth.uid() = user_id);

create policy "Users can update own subscriptions" on public.subscriptions
  for update using (auth.uid() = user_id);


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

create policy "Users can view own transactions" on public.wallet_transactions
  for select using (auth.uid() = user_id);

create policy "Users can insert own transactions" on public.wallet_transactions
  for insert with check (auth.uid() = user_id);


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

create policy "Users can view own invoices" on public.invoices
  for select using (auth.uid() = user_id);

create policy "Users can insert own invoices" on public.invoices
  for insert with check (auth.uid() = user_id);


-- Automatically create profile and wallet upon signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, new.raw_user_meta_data->>'full_name', 'customer');

  insert into public.wallets (user_id, balance)
  values (new.id, 0);

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
