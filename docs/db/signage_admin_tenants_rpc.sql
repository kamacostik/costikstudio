-- Admin RPC: list all Signage tenants with subscription + device summary.
-- Trusted backoffice read for CostikStudio admin web.
-- Requires profiles.role = 'admin' on the caller.
-- Run in Supabase SQL Editor after signage_schema.sql + schema_iptv.sql.

create or replace function public.admin_list_signage_tenants()
returns table (
  tenant_id uuid,
  tenant_name text,
  customer_user_id uuid,
  customer_email text,
  customer_name text,
  subscription_status text,
  subscription_device_count integer,
  subscription_expires_at timestamptz,
  device_total bigint,
  device_active bigint
)
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_role text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select p.role into caller_role
  from public.profiles p
  where p.id = auth.uid();

  if caller_role is distinct from 'admin' then
    raise exception 'Admin access required';
  end if;

  return query
  select
    t.id as tenant_id,
    t.name as tenant_name,
    sp.id as customer_user_id,
    au.email as customer_email,
    coalesce(sp.full_name, p.full_name, '') as customer_name,
    s.status as subscription_status,
    s.device_count as subscription_device_count,
    s.expires_at as subscription_expires_at,
    coalesce(d.device_total, 0) as device_total,
    coalesce(d.device_active, 0) as device_active
  from public.sg_tenants t
  left join public.sg_profiles sp
    on sp.tenant_id = t.id
    and sp.role = 'owner'
  left join auth.users au
    on au.id = sp.id
  left join public.profiles p
    on p.id = sp.id
  left join lateral (
    select
      sub.status,
      sub.device_count,
      sub.expires_at
    from public.subscriptions sub
    where sub.user_id = sp.id
      and sub.product_id = 'costik-signage'
    order by sub.created_at desc
    limit 1
  ) s on true
  left join lateral (
    select
      count(*) as device_total,
      count(*) filter (where dev.is_active) as device_active
    from public.sg_devices dev
    where dev.tenant_id = t.id
  ) d on true
  order by t.created_at desc;
end;
$$;

revoke all on function public.admin_list_signage_tenants() from public;
grant execute on function public.admin_list_signage_tenants() to authenticated;
