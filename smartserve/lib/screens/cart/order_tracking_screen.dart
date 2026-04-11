import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? orderId;

  const OrderTrackingScreen({super.key, this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late final OrderService _orderService;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
    _orderId = widget.orderId;

    // If orderId not passed, try to get from arguments
    if (_orderId == null) {
      Future.microtask(() {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is String) {
          setState(() {
            _orderId = args;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
      ),
      body: _orderId == null
          ? _buildNoOrderState(context)
          : StreamBuilder<FoodOrder?>(
              stream: _orderService.streamOrder(_orderId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return _buildNoOrderState(context);
                }

                final order = snapshot.data!;
                return _buildOrderTrackingContent(context, order);
              },
            ),
    );
  }

  Widget _buildNoOrderState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Order Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Your orders will appear here',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTrackingContent(BuildContext context, FoodOrder order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderStatus(context, order),
          const SizedBox(height: 24),
          if (order.status == FoodOrderStatus.completed)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Order Completed!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your order has been completed and picked up. Thank you for ordering!',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (order.status == FoodOrderStatus.cancelled)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cancel, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Order Cancelled',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your order has been cancelled.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                _buildTimelineSteps(context, order),
                const SizedBox(height: 24),
              ],
            ),
          _buildOrderDetails(context, order),
          const SizedBox(height: 24),
          _buildOrderItems(context, order),
          const SizedBox(height: 16),
          if (order.status != FoodOrderStatus.completed &&
              order.status != FoodOrderStatus.cancelled)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                ),
                onPressed: () => _cancelOrder(order.orderId),
                child: const Text('Cancel Order'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus(BuildContext context, FoodOrder order) {
    final statusColors = {
      FoodOrderStatus.pending: Colors.orange,
      FoodOrderStatus.confirmed: Colors.blue,
      FoodOrderStatus.preparing: Colors.purple,
      FoodOrderStatus.ready: Colors.green,
      FoodOrderStatus.completed: Colors.green,
      FoodOrderStatus.cancelled: Colors.red,
    };

    final statusTexts = {
      FoodOrderStatus.pending: 'Pending Confirmation',
      FoodOrderStatus.confirmed: 'Order Confirmed',
      FoodOrderStatus.preparing: 'Preparing Your Order',
      FoodOrderStatus.ready: 'Ready for Delivery',
      FoodOrderStatus.completed: 'Completed',
      FoodOrderStatus.cancelled: 'Cancelled',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderId.substring(0, 8).toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} ${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColors[order.status],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusTexts[order.status] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Total',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6B6B),
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Est. Prep Time',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.estimatedPrepTime.toStringAsFixed(0)} mins',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSteps(BuildContext context, FoodOrder order) {
    final steps = [
      ('Pending', FoodOrderStatus.pending),
      ('Confirmed', FoodOrderStatus.confirmed),
      ('Preparing', FoodOrderStatus.preparing),
      ('Ready', FoodOrderStatus.ready),
      ('Completed', FoodOrderStatus.completed),
    ];

    final currentIndex = steps.indexWhere((step) => step.$2 == order.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Progress',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          steps.length,
          (index) {
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  // Circle indicator
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFFFF6B6B)
                          : Colors.grey[300],
                    ),
                    child: Center(
                      child: isCurrent
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              isCompleted ? Icons.check : Icons.pending,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Step text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[index].$1,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Vertical line
                  if (index < steps.length - 1)
                    Positioned(
                      left: 20,
                      top: 40,
                      child: Container(
                        width: 2,
                        height: 30,
                        color: isCompleted ? const Color(0xFFFF6B6B) : Colors.grey[300],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOrderDetails(BuildContext context, FoodOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Payment Method', _formatPaymentMethod(order.paymentMethod)),
            _buildDetailRow('Payment Status', _formatPaymentStatus(order.paymentStatus)),
            _buildDetailRow(
              'Scheduled for',
              '${order.scheduledTime.day}/${order.scheduledTime.month}/${order.scheduledTime.year} ${order.scheduledTime.hour}:${order.scheduledTime.minute.toString().padLeft(2, '0')}',
            ),
            if (order.notes != null && order.notes!.isNotEmpty)
              _buildDetailRow('Special Notes', order.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context, FoodOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.name} x${item.quantity}'),
                          if (item.customizations.isNotEmpty)
                            Text(
                              item.customizations.values.join(', '),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                        ],
                      ),
                    ),
                    Text('₹${item.total.toStringAsFixed(2)}'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'upi':
        return 'UPI / Phone Pay';
      case 'cod':
        return 'Cash on Delivery';
      case 'wallet':
        return 'SmartServe Wallet';
      case 'card':
        return 'Debit/Credit Card';
      default:
        return method;
    }
  }

  String _formatPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return '✓ Completed';
      case 'pending':
        return '⏳ Pending';
      case 'failed':
        return '✗ Failed';
      default:
        return status;
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _orderService.cancelOrder(orderId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }
}
