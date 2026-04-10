import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Real-time stream of all menu items
  Stream<List<MenuItem>> getMenuItems() {
    return _db.collection('menu_items').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => MenuItem.fromFirestore(doc.data(), doc.id)).toList());
  }

  // Stream filtered by category
  Stream<List<MenuItem>> getMenuItemsByCategory(String category) {
    if (category == 'All') return getMenuItems();
    
    return _db
        .collection('menu_items')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MenuItem.fromFirestore(doc.data(), doc.id)).toList());
  }

  // --- NEW STAFF METHODS ---

  // Toggle availability instantly
  Future<void> toggleAvailability(String itemId, bool currentStatus) async {
    try {
      await _db.collection('menu_items').doc(itemId).update({
        'isAvailable': !currentStatus, // Flips true to false, or false to true
      });
    } catch (e) {
      print("Error toggling availability: $e");
    }
  }

  // Delete an item permanently
  Future<void> deleteMenuItem(String itemId) async {
    try {
      await _db.collection('menu_items').doc(itemId).delete();
    } catch (e) {
      print("Error deleting item: $e");
    }
  }

  // Add a brand new item to the database
  Future<void> addMenuItem(Map<String, dynamic> itemData) async {
    try {
      await _db.collection('menu_items').add(itemData);
    } catch (e) {
      print("Error adding item: $e");
      rethrow; // Pass the error to the UI so we can show a snackbar
    }
  }
}
