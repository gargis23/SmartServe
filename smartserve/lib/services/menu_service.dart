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
}