# Costik IPTV Device Pricing & Launch Discount Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Membuat sistem harga Costik IPTV berbasis jumlah device dengan harga dasar Rp 50.000/device/bulan, diskon volume untuk 10/50/100 device, dan promo launching untuk customer baru.

**Architecture:** Pricing harus dihitung dari satu sumber kebenaran yang dipakai UI dan RPC database. UI menampilkan estimasi, tapi nilai final tetap dihitung di Supabase RPC agar wallet deduction, subscription, transaction, dan invoice tidak bisa dimanipulasi dari client. Promo launching dibuat sebagai tabel/kode diskon agar bisa aktif/nonaktif tanpa deploy ulang aplikasi.

**Tech Stack:** Flutter, Cubit/BLoC, Supabase PostgreSQL/RPC, existing wallet billing flow, TDD.

---

## Current Context

- Halaman subscription IPTV saat ini ada di `lib/features/subscription/view/iptv_subscription_page.dart`.
- UI saat ini menghitung total sederhana:
  - `deviceCount * pricePerDevice * billingCycleMonths + addonTotal`
- Harga produk dimuat dari tabel `products.price_per_device` melalui billing snapshot.
- RPC checkout saat ini ada di `docs/db/iptv_subscription_rpc.sql` dan menghitung:
  - `product.price_per_device * device_count * billing_cycle_months`
- Upgrade device kemungkinan perlu ikut aturan pricing/diskon juga di:
  - `docs/db/iptv_subscription_upgrade_device_rpc.sql`
- File n8n lokal `docs/db/n8n_sumopod_create_payment_webhook.json` sedang modified dan tidak boleh ikut commit pricing ini.

---

## Proposed Business Plan

### Base Price

- Harga baru: **Rp 50.000 / device / bulan**.
- Harga berlaku untuk Costik IPTV.
- `products.price_per_device` untuk `costik-iptv` perlu diupdate ke `50000`.

### Volume Discount Tier

| Jumlah Device | Diskon Volume | Harga Efektif / Device / Bulan | Total / Bulan |
|---:|---:|---:|---:|
| 1–9 | 0% | Rp 50.000 | device × Rp 50.000 |
| 10–49 | 10% | Rp 45.000 | 10 device = Rp 450.000 |
| 50–99 | 20% | Rp 40.000 | 50 device = Rp 2.000.000 |
| 100+ | 30% | Rp 35.000 | 100 device = Rp 3.500.000 |

Rationale:
- 1 device tidak diskon supaya harga dasar jelas.
- 10 device mulai terasa menarik untuk hotel kecil/villa.
- 50 device cocok hotel menengah.
- 100 device cocok hotel besar/resort dan masih menjaga ARPU.

### Launch Discount for New Customers

Promo launching harus terpisah dari diskon volume.

Rekomendasi awal:

| Kode Promo | Target | Diskon | Maksimal | Catatan |
|---|---|---:|---:|---|
| `WELCOME20` | Customer baru | 20% | 1 transaksi pertama | Aman untuk public launching |
| `LAUNCH30` | Customer baru batch awal/terbatas | 30% | 1 transaksi pertama | Gunakan dengan kuota/tanggal expired |
| `HOTEL50FIRST` | Deal manual khusus | 50% | Admin/manual only | Jangan tampil publik default |

Aturan:
- Promo hanya untuk customer baru yang belum pernah punya subscription aktif/paid untuk `costik-iptv`.
- Promo diterapkan setelah diskon volume.
- Promo punya tanggal mulai/akhir, max redemption global, max redemption per user.
- Simpan redemption supaya kode yang sama tidak bisa dipakai berulang.

Formula final:

```text
base_subtotal = base_price_per_device * device_count * billing_cycle_months
volume_discount_amount = base_subtotal * volume_discount_percent
subtotal_after_volume = base_subtotal - volume_discount_amount
launch_discount_amount = subtotal_after_volume * promo_discount_percent
final_total = subtotal_after_volume - launch_discount_amount + addon_total
```

Contoh:
- 10 device, 1 bulan:
  - Base: 10 × 50.000 = Rp 500.000
  - Volume 10%: -Rp 50.000
  - Subtotal: Rp 450.000
  - Promo WELCOME20: -Rp 90.000
  - Final: Rp 360.000

