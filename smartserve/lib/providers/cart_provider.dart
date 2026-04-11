import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/menu_item_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  // Getters
  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + item.total);
  }

  int get totalQuantity {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Add item to cart
  void addItem(
    MenuItem menuItem, {
    Map<String, String>? customizations,
  }) {
    // Check if item already exists in cart
    final existingIndex = _items.indexWhere((item) => item.itemId == menuItem.itemId);

    if (existingIndex >= 0) {
      // Increase quantity if customizations are the same
      final existingItem = _items[existingIndex];
      if (customizations == existingItem.customizations || customizations == null) {
        _items[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + 1,
        );
      } else {
        // Add as new item with different customizations
        _items.add(
          CartItem(
            itemId: menuItem.itemId,
            name: menuItem.name,
            price: menuItem.price,
            imageUrl: menuItem.imageUrl,
            quantity: 1,
            customizations: customizations ?? {},
          ),
        );
      }
    } else {
      // Add new item
      _items.add(
        CartItem(
          itemId: menuItem.itemId,
          name: menuItem.name,
          price: menuItem.price,
          imageUrl: menuItem.imageUrl,
          quantity: 1,
          customizations: customizations ?? {},
        ),
      );
    }

    notifyListeners();
  }

  // Update quantity
  void updateQuantity(String itemId, int quantity) {
    final index = _items.indexWhere((item) => item.itemId == itemId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: quantity);
      }
      notifyListeners();
    }
  }

  // Update customizations
  void updateCustomizations(String itemId, Map<String, String> customizations) {
    final index = _items.indexWhere((item) => item.itemId == itemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(customizations: customizations);
      notifyListeners();
    }
  }

  // Remove item from cart
  void removeItem(String itemId) {
    _items.removeWhere((item) => item.itemId == itemId);
    notifyListeners();
  }

  // Clear entire cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Get specific item
  CartItem? getItem(String itemId) {
    try {
      return _items.firstWhere((item) => item.itemId == itemId);
    } catch (e) {
      return null;
    }
  }

  // Check if item is in cart
  bool hasItem(String itemId) {
    return _items.any((item) => item.itemId == itemId);
  }

  // Get total quantity for specific item
  int getItemQuantity(String itemId) {
    final item = getItem(itemId);
    return item?.quantity ?? 0;
  }
}
