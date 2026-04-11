enum PaymentTransactionStatus {
  pending,
  completed,
  failed,
  refunded,
}

class PaymentTransaction {
  final String transactionId;
  final String orderId;
  final String userId;
  final double amount;
  final String paymentMethod; // upi, wallet, cod, card
  final PaymentTransactionStatus status;
  final DateTime createdAt;
  final String? razorpayOrderId; // For Razorpay integration
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  final String? failureReason;
  final String? receiptUrl; // Generated receipt

  PaymentTransaction({
    required this.transactionId,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    this.status = PaymentTransactionStatus.pending,
    required this.createdAt,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
    this.failureReason,
    this.receiptUrl,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'razorpayOrderId': razorpayOrderId ?? '',
      'razorpayPaymentId': razorpayPaymentId ?? '',
      'razorpaySignature': razorpaySignature ?? '',
      'failureReason': failureReason ?? '',
      'receiptUrl': receiptUrl ?? '',
    };
  }

  factory PaymentTransaction.fromMap(Map<String, dynamic> map, String docId) {
    return PaymentTransaction(
      transactionId: docId,
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'cod',
      status: _parseTransactionStatus(map['status'] ?? 'pending'),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      razorpayOrderId: map['razorpayOrderId'],
      razorpayPaymentId: map['razorpayPaymentId'],
      razorpaySignature: map['razorpaySignature'],
      failureReason: map['failureReason'],
      receiptUrl: map['receiptUrl'],
    );
  }

  static PaymentTransactionStatus _parseTransactionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return PaymentTransactionStatus.completed;
      case 'failed':
        return PaymentTransactionStatus.failed;
      case 'refunded':
        return PaymentTransactionStatus.refunded;
      case 'pending':
      default:
        return PaymentTransactionStatus.pending;
    }
  }
}
