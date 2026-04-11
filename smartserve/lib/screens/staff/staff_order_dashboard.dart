import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class StaffOrderDashboard extends StatefulWidget {
  const StaffOrderDashboard({super.key});

  @override
  State<StaffOrderDashboard> createState() => _StaffOrderDashboardState();
}

class _StaffOrderDashboardState extends State<StaffOrderDashboard> {
  late final OrderService _orderService;
  String _selectedFilter = 'all'; // all, pending, confirming, preparing, ready

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: StreamBuilder<List<FoodOrder>>(
                stream: _orderService.getPendingOrders(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  return Badge(
                    label: Text(count.toString()),
                    child: const Icon(Icons.notification_important),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      ('all', 'All'),
      ('pending', 'New'),
      ('confirming', 'Confirming'),
      ('preparing', 'Preparing'),
      ('ready', 'Ready'),
    ];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter.$1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(filter.$2),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter.$1;
                  });
                },
                selectedColor: const Color(0xFFFF6B6B),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return StreamBuilder<List<FoodOrder>>(
      stream: _orderService.getPendingOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        var orders = snapshot.data!;

        // Apply filters
        if (_selectedFilter != 'all') {
          orders = orders.where((order) {
            switch (_selectedFilter) {
              case 'pending':
                return order.status == FoodOrderStatus.pending;
              case 'confirming':
                return order.status == FoodOrderStatus.confirmed;
              case 'preparing':
                return order.status == FoodOrderStatus.preparing;
              case 'ready':
                return order.status == FoodOrderStatus.ready;
              default:
                return true;
            }
          }).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(context, orders[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Orders',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'All caught up! No pending orders at the moment.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, FoodOrder order) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                      order.userName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.2),
                    border: Border.all(color: _getStatusColor(order.status)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatOrderStatus(order.status),
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 12),
            // Items count and total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.items.length} items',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Est. ${order.estimatedPrepTime.toStringAsFixed(0)} mins',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6B6B),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPaymentStatus(order.paymentStatus),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Items preview
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: order.items.take(2).map((item) {
                  return Text(
                    '${item.quantity}x ${item.name}',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }).toList(),
              ),
            ),
            if (order.items.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${order.items.length - 2} more items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note_add, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.notes!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Action buttons
            _buildActionButtons(context, order),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, FoodOrder order) {
    return Row(
      children: [
        if (order.status == FoodOrderStatus.pending)
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
              ),
              onPressed: () => _rejectOrder(order.orderId),
              child: const Text('Reject', style: TextStyle(color: Colors.white)),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          flex: order.status == FoodOrderStatus.pending ? 2 : 1,
          child: ElevatedButton(
            onPressed: () => _moveOrderForward(context, order),
            child: Text(_getNextActionText(order.status)),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.remove_red_eye),
          onPressed: () => _viewOrderDetails(context, order),
        ),
      ],
    );
  }

  String _getNextActionText(FoodOrderStatus status) {
    switch (status) {
      case FoodOrderStatus.pending:
        return 'Confirm';
      case FoodOrderStatus.confirmed:
        return 'Start Prep';
      case FoodOrderStatus.preparing:
        return 'Ready';
      case FoodOrderStatus.ready:
        return 'Complete';
      default:
        return 'Update';
    }
  }

  Future<void> _moveOrderForward(BuildContext context, FoodOrder order) async {
    try {
      // If order is ready, ask for confirmation before completing
      if (order.status == FoodOrderStatus.ready) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Order Completion'),
            content: const Text('Has the customer picked up their order?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not Yet'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, Picked Up'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
      }

      final nextStatus = _getNextOrderStatus(order.status);
      await _orderService.updateOrderStatus(order.orderId, nextStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order moved to ${_formatOrderStatus(nextStatus)}')),
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

  Future<void> _rejectOrder(String orderId) async {
    try {
      await _orderService.updateOrderStatus(orderId, FoodOrderStatus.cancelled);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order rejected')),
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

  void _viewOrderDetails(BuildContext context, FoodOrder order) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildOrderDetailsSheet(context, order),
    );
  }

  Widget _buildOrderDetailsSheet(BuildContext context, FoodOrder order) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Order #${order.orderId.substring(0, 8).toUpperCase()}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDetailSection('Customer', [
              'Name: ${order.userName}',
              'ID: ${order.userId}',
            ]),
            const SizedBox(height: 16),
            _buildDetailSection('Items', [
              ...order.items.map((item) =>
                  '${item.quantity}x ${item.name} (₹${item.total.toStringAsFixed(2)})'),
            ]),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailSection('Special Notes', [order.notes!]),
            ],
            const SizedBox(height: 16),
            _buildDetailSection('Order Info', [
              'Total: ₹${order.totalAmount.toStringAsFixed(2)}',
              'Payment: ${_formatPaymentMethod(order.paymentMethod)}',
              'Estimated Prep: ${order.estimatedPrepTime.toStringAsFixed(0)} mins',
            ]),
          ],
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(item),
          );
        }),
      ],
    );
  }

  FoodOrderStatus _getNextOrderStatus(FoodOrderStatus current) {
    switch (current) {
      case FoodOrderStatus.pending:
        return FoodOrderStatus.confirmed;
      case FoodOrderStatus.confirmed:
        return FoodOrderStatus.preparing;
      case FoodOrderStatus.preparing:
        return FoodOrderStatus.ready;
      case FoodOrderStatus.ready:
        return FoodOrderStatus.completed;
      default:
        return current;
    }
  }

  Color _getStatusColor(FoodOrderStatus status) {
    switch (status) {
      case FoodOrderStatus.pending:
        return Colors.orange;
      case FoodOrderStatus.confirmed:
        return Colors.blue;
      case FoodOrderStatus.preparing:
        return Colors.purple;
      case FoodOrderStatus.ready:
        return Colors.green;
      case FoodOrderStatus.completed:
        return Colors.teal;
      case FoodOrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatOrderStatus(FoodOrderStatus status) {
    switch (status) {
      case FoodOrderStatus.pending:
        return 'Pending';
      case FoodOrderStatus.confirmed:
        return 'Confirmed';
      case FoodOrderStatus.preparing:
        return 'Preparing';
      case FoodOrderStatus.ready:
        return 'Ready';
      case FoodOrderStatus.completed:
        return 'Completed';
      case FoodOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return '✓ Paid';
      case 'pending':
        return '⏳ Pending';
      case 'failed':
        return '✗ Failed';
      default:
        return status;
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'upi':
        return 'UPI';
      case 'cod':
        return 'Cash on Delivery';
      case 'wallet':
        return 'Wallet';
      case 'card':
        return 'Card';
      default:
        return method;
    }
  }
}
