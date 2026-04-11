import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/menu_item_model.dart';
import '../../services/menu_service.dart';
import '../../services/recommendation_service.dart';
import '../../widgets/menu_item_card.dart';
import 'menu_detail_screen.dart';

class MenuHomeScreen extends StatefulWidget {
  const MenuHomeScreen({Key? key}) : super(key: key);

  @override
  State<MenuHomeScreen> createState() => _MenuHomeScreenState();
}

class _MenuHomeScreenState extends State<MenuHomeScreen> {
  final MenuService _menuService = MenuService();
  final RecommendationService _recommendationService = RecommendationService();
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Meals', 'Snacks', 'Beverages', 'Desserts'];
  
  // Search & Filter State
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  bool _vegOnly = false;
  double _maxPrice = 500.0; // High default so it shows everything initially
  List<MenuItem> _recommendedItems = [];
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      final items = await _recommendationService.getPersonalizedRecommendations(
        userId: user.uid,
        limit: 6,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _recommendedItems = items;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _recommendedItems = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  // Opens the Advanced Filter Bottom Sheet
  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          // NEW: Clear Button only shows if filters are active
                          if (_vegOnly || _maxPrice < 500)
                            TextButton(
                              onPressed: () {
                                setModalState(() { _vegOnly = false; _maxPrice = 500.0; });
                                setState(() { _vegOnly = false; _maxPrice = 500.0; });
                                Navigator.pop(context); // Close sheet after clearing
                              },
                              child: Text('Clear', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Veg Only Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(16)),
                    child: SwitchListTile(
                      title: Text('Veg Only', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.green[800])),
                      value: _vegOnly,
                      activeColor: Colors.green,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setModalState(() => _vegOnly = val);
                        setState(() => _vegOnly = val); // Updates the main screen too
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Price Slider
                  Text('Max Price: ₹${_maxPrice.toInt()}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFFFF6B6B),
                      thumbColor: const Color(0xFFFF6B6B),
                      overlayColor: const Color(0xFFFF6B6B).withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _maxPrice,
                      min: 0,
                      max: 500,
                      divisions: 10,
                      label: '₹${_maxPrice.toInt()}',
                      onChanged: (val) {
                        setModalState(() => _maxPrice = val);
                        setState(() => _maxPrice = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Apply Filters', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          // The Search Bar
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search for food...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // NEW: The Filter Button
          GestureDetector(
            onTap: _openFilterSheet,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFFFF6B6B).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.tune, color: Colors.white),
                  // Small indicator dot if filters are active
                  if (_vegOnly || _maxPrice < 500)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.restaurant, color: Color(0xFFFF6B6B), size: 28),
            const SizedBox(width: 8),
            Text(
              'SmartServe',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFF6B6B), // Brand Color
                fontWeight: FontWeight.w900,   // Extra Bold
                fontSize: 26,
                letterSpacing: -0.5,           // Tighter tracking for logo feel
              ),
            ),
          ],
        ),
        // title: Text('SmartServe', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What are you\ncraving today?', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2)),
                const SizedBox(height: 24),
                _buildRecommendationSection(),
                const SizedBox(height: 20),
                _buildSearchBar(),
                _buildCategoryList(),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<MenuItem>>(
              stream: _menuService.getMenuItemsByCategory(selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmerLoading();
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('No items found.', style: GoogleFonts.inter()));

                var items = snapshot.data!;

                // 1. Apply Search Filter
                if (searchQuery.isNotEmpty) {
                  items = items.where((item) => item.name.toLowerCase().contains(searchQuery)).toList();
                }

                // 2. Apply Veg Only Filter
                if (_vegOnly) {
                  items = items.where((item) => !item.tags.contains('Non-Veg')).toList();
                }

                // 3. Apply Price Filter
                items = items.where((item) => item.price <= _maxPrice).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No matching food found.', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

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
                                Navigator.push(context, MaterialPageRoute(builder: (context) => MenuDetailScreen(item: items[index])));
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

  Widget _buildRecommendationSection() {
    if (_isLoadingRecommendations) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recommendedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber[700]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Add a few orders and your personalized recommendations will appear here.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'For You',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            TextButton.icon(
              onPressed: _loadRecommendations,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendedItems.length,
            separatorBuilder: (_, separatorIndex) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = _recommendedItems[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MenuDetailScreen(item: item)),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) {
                              return Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(color: Colors.white),
                              );
                            },
                            errorWidget: (context, url, error) {
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.fastfood,
                                  size: 36,
                                  color: Colors.grey[700],
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.08),
                                  Colors.black.withValues(alpha: 0.65),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Rs ${item.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
            onTap: () => setState(() => selectedCategory = categories[index]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6B6B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFFF6B6B).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] : [],
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: GoogleFonts.inter(color: isSelected ? Colors.white : Colors.black54, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
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