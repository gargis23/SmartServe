import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/menu_item_model.dart';
import '../../services/menu_service.dart';
import '../../widgets/menu_item_card.dart';
import 'menu_detail_screen.dart'; // Uncomment when you create the detail screen

class MenuHomeScreen extends StatefulWidget {
  const MenuHomeScreen({Key? key}) : super(key: key);

  @override
  State<MenuHomeScreen> createState() => _MenuHomeScreenState();
}

class _MenuHomeScreenState extends State<MenuHomeScreen> {
  final MenuService _menuService = MenuService();
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Meals', 'Snacks', 'Beverages', 'Desserts'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Off-white clean background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SmartServe',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              // TODO: Implement Search (Member 2 Sprint 2 task)
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Categories
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What are you\ncraving today?',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                _buildCategoryList(),
              ],
            ),
          ),
          
          // Menu Items List
          Expanded(
            child: StreamBuilder<List<MenuItem>>(
              stream: _menuService.getMenuItemsByCategory(selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('No items found.', style: GoogleFonts.inter()),
                  );
                }

                final items = snapshot.data!;
                return AnimationLimiter(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: MenuItemCard(
                              item: items[index],
                              onTap: () {
                                // Navigate to Detail Screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MenuDetailScreen(item: items[index]),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Category horizontal scroller
  Widget _buildCategoryList() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = selectedCategory == categories[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = categories[index];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6B6B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xFFFF6B6B).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Beautiful Shimmer effect while loading
  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          height: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Row(
              children: [
                Container(width: 130, height: 130, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 16, width: double.infinity, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 12, width: 100, color: Colors.white),
                        const Spacer(),
                        Container(height: 20, width: 60, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}