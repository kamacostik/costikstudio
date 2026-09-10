# Sumopod Webhook Event Mapping

Use the n8n production webhook URL in Sumopod Settings:

```text
https://n8n.sbkn.my.id/webhook/costikstudio-sumopod-paid
```

## Supported Sumopod events

- `payment.completed` → apply wallet top-up.
- `payment.failed` → do not apply wallet top-up.
- `payment.expired` → do not apply wallet top-up.
- `payment.test` → connectivity test only; do not apply wallet top-up.

## Confirmed completed payload shape

```json
{
  "event_type": "payment.completed",
  "data": {
    "payment_id": "uuid",
    "order_id": "INV-2026-001",
    "amount": 50000,
    "fee": 750,
    "net_amount": 49250,
    "status": "completed",
    "payment_method": "qris",
    "completed_at": "2026-06-18T12:00:00Z"
  }
}
```

n8n Webhook node wraps that under `$json.body`, so the paid workflow reads:

- Event type: `$json.body.event_type`
- Order reference: `$json.body.data.order_id`
- Gateway payment id: `$json.body.data.payment_id`
- Status: `$json.body.data.status`

## RPC body for `apply_paid_topup_order`

Use JSON body in n8n HTTP Request:

```json
{
  "target_external_reference": "{{$json.body.data.order_id}}",
  "provider_order_id": "{{$json.body.data.payment_id}}",
  "raw_payload": {
    "event_type": "{{$json.body.event_type}}",
    "payment_id": "{{$json.body.data.payment_id}}",
    "order_id": "{{$json.body.data.order_id}}",
    "amount": {{$json.body.data.amount}},
    "fee": {{$json.body.data.fee}},
    "net_amount": {{$json.body.data.net_amount}},
    "status": "{{$json.body.data.status}}",
    "payment_method": "{{$json.body.data.payment_method}}",
    "completed_at": "{{$json.body.data.completed_at}}"
  }
}
```

## Verification

After a completed webhook, check:

```sql
select external_reference, status, paid_at, gateway_payment_id
from payment_orders
order by created_at desc
limit 5;

select type, direction, amount, description, created_at
from wallet_transactions
order by created_at desc
limit 5;

select invoice_number, type, status, total, created_at
from invoices
order by created_at desc
limit 5;
```

Expected result:

- `payment_orders.status = paid`
- `paid_at` is filled
- wallet credit transaction exists
- paid top-up invoice exists

## Security note

For staging, filtering on `event_type = payment.completed` is enough to verify the flow. For production, use the token-protected import file:

```text
docs/db/n8n_sumopod_paid_webhook_with_token.json
```

Set this n8n environment variable before activating the workflow:

```text
SUMOPOD_WEBHOOK_TOKEN=whtok_...
```

The token-protected workflow checks:

```js
$json.headers['x-webhook-token'] === $env.SUMOPOD_WEBHOOK_TOKEN
```

Invalid tokens return HTTP 401 and do not apply wallet credit.
