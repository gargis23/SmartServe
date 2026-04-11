import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import your Menu screen
import '../menu/menu_home_screen.dart';
// Import Member 1's Profile screen (Adjust the path if needed based on your structure)
import '../profile/profile_screen.dart';
// Import the Cart screen
import '../cart/cart_screen.dart'; 
import '../notifications/notifications_screen.dart';
import '../../services/app_notification_service.dart';

class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({Key? key}) : super(key: key);

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _currentIndex = 0;
  final AppNotificationService _notificationService = AppNotificationService();

  // The list of screens for the bottom navigation
  final List<Widget> _screens = [
    const MenuHomeScreen(), // Index 0: Your Menu!
    const CartScreen(), // Index 1: Cart (Member 3 Task)
    const NotificationsScreen(), // Index 2: Member 4 Notifications
    const ProfileScreen(), // Index 3: Member 1's Profile
  ];

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFF6B6B).withOpacity(0.2), // Warm brand color
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu, color: Color(0xFFFF6B6B)),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart, color: Color(0xFFFF6B6B)),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: _buildNotificationIcon(userId, false),
            selectedIcon: _buildNotificationIcon(userId, true),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFFF6B6B)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(String? userId, bool selected) {
    final baseIcon = Icon(
      selected ? Icons.notifications : Icons.notifications_none,
      color: selected ? const Color(0xFFFF6B6B) : null,
    );

    if (userId == null) {
      return baseIcon;
    }

    return StreamBuilder<int>(
      stream: _notificationService.getUnreadCount(userId),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        if (unread <= 0) {
          return baseIcon;
        }

        return Badge(
          label: Text(unread > 99 ? '99+' : unread.toString()),
          child: baseIcon,
        );
      },
    );
  }
}