create or replace function public.admin_get_billing_overview()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pending_topups jsonb;
  v_wallets jsonb;
  v_subscriptions jsonb;
  v_revenue_today numeric;
  v_revenue_month numeric;
  v_total_users integer;
  v_active_subs integer;
  v_total_devices integer;
begin
  -- Calculate overall metrics
  select count(*) into v_total_users from public.profiles;
  select count(*) into v_active_subs from public.subscriptions where status = 'active';
  select coalesce(sum(device_count), 0) into v_total_devices from public.subscriptions where status = 'active';

  -- Calculate Revenue Today (Top Ups Paid Today)
  select coalesce(sum(amount), 0)
  into v_revenue_today
  from public.payment_orders
  where status = 'paid'
    and created_at >= date_trunc('day', timezone('utc', now()));

  -- Calculate Revenue This Month
  select coalesce(sum(amount), 0)
  into v_revenue_month
  from public.payment_orders
  where status = 'paid'
    and created_at >= date_trunc('month', timezone('utc', now()));

  -- Fetch recent pending and paid topups
  select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
  into v_pending_topups
  from (
    select
      p.id,
      coalesce(pr.company_name, pr.full_name, 'Unknown User') as customer_name,
      p.amount,
      p.provider as method,
      p.status,
      p.created_at,
      p.external_reference
    from public.payment_orders p
    left join public.profiles pr on pr.id = p.user_id
    where p.type = 'wallet_topup'
    order by p.created_at desc
    limit 20
  ) t;

  -- Fetch customer wallets
  select coalesce(jsonb_agg(to_jsonb(w)), '[]'::jsonb)
  into v_wallets
  from (
    select
      coalesce(pr.company_name, pr.full_name, 'Unknown User') as customer_name,
      w.balance
    from public.wallets w
    left join public.profiles pr on pr.id = w.user_id
    order by w.balance desc
    limit 20
  ) w;

  -- Fetch active/recent subscriptions
  select coalesce(jsonb_agg(to_jsonb(s)), '[]'::jsonb)
  into v_subscriptions
  from (
    select
      s.id,
      s.user_id,
      coalesce(pr.company_name, pr.full_name, 'Unknown User') as customer_email,
      s.product_id as product_name,
      s.device_count,
      s.billing_cycle_months,
      s.status as status_text,
      s.created_at as started_at,
      s.expires_at
    from public.subscriptions s
    left join public.profiles pr on pr.id = s.user_id
    order by s.created_at desc
    limit 50
  ) s;

  return jsonb_build_object(
    'pendingTopUps', v_pending_topups,
    'customerWallets', v_wallets,
    'allSubscriptions', v_subscriptions,
    'revenueToday', v_revenue_today,
    'revenueMonth', v_revenue_month,
    'totalUsers', v_total_users,
    'activeSubs', v_active_subs,
    'totalDevices', v_total_devices
  );
end;
$$;

grant execute on function public.admin_get_billing_overview() to authenticated;
