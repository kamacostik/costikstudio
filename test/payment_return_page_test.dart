import 'package:costikstudio/features/payment_return/view/payment_return_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders payment success return page with auto check copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PaymentReturnPage.success()),
    );
    await tester.pump();

    expect(find.text('Pembayaran Diproses'), findsOneWidget);
    expect(find.text('Pembayaran Diproses'), findsOneWidget);
    expect(find.text('Kembali ke Billing Dashboard'), findsOneWidget);
    expect(
      find.text('Otomatis kembali ke Billing dalam beberapa detik.'),
      findsOneWidget,
    );
  });

  testWidgets('renders payment cancelled return page with auto redirect copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PaymentReturnPage.cancelled()),
    );
    await tester.pump();

    expect(find.text('Pembayaran Dibatalkan'), findsOneWidget);
    expect(find.text('Kembali ke Billing sebentar lagi.'), findsOneWidget);
    expect(find.text('Kembali ke Billing Dashboard'), findsOneWidget);
  });
}
