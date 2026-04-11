class CartItem {
  final String itemId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  final Map<String, String> customizations; // {spiceLevel, addOns, etc}

  CartItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    this.customizations = const {},
  });

  // Calculate total for this cart item
  double get total => price * quantity;

  // Create a copy with modifications
  CartItem copyWith({
    String? itemId,
    String? name,
    double? price,
    String? imageUrl,
    int? quantity,
    Map<String, String>? customizations,
  }) {
    return CartItem(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      customizations: customizations ?? this.customizations,
    );
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'customizations': customizations,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      itemId: map['itemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity'] ?? 1,
      customizations: Map<String, String>.from(map['customizations'] ?? {}),
    );
  }
}
