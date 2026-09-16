class DeviceDiscountTier {
  const DeviceDiscountTier({
    required this.minQuantity,
    required this.discountPercent,
    required this.label,
  });

  final int minQuantity;
  final int discountPercent;
  final String label;
}

class DevicePriceBreakdown {
  const DevicePriceBreakdown({
    required this.baseSubtotal,
    required this.volumeDiscountAmount,
    required this.voucherDiscountAmount,
    required this.finalTotal,
    required this.effectivePricePerDevice,
    required this.volumeDiscountPercent,
    required this.voucherDiscountPercent,
    required this.tierLabel,
  });

  final int baseSubtotal;
  final int volumeDiscountAmount;
  final int voucherDiscountAmount;
  final int finalTotal;
  final int effectivePricePerDevice;
  final int volumeDiscountPercent;
  final int voucherDiscountPercent;
  final String tierLabel;
}

const int iptvBasePricePerDevice = 50000;

const iptvVolumeDiscountTiers = <DeviceDiscountTier>[
  DeviceDiscountTier(minQuantity: 1, discountPercent: 0, label: '1–9 device'),
  DeviceDiscountTier(minQuantity: 10, discountPercent: 10, label: '10+ device'),
  DeviceDiscountTier(minQuantity: 50, discountPercent: 30, label: '50+ device'),
  DeviceDiscountTier(
    minQuantity: 100,
    discountPercent: 60,
    label: '100+ device',
  ),
];

DevicePriceBreakdown calculateIptvDevicePrice({
  required int deviceCount,
  int billingCycleMonths = 1,
  int voucherDiscountPercent = 0,
  int basePricePerDevice = iptvBasePricePerDevice,
  List<DeviceDiscountTier> tiers = iptvVolumeDiscountTiers,
}) {
  final safeDeviceCount = deviceCount < 0 ? 0 : deviceCount;
  final safeBillingCycleMonths = billingCycleMonths < 0
      ? 0
      : billingCycleMonths;
  final safeVoucherDiscountPercent = voucherDiscountPercent.clamp(0, 100);
  final tier = _tierForQuantity(safeDeviceCount, tiers);
  final baseSubtotal =
      safeDeviceCount * basePricePerDevice * safeBillingCycleMonths;
  final volumeDiscountAmount = (baseSubtotal * tier.discountPercent / 100)
      .round();
  final subtotalAfterVolume = baseSubtotal - volumeDiscountAmount;
  final voucherDiscountAmount =
      (subtotalAfterVolume * safeVoucherDiscountPercent / 100).round();
  final finalTotal = subtotalAfterVolume - voucherDiscountAmount;
  final effectivePricePerDevice =
      safeDeviceCount == 0 || safeBillingCycleMonths == 0
      ? 0
      : (subtotalAfterVolume / safeDeviceCount / safeBillingCycleMonths)
            .round();

  return DevicePriceBreakdown(
    baseSubtotal: baseSubtotal,
    volumeDiscountAmount: volumeDiscountAmount,
    voucherDiscountAmount: voucherDiscountAmount,
    finalTotal: finalTotal,
    effectivePricePerDevice: effectivePricePerDevice,
    volumeDiscountPercent: tier.discountPercent,
    voucherDiscountPercent: safeVoucherDiscountPercent,
    tierLabel: tier.label,
  );
}

DeviceDiscountTier _tierForQuantity(
  int deviceCount,
  List<DeviceDiscountTier> tiers,
) {
  var selected = tiers.first;
  for (final tier in tiers) {
    if (deviceCount >= tier.minQuantity &&
        tier.minQuantity >= selected.minQuantity) {
      selected = tier;
    }
  }
  return selected;
}
