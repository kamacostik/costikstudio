import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signage device schema and payload expose event theme', () {
    final schema = File('docs/db/signage_schema.sql').readAsStringSync();
    final migration = File('docs/db/signage_device_event_theme.sql')
        .readAsStringSync();
    final payload = File('docs/db/signage_client_payload_rpc.sql')
        .readAsStringSync();

    expect(schema, contains('event_theme text'));
    expect(schema, contains("check (event_theme in"));
    expect(migration, contains('add column if not exists event_theme'));
    expect(payload, contains("'event_theme', v_device.event_theme"));
  });

  test('web admin device settings can update event theme per device', () {
    final model = File(
      'lib/features/signage/data/signage_admin_repository.dart',
    ).readAsStringSync();
    final cubit = File('lib/features/signage/cubit/signage_admin_cubit.dart')
        .readAsStringSync();
    final ui = File('lib/features/signage/view/signage_devices_section.dart')
        .readAsStringSync();

    expect(model, contains('enum SignageEventTheme'));
    expect(model, contains('eventTheme'));
    expect(model, contains("'event_theme': eventTheme.value"));
    expect(cubit, contains('updateDeviceEventTheme'));
    expect(ui, contains('Tema Event Schedule'));
    expect(ui, contains('DropdownButtonFormField<SignageEventTheme>'));
  });
}