---

## Data Model Plan

### Task 1: Add SQL pricing tables/docs

**Objective:** Buat struktur diskon volume dan promo launching di Supabase.

**Files:**
- Create: `docs/db/iptv_pricing_discounts.sql`
- Modify optionally: `docs/db/seed_iptv_product.sql`

**Tables:**

```sql
create table if not exists public.product_volume_discounts (
  id uuid primary key default gen_random_uuid(),
  product_id text not null references public.products(id) on delete cascade,
  min_quantity integer not null,
  discount_percent numeric not null default 0,
  label text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint product_volume_discounts_min_quantity_check check (min_quantity > 0),
  constraint product_volume_discounts_percent_check check (discount_percent >= 0 and discount_percent <= 100),
  unique (product_id, min_quantity)
);

create table if not exists public.promo_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  product_id text references public.products(id) on delete cascade,
  discount_percent numeric not null default 0,
  starts_at timestamptz,
  ends_at timestamptz,
  max_redemptions integer,
  max_redemptions_per_user integer not null default 1,
  new_customer_only boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint promo_codes_percent_check check (discount_percent >= 0 and discount_percent <= 100),
  constraint promo_codes_max_redemptions_check check (max_redemptions is null or max_redemptions > 0),
  constraint promo_codes_per_user_check check (max_redemptions_per_user > 0)
);

create table if not exists public.promo_redemptions (
  id uuid primary key default gen_random_uuid(),
  promo_code_id uuid not null references public.promo_codes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null references public.products(id) on delete cascade,
  subscription_id uuid,
  invoice_id uuid,
  discount_amount numeric not null default 0,
  redeemed_at timestamptz not null default now()
);
```

**Seed:**

```sql
update public.products
set price_per_device = 50000
where id = 'costik-iptv';

insert into public.product_volume_discounts (product_id, min_quantity, discount_percent, label)
values
  ('costik-iptv', 1, 0, '1–9 devices'),
  ('costik-iptv', 10, 10, '10+ devices'),
  ('costik-iptv', 50, 20, '50+ devices'),
  ('costik-iptv', 100, 30, '100+ devices')
on conflict (product_id, min_quantity) do update
set discount_percent = excluded.discount_percent,
    label = excluded.label,
    is_active = true,
    updated_at = now();

insert into public.promo_codes (code, product_id, discount_percent, new_customer_only, max_redemptions_per_user, is_active)
values
  ('WELCOME20', 'costik-iptv', 20, true, 1, true),
  ('LAUNCH30', 'costik-iptv', 30, true, 1, true)
on conflict (code) do update
set discount_percent = excluded.discount_percent,
    product_id = excluded.product_id,
    new_customer_only = excluded.new_customer_only,
    max_redemptions_per_user = excluded.max_redemptions_per_user,
    is_active = true,
    updated_at = now();
```

**Validation:**
- Add/extend SQL schema tests if existing SQL validation test exists.
- Verify file contains `product_volume_discounts`, `promo_codes`, and `promo_redemptions`.

---

### Task 2: Add shared Dart pricing calculator

**Objective:** UI pricing estimate must not duplicate raw formula everywhere.

**Files:**
- Create: `lib/core/billing/device_pricing.dart`
- Test: `test/device_pricing_test.dart`

**Dart model idea:**

```dart
class DeviceDiscountTier {
  const DeviceDiscountTier({
    required this.minQuantity,
    required this.discountPercent,
    required this.label,
  });

  final int minQuantity;
  final int discountPercent;
  final String label;
}

class DevicePriceBreakdown {
  const DevicePriceBreakdown({
    required this.baseSubtotal,
    required this.volumeDiscountAmount,
    required this.launchDiscountAmount,
    required this.finalTotal,
    required this.effectivePricePerDevice,
    required this.volumeDiscountPercent,
  });

  final int baseSubtotal;
  final int volumeDiscountAmount;
  final int launchDiscountAmount;
  final int finalTotal;
  final int effectivePricePerDevice;
  final int volumeDiscountPercent;
}
```

**Default tiers:**

