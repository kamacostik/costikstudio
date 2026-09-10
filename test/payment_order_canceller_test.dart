import 'package:costikstudio/core/payment/payment_order_canceller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does nothing when external reference is empty', () async {
    final cancelled = await const PaymentOrderCanceller()
        .cancelByExternalReference('');

    expect(cancelled, isFalse);
  });
}
