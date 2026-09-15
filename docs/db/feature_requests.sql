-- Feature request storage for CostikStudio member dashboard.
-- Run after products/profiles schemas exist.

create table if not exists public.feature_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null references public.products(id) on delete restrict,
  product_name text not null,
  title text not null,
  description text not null,
  status text not null default 'pending',
  admin_note text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint feature_requests_status_check check (
    status in ('pending', 'reviewing', 'planned', 'done', 'rejected')
  ),
  constraint feature_requests_title_not_blank check (length(trim(title)) > 0),
  constraint feature_requests_description_not_blank check (length(trim(description)) > 0)
);

create index if not exists feature_requests_user_created_idx
  on public.feature_requests (user_id, created_at desc);

create index if not exists feature_requests_status_created_idx
  on public.feature_requests (status, created_at desc);

alter table public.feature_requests enable row level security;

drop policy if exists "feature requests insert own" on public.feature_requests;
create policy "feature requests insert own"
  on public.feature_requests
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "feature requests select own" on public.feature_requests;
create policy "feature requests select own"
  on public.feature_requests
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "feature requests admin manage" on public.feature_requests;
create policy "feature requests admin manage"
  on public.feature_requests
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

create or replace function public.set_feature_requests_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_feature_requests_updated_at on public.feature_requests;
create trigger set_feature_requests_updated_at
  before update on public.feature_requests
  for each row
  execute function public.set_feature_requests_updated_at();
