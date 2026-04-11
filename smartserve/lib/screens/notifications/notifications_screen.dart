import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_notification_model.dart';
import '../../services/app_notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final service = AppNotificationService();

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login to view notifications.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => service.markAllAsRead(user.uid),
            child: const Text(
              'Mark all',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: service.getUserNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _NotificationLoadError(
              errorMessage: snapshot.error.toString(),
            );
          }

          final notifications = snapshot.data ?? const <AppNotification>[];
          if (notifications.isEmpty) {
            return const _EmptyNotifications();
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, separatorIndex) => Divider(color: Colors.grey[200], height: 0),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                tileColor: notification.isRead ? Colors.white : const Color(0xFFFFF3F3),
                leading: CircleAvatar(
                  backgroundColor: _typeColor(notification.type).withOpacity(0.15),
                  child: Icon(
                    _typeIcon(notification.type),
                    color: _typeColor(notification.type),
                  ),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notification.body),
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(notification.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  if (!notification.isRead) {
                    await service.markAsRead(notification.id);
                  }

                  final orderId = notification.metadata['orderId'];
                  if (orderId is String && orderId.isNotEmpty && context.mounted) {
                    Navigator.pushNamed(
                      context,
                      '/order-tracking',
                      arguments: orderId,
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
      case 'order_status':
        return Icons.receipt_long;
      case 'promo':
        return Icons.local_offer;
      case 'inventory':
        return Icons.inventory;
      default:
        return Icons.notifications;
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
      case 'order_status':
        return const Color(0xFFFF6B6B);
      case 'promo':
        return Colors.green;
      case 'inventory':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDateTime(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y  $hh:$mm';
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Order updates, promos, and system alerts will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationLoadError extends StatelessWidget {
  final String errorMessage;

  const _NotificationLoadError({required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 72, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Unable to load notifications',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again in a moment. If the issue continues, check your Firestore indexes.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
