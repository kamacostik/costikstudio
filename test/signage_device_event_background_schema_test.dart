import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signage device schema exposes per-device event background url', () {
    final schemaSql = File('docs/db/signage_schema.sql').readAsStringSync();
    final payloadSql = File('docs/db/signage_client_payload_rpc.sql')
        .readAsStringSync();

    expect(schemaSql, contains('event_background_url text'));
    expect(
      payloadSql,
      contains("'event_background_url', v_device.event_background_url"),
    );
  });
}
