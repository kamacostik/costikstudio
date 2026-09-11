-- Costik Signage subscription provisioning for CostikStudio.
-- Run after CostikStudio schema/RPC files and Signage schema.
-- Creates a signage tenant/profile for authenticated users with an active Costik Signage subscription.

create extension if not exists pgcrypto;

create or replace function public.provision_signage_tenant()
returns table (
  tenant_id uuid,
  profile_id uuid,
  tenant_name text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  profile_company text;
  profile_name text;
  existing_tenant_id uuid;
  new_tenant_id uuid;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not exists (
    select 1
    from public.subscriptions s
    where s.user_id = current_user_id
      and s.product_id = 'costik-signage'
      and s.status = 'active'
      and s.expires_at > now()
  ) then
    raise exception 'Active Costik Signage subscription required';
  end if;

  select p.company_name, p.full_name
    into profile_company, profile_name
  from public.profiles p
  where p.id = current_user_id;

  select sp.tenant_id
    into existing_tenant_id
  from public.sg_profiles sp
  where sp.id = current_user_id;

  if existing_tenant_id is null then
    insert into public.sg_tenants (name)
    values (coalesce(nullif(profile_company, ''), nullif(profile_name, ''), 'Costik Signage Tenant'))
    returning id into new_tenant_id;

    insert into public.sg_profiles (id, tenant_id, role, full_name)
    values (
      current_user_id,
      new_tenant_id,
      'owner',
      coalesce(nullif(profile_name, ''), nullif(profile_company, ''), 'Costik Signage Owner')
    );
  else
    new_tenant_id := existing_tenant_id;

    update public.sg_tenants
    set name = coalesce(nullif(profile_company, ''), nullif(profile_name, ''), sg_tenants.name)
    where id = new_tenant_id;
  end if;

  return query
  select
    t.id,
    current_user_id,
    t.name
  from public.sg_tenants t
  where t.id = new_tenant_id;
end;
$$;

revoke all on function public.provision_signage_tenant() from public;
grant execute on function public.provision_signage_tenant() to authenticated;
