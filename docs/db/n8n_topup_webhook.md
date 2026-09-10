# n8n Top-Up Webhook Guide

Use n8n as the trusted payment gateway webhook handler. Flutter only creates a pending `payment_orders` row; n8n applies wallet balance after the gateway confirms payment success.

## Current Flow

1. Flutter user clicks Top Up.
2. Flutter calls Supabase RPC `create_topup_order(amount, provider)`.
3. Supabase creates `payment_orders.status = 'pending'` and returns `external_reference`.
4. Payment gateway processes payment using that `external_reference` as merchant/order reference.
5. Payment gateway sends webhook to n8n.
6. n8n verifies gateway signature and paid status.
7. n8n calls Supabase RPC `apply_paid_topup_order(...)`.
8. Supabase updates wallet, transaction, invoice, and marks order `paid`.

## Required n8n Secrets

Store these in n8n credentials or environment variables, not in workflow nodes as plain text:

- Supabase Project URL
- Supabase Service Role Key
- Payment Gateway Webhook Secret / Signature Key

Never expose the Supabase service role key in Flutter, browser code, GitHub, or public logs.

## n8n Workflow Nodes

### 1. Webhook Trigger

Method: `POST`

Path example:

```text
/payment/topup-webhook
```

The final URL from n8n becomes the webhook URL configured in the payment gateway dashboard.

### 2. Verify Signature

Before touching Supabase:

- verify the webhook signature/hash/token from the payment gateway
- reject invalid signature with non-200 response
- confirm payment status is success/paid/settlement
- ignore pending/failed/expired/cancelled callbacks

Provider-specific names differ, but the payload must give you:

- payment status
- order/reference id
- provider transaction/order id
- paid amount
- raw payload

### 3. Extract Reference

Map payment gateway payload into:

```text
external_reference = payload.order_id or payload.external_id or payload.merchant_ref
provider_order_id = payload.transaction_id or payload.payment_id
raw_payload = full webhook JSON body
```

The `external_reference` must match `payment_orders.external_reference`.

### 4. Call Supabase RPC

Use n8n HTTP Request node.

Method:

```text
POST
```

URL:

```text
https://YOUR_PROJECT_REF.supabase.co/rest/v1/rpc/apply_paid_topup_order
```

Headers:

```text
apikey: YOUR_SUPABASE_SERVICE_ROLE_KEY
Authorization: Bearer YOUR_SUPABASE_SERVICE_ROLE_KEY
Content-Type: application/json
```

Body JSON:

```json
{
  "target_external_reference": "{{$json.external_reference}}",
  "provider_order_id": "{{$json.provider_order_id}}",
  "raw_payload": {{$json.raw_payload}}
}
```

Use your actual n8n expression paths based on your gateway payload.

## Success Response

RPC returns:

```json
[
  {
    "transaction_id": "uuid",
    "new_balance": 100000
  }
]
```

Then n8n can return HTTP `200 OK` to the payment gateway.

## Idempotency

Payment gateways may send the same webhook multiple times.

`apply_paid_topup_order` already guards against duplicate balance updates:

- if order is still `pending`, it applies balance once
- if order is already `paid`, it returns current balance without adding saldo again
- if order status is not pending/paid, it raises an error

## Verification Query

After a test webhook, verify in Supabase SQL Editor:

```sql
select
  po.external_reference,
  po.status,
  po.amount,
  po.paid_at,
  wt.id as transaction_id,
  inv.invoice_number,
  w.balance
from public.payment_orders po
left join public.wallet_transactions wt
  on wt.user_id = po.user_id
  and wt.amount = po.amount
left join public.invoices inv
  on inv.transaction_id = wt.id
left join public.wallets w
  on w.user_id = po.user_id
where po.external_reference = 'PASTE_EXTERNAL_REFERENCE_HERE'
order by wt.created_at desc
limit 1;
```

Expected after success:

- `payment_orders.status = paid`
- `wallets.balance` increased
- one `wallet_transactions` row with `type = topup`
- one `invoices` row with `status = paid`

## Important Production Rules

- n8n must verify webhook signature before calling Supabase.
- n8n must use service role key only server-side.
- Flutter must only use anon/publishable key.
- Do not grant `apply_paid_topup_order` to authenticated users.
- Do not update wallet balance directly from Flutter.
