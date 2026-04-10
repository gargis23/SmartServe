import 'package:flutter/material.dart';
// Import your Menu screen
import '../menu/menu_home_screen.dart';
// Import Member 1's Profile screen (Adjust the path if needed based on your structure)
import '../profile/profile_screen.dart'; 

class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({Key? key}) : super(key: key);

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _currentIndex = 0;

  // The list of screens for the bottom navigation
  final List<Widget> _screens = [
    const MenuHomeScreen(), // Index 0: Your Menu!
    const Center(child: Text('Cart (Member 3 Task)')), // Index 1: Placeholder for Cart
    const ProfileScreen(), // Index 2: Member 1's Profile
  ];

  @override
  Widget build(BuildContext context) {
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
        destinations: const [
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
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFFF6B6B)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}