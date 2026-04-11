import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  String _selectedPaymentMethod = 'cod';
  String _specialNotes = '';
  bool _isProcessing = false;

  final orderService = OrderService();
  final paymentService = PaymentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSummary(context, cartProvider),
                  const SizedBox(height: 24),
                  _buildScheduleSection(context),
                  const SizedBox(height: 24),
                  _buildPaymentMethodSection(context),
                  const SizedBox(height: 24),
                  _buildNotesSection(context),
                  const SizedBox(height: 24),
                  _buildOrderButton(context, cartProvider),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, CartProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...provider.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.name} x ${item.quantity}'),
                    ),
                    Text('₹${item.total.toStringAsFixed(2)}'),
                  ],
                ),
              );
            }),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('₹${provider.totalPrice.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery'),
                Text('Free'),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '₹${provider.totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF6B6B),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Time',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 7)),
            );
            if (picked != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_selectedDate),
              );
              if (time != null) {
                setState(() {
                  _selectedDate = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            }
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Schedule for'),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} - ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.edit_calendar),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...[
          ('cod', 'Cash on Delivery', Icons.money),
          ('upi', 'UPI / Phone Pay', Icons.phone_android),
          ('wallet', 'SmartServe Wallet', Icons.account_balance_wallet),
          ('card', 'Debit/Credit Card', Icons.credit_card),
        ].map((option) {
          return RadioListTile<String>(
            title: Row(
              children: [
                Icon(option.$3 as IconData),
                const SizedBox(width: 12),
                Text(option.$2 as String),
              ],
            ),
            value: option.$1 as String,
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Special Instructions (Optional)',
        hintText: 'E.g., Extra spicy, no onions, etc.',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.note_add),
      ),
      maxLines: 3,
      onChanged: (value) {
        setState(() {
          _specialNotes = value;
        });
      },
    );
  }

  Widget _buildOrderButton(BuildContext context, CartProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : () => _placeOrder(context, provider),
        child: _isProcessing
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Place Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, CartProvider provider) async {
    if (provider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Process payment based on selected method
      if (_selectedPaymentMethod != 'cod') {
        final paymentSuccess = await paymentService.processPayment(
          orderId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          amount: provider.totalPrice,
          paymentMethod: _selectedPaymentMethod,
        );

        if (!paymentSuccess) {
          throw Exception('Payment failed. Please try again.');
        }
      }

      // Create order
      final orderId = await orderService.createOrder(
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'User',
        items: provider.items,
        totalAmount: provider.totalPrice,
        scheduledTime: _selectedDate,
        paymentMethod: _selectedPaymentMethod,
        notes: _specialNotes,
      );

      // Create transaction record
      await paymentService.createTransaction(
        orderId: orderId,
        userId: user.uid,
        amount: provider.totalPrice,
        paymentMethod: _selectedPaymentMethod,
      );

      // Clear cart
      provider.clearCart();

      // Navigate to order tracking
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/order-tracking',
          arguments: orderId,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