```dart
const iptvDefaultVolumeTiers = [
  DeviceDiscountTier(minQuantity: 1, discountPercent: 0, label: '1–9 device'),
  DeviceDiscountTier(minQuantity: 10, discountPercent: 10, label: '10+ device'),
  DeviceDiscountTier(minQuantity: 50, discountPercent: 20, label: '50+ device'),
  DeviceDiscountTier(minQuantity: 100, discountPercent: 30, label: '100+ device'),
];
```

**Required tests:**
- 1 device = no discount = Rp 50.000.
- 10 device = 10% = Rp 450.000/month.
- 50 device = 20% = Rp 2.000.000/month.
- 100 device = 30% = Rp 3.500.000/month.
- Launch 20% after volume: 10 device = Rp 360.000.

---

### Task 3: Update IPTV subscription UI pricing

**Objective:** User sees volume tier, discount amount, promo code field, and final payable total before checkout.

**Files:**
- Modify: `lib/features/subscription/view/iptv_subscription_page.dart`
- Test: existing subscription page tests or create `test/iptv_subscription_pricing_test.dart`

**UI changes:**
- Default device count can remain `10`, but show clearly:
  - Harga dasar: Rp 50.000/device/bulan
  - Diskon volume: `10%` etc
  - Harga efektif/device
  - Promo code input: `WELCOME20`
  - Total sebelum diskon
  - Total akhir
- Button checkout should send promo code to Cubit/repository/RPC.

**Important:** UI estimate is informational. Server RPC remains source of truth.

---

### Task 4: Extend repository and Cubit checkout API

**Objective:** Pass promo code into checkout without breaking existing calls.

**Files:**
- Modify: `lib/core/billing/billing_repository.dart`
- Modify: `lib/core/billing/supabase_billing_repository.dart`
- Modify: `lib/features/billing/cubit/billing_cubit.dart`
- Tests: `test/billing_cubit_test.dart`, `test/billing_repository_test.dart`

**API change:**

```dart
Future<BillingSnapshot> checkoutIptvSubscription({
  required int deviceCount,
  required int billingCycleMonths,
  bool autoRenew = false,
  bool includeVideoAddon = false,
  String? promoCode,
});
```

RPC params:

```dart
params: {
  'device_count': deviceCount,
  'billing_cycle_months': billingCycleMonths,
  'p_auto_renew': autoRenew,
  'p_include_video_addon': includeVideoAddon,
  'p_promo_code': promoCode,
}
```

---

### Task 5: Update Supabase checkout RPC pricing logic

**Objective:** Server calculates volume discount + promo discount atomically.

**Files:**
- Modify: `docs/db/iptv_subscription_rpc.sql`
- Possibly create versioned migration: `docs/db/iptv_subscription_pricing_rpc.sql`

**RPC signature target:**

```sql
create or replace function public.checkout_iptv_subscription(
  device_count integer,
  billing_cycle_months integer default 1,
  p_auto_renew boolean default false,
  p_include_video_addon boolean default false,
  p_promo_code text default null
)
```

**Logic:**
1. Validate user authenticated.
2. Validate device count and billing cycle.
3. Load product `costik-iptv`.
4. Load best volume tier:
   - `where min_quantity <= device_count and is_active = true`
   - `order by min_quantity desc limit 1`
5. Calculate base subtotal.
6. Calculate volume discount amount.
7. If promo code provided:
   - Normalize upper trim.
   - Validate active/date/product.
   - Validate max redemptions.
   - Validate per-user redemption.
   - If `new_customer_only`, check user has no paid/active previous subscription for product.
8. Calculate final total.
9. Check wallet balance against final total.
10. Deduct final total.
11. Insert subscription with final `total_amount`.
12. Insert transaction and invoice.
13. Insert promo redemption if used.

**Optional metadata:** Store pricing breakdown in `subscriptions.media_limits` or a new `metadata`/`pricing_breakdown` field if schema supports it. If no existing field, keep it in invoice/transaction description first to avoid broad schema changes.

---

### Task 6: Update upgrade-device RPC pricing policy

**Objective:** Adding devices later should have clear rule.

**Recommended rule:** Upgrade additional devices uses current volume tier based on **new total device count**, prorated by remaining subscription period if existing RPC already prorates.

