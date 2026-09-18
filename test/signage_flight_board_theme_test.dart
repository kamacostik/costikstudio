import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin event theme options include flight board', () {
    final repository = File(
      'lib/features/signage/data/signage_admin_repository.dart',
    ).readAsStringSync();
    final schema = File('docs/db/signage_schema.sql').readAsStringSync();
    final migration = File('docs/db/signage_device_event_theme.sql')
        .readAsStringSync();

    expect(repository, contains("flightBoard('flight_board', 'Flight Board')"));
    expect(schema, contains("'flight_board'"));
    expect(migration, contains("'flight_board'"));
  });
}
