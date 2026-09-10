import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loginAsCustomer(WidgetTester tester) async {
  await _login(tester, 'user@costik.com');
}

Future<void> loginAsAdmin(WidgetTester tester) async {
  await _login(tester, 'admin@costik.com');
}

Future<void> _login(WidgetTester tester, String email) async {
  await tester.tap(find.byKey(const Key('header_login_button')));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    '123456',
  );
  await tester.ensureVisible(
    find.widgetWithText(FilledButton, 'Masuk ke Dashboard'),
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Masuk ke Dashboard'));
  await tester.pumpAndSettle();
}
