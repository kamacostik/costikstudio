import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signage device schema and payload expose running text', () {
    final schema = File('docs/db/signage_schema.sql').readAsStringSync();
    final migration = File('docs/db/signage_device_running_text.sql')
        .readAsStringSync();
    final payload = File('docs/db/signage_client_payload_rpc.sql')
        .readAsStringSync();

    expect(schema, contains('running_text_enabled boolean'));
    expect(schema, contains('running_text text'));
    expect(
      migration,
      contains('add column if not exists running_text_enabled'),
    );
    expect(migration, contains('add column if not exists running_text'));
    expect(
      payload,
      contains("'running_text_enabled', v_device.running_text_enabled"),
    );
    expect(payload, contains("'running_text', v_device.running_text"));
  });

  test('web admin device settings can update running text per device', () {
    final model = File(
      'lib/features/signage/data/signage_admin_repository.dart',
    ).readAsStringSync();
    final cubit = File('lib/features/signage/cubit/signage_admin_cubit.dart')
        .readAsStringSync();
    final ui = File('lib/features/signage/view/signage_devices_section.dart')
        .readAsStringSync();

    expect(model, contains('runningTextEnabled'));
    expect(model, contains('runningText'));
    expect(model, contains('updateDeviceRunningText'));
    expect(cubit, contains('updateDeviceRunningText'));
    expect(ui, contains('Text Berjalan'));
    expect(ui, contains('runningTextController'));
  });
}
