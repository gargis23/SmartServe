import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new order
  Future<String> createOrder({
    required String userId,
    required String userName,
    required List<CartItem> items,
    required double totalAmount,
    required DateTime scheduledTime,
    required String paymentMethod,
    required String notes,
  }) async {
    try {
      // Calculate estimated preparation time based on items
      double maxPrepTime = 0;
      for (var item in items) {
        // You can expand this logic to include item-specific prep times
        maxPrepTime = maxPrepTime + 5; // 5 minutes per item as baseline
      }

      final order = FoodOrder(
        orderId: '', // Will be set by Firestore
        userId: userId,
        userName: userName,
        items: items,
        totalAmount: totalAmount,
        status: FoodOrderStatus.pending,
        createdAt: DateTime.now(),
        scheduledTime: scheduledTime,
        notes: notes.isEmpty ? null : notes,
        paymentMethod: paymentMethod,
        paymentStatus: paymentMethod == 'cod' ? 'pending' : 'pending',
        estimatedPrepTime: maxPrepTime,
      );

      final docRef = await _db.collection('orders').add(order.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  // Get orders for a specific user
  Stream<List<FoodOrder>> getUserOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FoodOrder.fromMap(doc.data(), doc.id)).toList());
  }

  // Get single order details
  Future<FoodOrder?> getOrder(String orderId) async {
    try {
      final doc = await _db.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return FoodOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching order: $e');
      return null;
    }
  }

  // Stream for single order (real-time updates)
  Stream<FoodOrder?> streamOrder(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots().map((doc) {
      if (doc.exists) {
        return FoodOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Get all pending orders (for staff dashboard)
  Stream<List<FoodOrder>> getPendingOrders() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => FoodOrder.fromMap(doc.data(), doc.id))
              .toList();
          // Show active orders only (don't show cancelled, but DO show ready and completed for short time)
          return orders
              .where((order) => order.status != FoodOrderStatus.cancelled)
              .toList();
        });
  }

  // Get all user orders including completed ones (for student history)
  Stream<List<FoodOrder>> getUserOrderHistory(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FoodOrder.fromMap(doc.data(), doc.id)).toList());
  }

  // Update order status (for staff)
  Future<void> updateOrderStatus(String orderId, FoodOrderStatus status) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  // Assign order to staff member
  Future<void> assignOrderToStaff(String orderId, String staffId) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'staffAssignedId': staffId,
      });
    } catch (e) {
      print('Error assigning order: $e');
      rethrow;
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'paymentStatus': paymentStatus,
      });
    } catch (e) {
      print('Error updating payment status: $e');
      rethrow;
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': 'cancelled',
      });
    } catch (e) {
      print('Error cancelling order: $e');
      rethrow;
    }
  }

  // Get order history for a user (filtered by date range)
  Stream<List<FoodOrder>> getOrderHistory(String userId, {DateTime? from, DateTime? to}) {
    var query = _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed');

    if (from != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: from);
    }

    if (to != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: to);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FoodOrder.fromMap(doc.data(), doc.id)).toList());
  }
}