**Files:**
- Modify: `docs/db/iptv_subscription_upgrade_device_rpc.sql`
- Test if SQL validation exists.

**Example:**
- User has 8 devices, adds 2 devices, new total 10.
- Additional 2 devices should use 10-device tier price (Rp 45.000/device/month), not Rp 50.000.

Open decision:
- Should promo code apply to upgrades? Recommended: **No**, promo only first checkout.

---

### Task 7: Admin/marketing display for discount tiers

**Objective:** Make pricing easy to understand for customers.

**Files likely:**
- `lib/features/subscription/view/iptv_subscription_page.dart`
- Possibly product detail page if pricing card shown there.

**UI copy:**

```text
Harga mulai Rp 50.000 / device / bulan
Diskon otomatis:
10+ device hemat 10%
50+ device hemat 20%
100+ device hemat 30%
Promo launching untuk customer baru: WELCOME20
```

**Validation:**
- Customer can understand discount before checkout.
- Total changes instantly when device count changes.
- Promo invalid shows friendly message.

---

## Suggested Launch Offer

### Public default offer

- `WELCOME20`
- 20% off first Costik IPTV subscription
- New customer only
- 1x redemption per user
- Active for first 30–60 days after launch

### Limited urgency offer

- `LAUNCH30`
- 30% off first subscription
- New customer only
- Limit e.g. first 20 customers or first 14 days
- Use in direct sales / early access, not always displayed forever

### Avoid at launch

- Do not combine multiple promo codes.
- Do not give lifetime discount yet.
- Do not hardcode launch discount only in Flutter; customer can manipulate UI if server does not enforce.

---

## Files Likely to Change

- `docs/db/iptv_pricing_discounts.sql` — new pricing/promo tables and seeds.
- `docs/db/iptv_subscription_rpc.sql` — checkout server calculation.
- `docs/db/iptv_subscription_upgrade_device_rpc.sql` — device upgrade pricing.
- `lib/core/billing/device_pricing.dart` — shared UI calculator.
- `lib/core/billing/billing_repository.dart` — promo code API param.
- `lib/core/billing/supabase_billing_repository.dart` — pass promo param to RPC.
- `lib/features/billing/cubit/billing_cubit.dart` — promo param flow.
- `lib/features/subscription/view/iptv_subscription_page.dart` — UI estimate + promo field.
- Tests under `test/` for pricing calculator, subscription UI, Cubit/repository.

---

## Tests / Validation

Run after implementation:

```bash
/opt/data/tools/flutter/bin/dart format lib test
/opt/data/tools/flutter/bin/flutter analyze
/opt/data/tools/flutter/bin/flutter test
```

Specific expected checks:
- 1 device no discount.
- 10/50/100 device volume discounts correct.
- Launch promo applies after volume discount.
- Promo code sent to repository/RPC.
- RPC SQL includes server-side validation; UI is not source of truth.
- Existing billing tests still pass.

---

## Risks & Tradeoffs

- **Risk:** If UI and RPC formulas differ, customer sees one total but wallet deducts another. Mitigation: keep Dart calculator and SQL formula aligned with tests and clear constants.
- **Risk:** Promo abuse if only checked client-side. Mitigation: enforce redemption and new-customer rule in DB.
- **Risk:** Too many tiers confuse customers. Mitigation: keep only 4 tiers: 1, 10, 50, 100.
- **Risk:** 30% promo + 30% volume discount makes deep discount for 100+ devices. Mitigation: set max promo for large deals manually or cap launch discount amount if needed.

---

## Open Questions Before Implementation

1. Diskon volume final mau pakai rekomendasi ini?
   - 10 device = 10%
   - 50 device = 20%
   - 100 device = 30%
2. Promo launching mau default public `WELCOME20` atau langsung `LAUNCH30`?
3. Promo berlaku untuk 1 bulan pertama saja, atau semua durasi checkout pertama? Rekomendasi: berlaku pada checkout pertama sesuai durasi yang dibeli.
4. Upgrade tambah device boleh pakai promo? Rekomendasi: tidak.
5. Apakah diskon volume berlaku untuk Digital Signage juga nanti, atau khusus IPTV dulu? Rekomendasi: khusus IPTV dulu, struktur tabel sudah bisa reusable.
