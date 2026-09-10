# n8n Sumopod QRIS Top-Up Workflow

This workflow keeps the Sumopod API key outside Flutter.

## Prerequisites

- Supabase Service Role key stored in n8n credentials/env, never in Flutter.
- Sumopod sandbox API key stored in n8n credentials/env.
- SQL already executed:
  - `schema_iptv.sql`
  - `topup_payment_gateway.sql`
  - `sumopod_topup_flow.sql`

## Workflow A — Create Sumopod Payment URL

Use this after Flutter creates a pending payment order via `create_sumopod_topup_order`.

### Option 1: Manual/cron polling pending orders

1. Add a Schedule Trigger or Manual Trigger.
2. Add HTTP Request node: Supabase REST select pending Sumopod orders.

```http
GET https://YOUR_PROJECT_REF.supabase.co/rest/v1/payment_orders?provider=eq.sumopod&status=eq.pending&payment_url=is.null&select=id,external_reference,amount,currency,payment_method_type_code
apikey: SUPABASE_SERVICE_ROLE_KEY
Authorization: Bearer SUPABASE_SERVICE_ROLE_KEY
```

3. Add Split In Batches node.
4. Add HTTP Request node: create Sumopod payment.

```http
POST https://api-pay-sandbox.sumopod.com/api/v1/payments
Content-Type: application/json
X-Api-Key: SUMOPOD_API_KEY
```

Body:

```json
{
  "order_id": "{{$json.external_reference}}",
  "amount": {{$json.amount}},
  "currency": "{{$json.currency || 'IDR'}}",
  "expires_in_hours": 24,
  "success_return_url": "https://yourdomain.com/billing",
  "cancel_return_url": "https://yourdomain.com/billing",
  "payment_method_type_code": "{{$json.payment_method_type_code || 'QRIS'}}"
}
```

5. Add HTTP Request node: call Supabase RPC `attach_sumopod_payment_url`.

```http
POST https://YOUR_PROJECT_REF.supabase.co/rest/v1/rpc/attach_sumopod_payment_url
Content-Type: application/json
apikey: SUPABASE_SERVICE_ROLE_KEY
Authorization: Bearer SUPABASE_SERVICE_ROLE_KEY
```

Body mapping depends on Sumopod response field names. Use the actual payment id/url returned by Sumopod:

```json
{
  "target_external_reference": "{{$node['Split In Batches'].json.external_reference}}",
  "target_gateway_payment_id": "{{$json.id || $json.payment_id || $json.data.id}}",
  "target_payment_url": "{{$json.payment_url || $json.checkout_url || $json.data.payment_url || $json.data.checkout_url}}",
  "raw_payload": {{$json}}
}
```

## Workflow B — Sumopod Paid Webhook

1. Add Webhook node. Method: POST.
2. Configure the Sumopod dashboard webhook URL to the n8n production webhook URL.
3. Validate webhook signature if Sumopod provides a signature header.
4. Extract:
   - order reference: `order_id` / `external_reference`
   - payment id: `payment_id` / `id`
   - payment status: `paid` / `success` / `settlement`

5. If status is paid/success, call Supabase RPC `apply_paid_topup_order`.

```http
POST https://YOUR_PROJECT_REF.supabase.co/rest/v1/rpc/apply_paid_topup_order
Content-Type: application/json
apikey: SUPABASE_SERVICE_ROLE_KEY
Authorization: Bearer SUPABASE_SERVICE_ROLE_KEY
```

Body:

```json
{
  "target_external_reference": "{{$json.order_id || $json.external_reference || $json.data.order_id}}",
  "provider_order_id": "{{$json.payment_id || $json.id || $json.data.payment_id || $json.data.id}}",
  "raw_payload": {{$json}}
}
```

## Flutter test steps

1. User logs in.
2. User opens Billing.
3. User creates top-up order.
4. Run Workflow A once.
5. Refresh Billing.
6. Pending order should show **Bayar Sekarang**.
7. Open Sumopod payment link and simulate paid payment.
8. Run/receive Workflow B webhook.
9. Refresh Billing.
10. Wallet balance increases, top-up invoice appears paid.

## Important notes

- Do not expose Sumopod `X-Api-Key` in Flutter.
- Use service role only inside n8n/server-side.
- Keep `apply_paid_topup_order` unavailable to authenticated client users.
- For production, replace sandbox URL with Sumopod production API URL.
- Confirm Sumopod response field names before final mapping.
