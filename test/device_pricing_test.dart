import 'package:costikstudio/core/billing/device_pricing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IPTV volume pricing', () {
    test('1 device uses base price without discount', () {
      final breakdown = calculateIptvDevicePrice(deviceCount: 1);

      expect(breakdown.baseSubtotal, 50000);
      expect(breakdown.volumeDiscountPercent, 0);
      expect(breakdown.effectivePricePerDevice, 50000);
      expect(breakdown.finalTotal, 50000);
    });

    test('10 devices receive 10 percent volume discount', () {
      final breakdown = calculateIptvDevicePrice(deviceCount: 10);

      expect(breakdown.volumeDiscountPercent, 10);
      expect(breakdown.effectivePricePerDevice, 45000);
      expect(breakdown.finalTotal, 450000);
    });

    test('50 devices receive 30 percent volume discount', () {
      final breakdown = calculateIptvDevicePrice(deviceCount: 50);

      expect(breakdown.volumeDiscountPercent, 30);
      expect(breakdown.effectivePricePerDevice, 35000);
      expect(breakdown.finalTotal, 1750000);
    });

    test(
      '100 devices receive 60 percent volume discount for 20k unit price',
      () {
        final breakdown = calculateIptvDevicePrice(deviceCount: 100);

        expect(breakdown.volumeDiscountPercent, 60);
        expect(breakdown.effectivePricePerDevice, 20000);
        expect(breakdown.finalTotal, 2000000);
      },
    );

    test('voucher discount applies after volume discount', () {
      final breakdown = calculateIptvDevicePrice(
        deviceCount: 100,
        voucherDiscountPercent: 20,
      );

      expect(breakdown.volumeDiscountAmount, 3000000);
      expect(breakdown.voucherDiscountAmount, 400000);
      expect(breakdown.finalTotal, 1600000);
    });
  });
}
