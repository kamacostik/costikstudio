from pathlib import Path


def test_upgrade_rpc_uses_current_schema_columns():
    sql = Path('docs/db/iptv_subscription_upgrade_device_rpc.sql').read_text()

    assert 'insert into public.wallet_transactions' in sql
    assert 'description' in sql
    assert 'status' in sql
    assert 'balance_before' not in sql
    assert 'balance_after' not in sql
    assert 'reference_id' not in sql

    assert 'insert into public.invoices' in sql
    invoice_insert = sql.split('insert into public.invoices', 1)[1].split('update public.subscriptions', 1)[0]
    assert 'subscription_id' not in invoice_insert
    assert 'paid_at' not in invoice_insert
    assert 'created_at' not in invoice_insert

    assert 'device_count = v_device_count + additional_device_count' in sql


if __name__ == '__main__':
    test_upgrade_rpc_uses_current_schema_columns()
