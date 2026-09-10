import 'package:costikstudio/features/payment_return/view/payment_return_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders payment success return page', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PaymentReturnPage.success()),
    );

    expect(find.text('Pembayaran Diproses'), findsOneWidget);
    expect(find.text('Kembali ke Billing Dashboard'), findsOneWidget);
  });

  testWidgets('renders payment cancelled return page', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PaymentReturnPage.cancelled()),
    );

    expect(find.text('Pembayaran Dibatalkan'), findsOneWidget);
    expect(find.text('Kembali ke Billing Dashboard'), findsOneWidget);
  });
}
