import '../../main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartserve/screens/staff/add_menu_item_screen.dart';
import '../../models/menu_item_model.dart';
import '../../services/menu_service.dart';
import '../auth/login_screen.dart'; // Member 1's login screen
import 'add_menu_item_screen.dart';
import 'staff_order_dashboard.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({Key? key}) : super(key: key);

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> with SingleTickerProviderStateMixin {
  final MenuService _menuService = MenuService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Staff Dashboard',
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
            Tab(icon: Icon(Icons.assignment), text: 'Orders'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              
              // FIX: Push back to the root AuthGate and clear all previous routes
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AuthGate()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      
      // Floating Action Button to Add New Items (We will build this next!)
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                // Navigates to your new form!
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddMenuItemScreen()),
                );
              },
              backgroundColor: const Color(0xFFFF6B6B),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Add Item', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            )
          : null,

      body: TabBarView(
        controller: _tabController,
        children: [
          // Menu Management Tab
          _buildMenuManagementTab(),
          // Order Management Tab
          const StaffOrderDashboard(),
        ],
      ),
    );
  }

  Widget _buildMenuManagementTab() {
    return StreamBuilder<List<MenuItem>>(
      stream: _menuService.getMenuItems(), // Fetching ALL items
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No menu items yet.', style: GoogleFonts.inter()));
        }

        final items = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80, top: 16), // Padding for the FAB
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildStaffItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildStaffItemCard(MenuItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 60,
            height: 60,
            child: ColorFiltered(
              colorFilter: item.isAvailable 
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        title: Text(
          item.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          '₹${item.price.toStringAsFixed(2)} • ${item.category}',
          style: GoogleFonts.inter(color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Availability Toggle
            Switch(
              value: item.isAvailable,
              activeColor: Colors.green,
              onChanged: (bool newValue) {
                _menuService.toggleAvailability(item.itemId, item.isAvailable);
              },
            ),
            // NEW: Edit Button!
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddMenuItemScreen(itemToEdit: item)),
                );
              },
            ),
            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context, item),
            ),
          ],
        ),
      ),
    );
  }

  // Safety confirmation before deleting
  Future<void> _confirmDelete(BuildContext context, MenuItem item) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${item.name}?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _menuService.deleteMenuItem(item.itemId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}