import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/menu_item_model.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const MenuItemCard({Key? key, required this.item, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Logic to determine if it's a bestseller
    bool isBestseller = item.rating >= 4.5;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            // Image Stack (Allows us to overlap the badge)
            Stack(
              children: [
                Hero(
                  tag: 'food_image_${item.itemId}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
                    child: SizedBox(
                      width: 130,
                      height: 130,
                      child: ColorFiltered(
                        colorFilter: item.isAvailable 
                            ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                            : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                        child: CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[100]),
                          errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.fastfood, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // NEW: The Dynamic Bestseller Badge
                if (isBestseller)
                  Positioned(
                    top: 12,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF9A44), Color(0xFFFC6076)]), // Warm fiery gradient
                        borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                        boxShadow: [BoxShadow(color: const Color(0xFFFC6076).withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text('Bestseller', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Text Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${item.price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFFF6B6B)),
                        ),
                        item.isAvailable
                            ? Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                                child: const Icon(Icons.add, color: Colors.white, size: 20),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                                child: Text('Out', style: GoogleFonts.inter(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}