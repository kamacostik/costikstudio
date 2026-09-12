# Costik Studio — Project Status Summary

_Last updated: 2026-09-11_

## Current project state

Costik Studio is being built as a Flutter SaaS portal focused on IPTV and Digital Signage billing, wallet/top-up, invoices, product onboarding, and separated user/admin experiences.

Digital Signage admin is moving into CostikStudio so the active runtime set becomes:
- `costikstudio` for SaaS portal, subscriptions, wallet, invoices, and Signage web admin.
- `4.-Client-Costik-Signage` for Android TV/player runtime.

The old Admin Signage repo is now reference/legacy for porting modules only.

## Active architecture decisions

- Flutter app uses package-first / clean feature composition style.
- User runtime and admin runtime stay separated:
  - User entry: `lib/main.dart`
  - Admin entry: `lib/main_admin.dart`
- Supabase config currently uses `assets/env/.env` for local/staging ease.
- Do not switch to `dart-define` until final hosting/upload stage.
- Secrets stay outside Flutter:
  - Sumopod API key must remain in n8n/backend only.
  - Supabase service role must never be exposed to Flutter.
- Billing, wallet, invoice, subscription mutations should go through trusted Supabase RPC/backend flows.

## Implemented SaaS billing features

### Wallet & top-up

- Wallet balance dashboard.
- Sumopod/n8n payment order flow.
- Same-tab redirect to Sumopod payment page.
- Success and cancel return pages:
  - `/payment/success`
  - `/payment/cancel`
- Auto check status and auto redirect back to Billing.
- Failed/cancelled/expired/error payment orders now appear in **Riwayat & Log → Top Up**.

### Invoice

- Paid wallet purchases generate invoice records.
- Top-up invoice support exists.
- Invoice UI and printable invoice page implemented.

### IPTV subscription lifecycle

- Initial IPTV checkout by device count and billing duration.
- Renew / Extend subscription.
- Upgrade Device with prorated pricing.
- Cancel subscription.
- Reactivate cancelled subscription.
- Admin subscription management.

## Current IPTV pricing logic

- IPTV price: Rp15.000 per device per month.
- Renewal cost:
  - `deviceCount * 15000 * billingCycleMonths`
- Upgrade Device cost:
  - `ceil(additionalDeviceCount * 15000 * remainingDays / 30)`
- Upgrade Device does **not** change expiry date.
- Additional devices expire together with the existing subscription.

## Important IPTV business rules

- User can only have one IPTV subscription record.
- If user already has active IPTV subscription:
  - Hide **Berlangganan Sekarang**.
  - Show info that subscription is already active.
  - Direct user to **Upgrade Device** instead.
- If user has cancelled IPTV subscription:
  - Hide **Berlangganan Sekarang**.
  - Show cancelled/inactive explanation.
  - Direct user to Subscription page to reactivate.
- Cancelled subscriptions cannot renew/upgrade until reactivated.
- Cancelled subscriptions show **Aktifkan Kembali**.

## Recent UI decisions implemented

- Dashboard summary cards only appear on Home Dashboard / main product tab:
  - Wallet Balance
  - Active Subscription
  - Latest Invoice
  - Payment Status
- Summary cards are hidden from Subscription, Billing Wallet, Activity, Invoice, Support, product detail, and IPTV order form.
- Upgrade Device popup now requires two steps:
  1. Select additional device count.
  2. Click **Proses Upgrade** near **Batal**.
- Selecting `+1/+2/+5/+10 Device` no longer immediately processes upgrade.
- Product tutorial/documentation/member resources moved from public product detail page to authenticated dashboard member area:
  - Dashboard → Sidebar Produk → Detail Produk
- Public product pages now show only basic/marketing product info and login CTA.

## Admin features implemented

- Admin Billing dashboard includes subscription management.
- Admin can view subscription list.
- Admin can extend subscription expiry.
- Admin can set/update device count.
- Admin management is admin-build/admin-route only.
- User app must not expose Admin Billing UI.

## SQL/RPC files to remember for Supabase E2E

Run/update these in Supabase when testing full backend flows:

1. `docs/db/signage_schema.sql` — creates `sg_profiles`, `sg_tenants`, hotel/device/media/playlist/event tables, RLS, and storage bucket.
2. `docs/db/signage_event_slide_duration.sql` — adds `event_slide_duration_seconds` for existing databases.
2b. `docs/db/signage_device_app_mode.sql` — adds `app_mode` (`daily_event`/`video_player`) for existing databases.
3. `docs/db/seed_signage_product.sql` — seeds `costik-signage` at Rp20.000/device/month.
4. `docs/db/signage_subscription_rpc.sql` — checkout Signage + wallet deduction + tenant/profile provisioning.
5. `docs/db/signage_subscription_lifecycle_rpc.sql` — renew, upgrade device, cancel, reactivate for Signage.
6. `docs/db/iptv_subscription_renewal_rpc.sql`
7. `docs/db/iptv_subscription_upgrade_device_rpc.sql`
8. `docs/db/iptv_subscription_cancel_rpc.sql`
9. `docs/db/iptv_subscription_reactivate_rpc.sql`
10. `docs/db/iptv_subscription_admin_management_rpc.sql`
11. `docs/db/signage_device_pairing_rpc.sql` — pairing/quota/delete device RPCs.
12. `docs/db/signage_client_payload_rpc.sql` — payload/heartbeat RPCs including `event_slide_duration_seconds` and `app_mode`.

Important fixed SQL issue:
- Old upgrade RPC used obsolete wallet columns:
  - `balance_before`
  - `balance_after`
  - `reference_id`
- Current RPC matches actual schema using:
  - `user_id`
  - `type`
  - `amount`
  - `description`
  - `status`

## n8n / Sumopod notes

- Flutter should call n8n create-payment webhook, not Sumopod directly.
- Production create-payment endpoint currently expected in env as:
  - `SUMOPOD_CREATE_PAYMENT_WEBHOOK_URL`
- App should call `/webhook/...`, not `/webhook-test/...`, when workflow is active.
- Webhook token validation is done in n8n IF node/manual compare if env access is blocked.
- Missing/invalid webhook token must return 401 and must not apply wallet balance.

## Current latest pushed commits

- `70b2cf7 fix: move product resources to member dashboard`
- `4aaed15 feat: show failed payment orders in billing history`
- `2f0e4b2 feat: block duplicate IPTV subscription for existing subscribers`
- `8296e04 fix: confirm upgrade device before processing`

## Latest verified state

After the latest commit:

- `flutter analyze` clean.
- `flutter test` passed: 67/67.
- `flutter build web --release` succeeded.

## Recommended next steps when returning

1. Test member Dashboard → Produk flow in Chrome.
2. Confirm public product page no longer exposes documentation/tutorial.
3. Run/update Supabase RPC SQL files before backend E2E.
4. Test Sumopod/n8n failed/cancelled payment orders appear in Riwayat & Log.
5. Continue SaaS hardening:
   - backend guard for single IPTV subscription in RPC,
   - stricter direct-route guard for `/subscribe-iptv`,
   - richer payment failure reason display,
   - customer subscription detail page polishing.
