import '../models/cart_item_model.dart';

enum FoodOrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  completed,
  cancelled,
}

class FoodOrder {
  final String orderId;
  final String userId;
  final String userName;
  final List<CartItem> items;
  final double totalAmount;
  final FoodOrderStatus status;
  final DateTime createdAt;
  final DateTime scheduledTime; // For advance booking
  final String? notes; // Special instructions
  final String paymentMethod;
  final String paymentStatus; // pending, completed, failed
  final double estimatedPrepTime; // in minutes
  final String? staffAssignedId;

  FoodOrder({
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.items,
    required this.totalAmount,
    this.status = FoodOrderStatus.pending,
    required this.createdAt,
    required this.scheduledTime,
    this.notes,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    required this.estimatedPrepTime,
    this.staffAssignedId,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'userName': userName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'scheduledTime': scheduledTime.toIso8601String(),
      'notes': notes ?? '',
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'estimatedPrepTime': estimatedPrepTime,
      'staffAssignedId': staffAssignedId ?? '',
    };
  }

  factory FoodOrder.fromMap(Map<String, dynamic> map, String docId) {
    return FoodOrder(
      orderId: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      items: (map['items'] as List?)
              ?.map((item) => CartItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      status: _parseOrderStatus(map['status'] ?? 'pending'),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      scheduledTime:
          DateTime.tryParse(map['scheduledTime'] ?? '') ?? DateTime.now(),
      notes: map['notes'],
      paymentMethod: map['paymentMethod'] ?? 'cod',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      estimatedPrepTime: (map['estimatedPrepTime'] ?? 15).toDouble(),
      staffAssignedId: map['staffAssignedId'],
    );
  }

  static FoodOrderStatus _parseOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return FoodOrderStatus.confirmed;
      case 'preparing':
        return FoodOrderStatus.preparing;
      case 'ready':
        return FoodOrderStatus.ready;
      case 'completed':
        return FoodOrderStatus.completed;
      case 'cancelled':
        return FoodOrderStatus.cancelled;
      case 'pending':
      default:
        return FoodOrderStatus.pending;
    }
  }
}
