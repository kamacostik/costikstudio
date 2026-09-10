class TopUpOrderResult {
  const TopUpOrderResult({
    required this.orderId,
    required this.externalReference,
    required this.status,
    required this.amount,
    this.paymentUrl,
    this.paymentCode,
    this.paymentCodeType,
    this.paymentChannelUsed,
    this.paymentErrorMessage,
    this.paymentLinkRequested = false,
  });

  final String orderId;
  final String externalReference;
  final String status;
  final int amount;
  final String? paymentUrl;
  final String? paymentCode;
  final String? paymentCodeType;
  final String? paymentChannelUsed;
  final String? paymentErrorMessage;
  final bool paymentLinkRequested;

  bool get hasPaymentError =>
      paymentErrorMessage != null && paymentErrorMessage!.isNotEmpty;

  TopUpOrderResult copyWith({
    String? paymentUrl,
    String? paymentCode,
    String? paymentCodeType,
    String? paymentChannelUsed,
    String? paymentErrorMessage,
    bool? paymentLinkRequested,
  }) {
    return TopUpOrderResult(
      orderId: orderId,
      externalReference: externalReference,
      status: status,
      amount: amount,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      paymentCode: paymentCode ?? this.paymentCode,
      paymentCodeType: paymentCodeType ?? this.paymentCodeType,
      paymentChannelUsed: paymentChannelUsed ?? this.paymentChannelUsed,
      paymentErrorMessage: paymentErrorMessage ?? this.paymentErrorMessage,
      paymentLinkRequested: paymentLinkRequested ?? this.paymentLinkRequested,
    );
  }
}
