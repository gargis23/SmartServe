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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image with Hero animation tag
            Hero(
              tag: 'food_image_${item.itemId}',
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
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
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.fastfood, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
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
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${item.price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6B6B), // Primary brand color
                          ),
                        ),
                        // Add Button or Out of Stock Tag
                        item.isAvailable
                            ? Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 20),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Out',
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                                ),
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