import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats integer amount as Indonesian rupiah text', () {
    expect(formatRupiah(0), 'Rp 0');
    expect(formatRupiah(50000), 'Rp 50.000');
    expect(formatRupiah(1250000), 'Rp 1.250.000');
  });
}
