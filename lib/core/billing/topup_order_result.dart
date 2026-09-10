class TopUpOrderResult {
  const TopUpOrderResult({
    required this.orderId,
    required this.externalReference,
    required this.status,
    required this.amount,
    this.paymentUrl,
    this.paymentLinkRequested = false,
  });

  final String orderId;
  final String externalReference;
  final String status;
  final int amount;
  final String? paymentUrl;
  final bool paymentLinkRequested;

  TopUpOrderResult copyWith({String? paymentUrl, bool? paymentLinkRequested}) {
    return TopUpOrderResult(
      orderId: orderId,
      externalReference: externalReference,
      status: status,
      amount: amount,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      paymentLinkRequested: paymentLinkRequested ?? this.paymentLinkRequested,
    );
  }
}
