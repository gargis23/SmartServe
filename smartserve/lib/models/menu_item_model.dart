class MenuItem {
  final String itemId;
  final String name;
  final String description;
  final String category;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final int preparationTime;
  final List<String> tags;
  // NEW FIELDS added for the Detail Screen:
  final List<String> ingredients;
  final String calories;
  final double rating;

  MenuItem({
    required this.itemId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    required this.preparationTime,
    required this.tags,
    required this.ingredients,
    required this.calories,
    required this.rating,
  });

  factory MenuItem.fromFirestore(Map<String, dynamic> data, String id) {
    return MenuItem(
      itemId: id,
      name: data['name'] ?? 'Unknown Item',
      // Provide a long fallback description for testing the Read More feature
      description: data['description'] ?? 'Crispy patty with spicy mayo and fresh lettuce. Prepared with our signature blend of herbs and spices, it offers a delightful crunch on the outside and a soft center. Served on a toasted brioche bun.',
      category: data['category'] ?? 'General',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/150',
      isAvailable: data['isAvailable'] ?? false,
      preparationTime: data['preparationTime'] ?? 15,
      tags: List<String>.from(data['tags'] ?? []),
      ingredients: List<String>.from(data['ingredients'] ?? ['Paneer', 'Lettuce', 'Mayo', 'Bun']),
      // Now fetching from Firebase, with fallbacks
      calories: data['calories']?.toString() ?? '450',
      rating: (data['rating'] ?? 4.0).toDouble(),
    );
  }
}