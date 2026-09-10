class TopUpOrderResult {
  const TopUpOrderResult({
    required this.orderId,
    required this.externalReference,
    required this.status,
    required this.amount,
    this.paymentUrl,
  });

  final String orderId;
  final String externalReference;
  final String status;
  final int amount;
  final String? paymentUrl;
}
