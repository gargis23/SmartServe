import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import 'dart:math';

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a transaction record
  Future<String> createTransaction({
    required String orderId,
    required String userId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final transaction = PaymentTransaction(
        transactionId: '', // Will be set by Firestore
        orderId: orderId,
        userId: userId,
        amount: amount,
        paymentMethod: paymentMethod,
        status: paymentMethod == 'cod' ? PaymentTransactionStatus.completed : PaymentTransactionStatus.pending,
        createdAt: DateTime.now(),
      );

      final docRef = await _db.collection('transactions').add(transaction.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating transaction: $e');
      rethrow;
    }
  }

  // Get user's transaction history
  Stream<List<PaymentTransaction>> getUserTransactions(String userId) {
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentTransaction.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get transaction details
  Future<PaymentTransaction?> getTransaction(String transactionId) async {
    try {
      final doc = await _db.collection('transactions').doc(transactionId).get();
      if (doc.exists) {
        return PaymentTransaction.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching transaction: $e');
      return null;
    }
  }

  // Update transaction with Razorpay details
  Future<void> updateTransactionWithRazorpay({
    required String transactionId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      await _db.collection('transactions').doc(transactionId).update({
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
        'status': 'completed',
      });
    } catch (e) {
      print('Error updating transaction: $e');
      rethrow;
    }
  }

  // Mark transaction as failed
  Future<void> markTransactionFailed(
    String transactionId,
    String failureReason,
  ) async {
    try {
      await _db.collection('transactions').doc(transactionId).update({
        'status': 'failed',
        'failureReason': failureReason,
      });
    } catch (e) {
      print('Error marking transaction as failed: $e');
      rethrow;
    }
  }

  // Generate receipt (stores receipt URL/data)
  Future<void> generateReceipt(String transactionId, String receiptUrl) async {
    try {
      await _db.collection('transactions').doc(transactionId).update({
        'receiptUrl': receiptUrl,
      });
    } catch (e) {
      print('Error generating receipt: $e');
      rethrow;
    }
  }

  // Get wallet balance for a user
  Future<double> getWalletBalance(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return (doc['walletBalance'] ?? 0.0).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('Error fetching wallet balance: $e');
      return 0.0;
    }
  }

  // Add amount to wallet
  Future<void> addToWallet(String userId, double amount) async {
    try {
      await _db.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(amount),
      });
    } catch (e) {
      print('Error adding to wallet: $e');
      rethrow;
    }
  }

  // Deduct from wallet
  Future<void> deductFromWallet(String userId, double amount) async {
    try {
      final currentBalance = await getWalletBalance(userId);
      if (currentBalance >= amount) {
        await _db.collection('users').doc(userId).update({
          'walletBalance': FieldValue.increment(-amount),
        });
      } else {
        throw Exception('Insufficient wallet balance');
      }
    } catch (e) {
      print('Error deducting from wallet: $e');
      rethrow;
    }
  }

  // Generate Razorpay order ID (test implementation)
  Future<String> generateRazorpayOrderId(double amount) async {
    try {
      // In production, this would call Razorpay API
      // For now, returning a test order ID
      return 'order_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
    } catch (e) {
      print('Error generating Razorpay order: $e');
      rethrow;
    }
  }

  // Mock payment gateway integration (test mode)
  Future<bool> processPayment({
    required String orderId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // In test mode, randomly succeed or fail (80% success rate)
      final random = Random();
      final success = random.nextInt(100) < 80;

      return success;
    } catch (e) {
      print('Error processing payment: $e');
      return false;
    }
  }
}
