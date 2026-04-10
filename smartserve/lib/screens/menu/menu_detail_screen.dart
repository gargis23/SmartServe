import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/menu_item_model.dart';

class MenuDetailScreen extends StatefulWidget {
  final MenuItem item;

  const MenuDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  double _spiceLevel = 1;
  int _quantity = 1;
  bool _isDescriptionExpanded = false; // Controls the Read More state

  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.item.price * _quantity;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Image Header
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFFF8F9FA),
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: 'food_image_${widget.item.itemId}',
                child: CachedNetworkImage(
                  imageUrl: widget.item.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // Content Area
          SliverToBoxAdapter(
            child: Container(
              // FIX: Increased negative transform to pull the card higher over the image
              transform: Matrix4.translationValues(0.0, -40.0, 0.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              // FIX: Reduced top padding from 32 to 20 to tighten the gap
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 100),
                child: AnimationLimiter(
                  // ANIMATION: This automatically staggers all children in the list!
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 600),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 40.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        // Title and Tags
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.item.name,
                                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2, color: Colors.black87),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.item.tags.contains('Non-Veg') ? Colors.red[50] : Colors.green[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: widget.item.tags.contains('Non-Veg') ? Colors.red : Colors.green),
                              ),
                              child: Text(
                                widget.item.tags.contains('Non-Veg') ? 'Non-Veg' : 'Veg',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: widget.item.tags.contains('Non-Veg') ? Colors.red : Colors.green),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Info Row
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildInfoStat(Icons.local_fire_department, '${widget.item.calories} kcal'),
                              Container(width: 1, height: 30, color: Colors.grey[300]),
                              _buildInfoStat(Icons.access_time_filled, '${widget.item.preparationTime} min'),
                              Container(width: 1, height: 30, color: Colors.grey[300]),
                              _buildInfoStat(Icons.star, '4.8'), // Hardcoded for now, can map to Firebase rating later
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Animated About Section
                        Text('About', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        AnimatedCrossFade(
                          firstChild: Text(
                            widget.item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 15, color: Colors.grey[600], height: 1.6),
                          ),
                          secondChild: Text(
                            widget.item.description,
                            style: GoogleFonts.inter(fontSize: 15, color: Colors.grey[600], height: 1.6),
                          ),
                          crossFadeState: _isDescriptionExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _isDescriptionExpanded ? "Read Less" : "Read More",
                              style: GoogleFonts.poppins(color: const Color(0xFFFF6B6B), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Ingredients
                        Text('Ingredients', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: widget.item.ingredients.map((ing) => Chip(
                            label: Text(ing, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[300]!)),
                          )).toList(),
                        ),
                        const SizedBox(height: 32),

                        // Customization
                        Text('Spice Level', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: const Color(0xFFFF6B6B),
                            inactiveTrackColor: Colors.red[100],
                            thumbColor: const Color(0xFFFF6B6B),
                            overlayColor: const Color(0xFFFF6B6B).withOpacity(0.2),
                            trackHeight: 6,
                          ),
                          child: Slider(
                            value: _spiceLevel,
                            min: 0,
                            max: 2,
                            divisions: 2,
                            onChanged: (val) => setState(() => _spiceLevel = val),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Mild', style: GoogleFonts.inter(color: _spiceLevel == 0 ? Colors.black87 : Colors.grey, fontWeight: _spiceLevel == 0 ? FontWeight.bold : FontWeight.normal)),
                              Text('Medium', style: GoogleFonts.inter(color: _spiceLevel == 1 ? Colors.black87 : Colors.grey, fontWeight: _spiceLevel == 1 ? FontWeight.bold : FontWeight.normal)),
                              Text('Hot', style: GoogleFonts.inter(color: _spiceLevel == 2 ? const Color(0xFFFF6B6B) : Colors.grey, fontWeight: _spiceLevel == 2 ? FontWeight.bold : FontWeight.normal)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      
      // Floating Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 16, bottom: 32, left: 24, right: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))],
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.black87),
                    onPressed: () { if (_quantity > 1) setState(() => _quantity--); },
                  ),
                  // Animated Quantity
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Text('$_quantity', key: ValueKey<int>(_quantity), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.black87),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.item.isAvailable ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.item.isAvailable ? const Color(0xFFFF6B6B) : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                // Animated Total Price
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Text(
                    widget.item.isAvailable ? 'Add | ₹${totalPrice.toStringAsFixed(2)}' : 'Unavailable',
                    key: ValueKey<double>(totalPrice),
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStat(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF6B6B), size: 24),
        const SizedBox(height: 4),
        Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
      ],
    );
  }
}