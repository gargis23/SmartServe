import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_item_model.dart';
import '../models/recommendation_model.dart';

class RecommendationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<MenuItem>> getPersonalizedRecommendations({
    required String userId,
    int limit = 6,
  }) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? const <String, dynamic>{};

    final menuSnapshot = await _db
        .collection('menu_items')
        .where('isAvailable', isEqualTo: true)
        .get();

    final menuItems = menuSnapshot.docs
        .map((doc) => MenuItem.fromFirestore(doc.data(), doc.id))
        .toList();

    if (menuItems.isEmpty) {
      return [];
    }

    final userOrders = await _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .get();

    final globalOrders = await _db.collection('orders').get();

    final scored = _scoreItems(
      userData: userData,
      menuItems: menuItems,
      userOrders: userOrders.docs,
      globalOrders: globalOrders.docs,
    );

    final itemById = {
      for (final item in menuItems) item.itemId: item,
    };

    return scored
        .where((rec) => itemById.containsKey(rec.itemId))
        .take(limit)
        .map((rec) => itemById[rec.itemId]!)
        .toList();
  }

  List<FoodRecommendation> _scoreItems({
    required Map<String, dynamic> userData,
    required List<MenuItem> menuItems,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> userOrders,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> globalOrders,
  }) {
    final dietaryPrefs = List<String>.from(userData['dietaryPreferences'] ?? const []);
    final allergies = List<String>.from(userData['allergies'] ?? const []);

    final userItemCount = <String, int>{};
    final userCategoryCount = <String, int>{};
    final globalItemCount = <String, int>{};

    for (final order in userOrders) {
      final data = order.data();
      if ((data['status'] ?? '').toString().toLowerCase() == 'cancelled') {
        continue;
      }
      final items = List<Map<String, dynamic>>.from(data['items'] ?? const []);
      for (final item in items) {
        final itemId = (item['itemId'] ?? '').toString();
        final qty = _safeInt(item['quantity'], fallback: 1);
        if (itemId.isNotEmpty) {
          userItemCount[itemId] = (userItemCount[itemId] ?? 0) + qty;
        }
      }
    }

    final categoryLookup = {
      for (final item in menuItems) item.itemId: item.category.toLowerCase(),
    };

    userItemCount.forEach((itemId, qty) {
      final category = categoryLookup[itemId];
      if (category != null) {
        userCategoryCount[category] = (userCategoryCount[category] ?? 0) + qty;
      }
    });

    final now = DateTime.now();
    final popularityWindow = now.subtract(const Duration(days: 21));

    for (final order in globalOrders) {
      final data = order.data();
      if ((data['status'] ?? '').toString().toLowerCase() == 'cancelled') {
        continue;
      }

      final createdAt = _parseDate(data['createdAt']);
      if (createdAt.isBefore(popularityWindow)) {
        continue;
      }

      final items = List<Map<String, dynamic>>.from(data['items'] ?? const []);
      for (final item in items) {
        final itemId = (item['itemId'] ?? '').toString();
        final qty = _safeInt(item['quantity'], fallback: 1);
        if (itemId.isNotEmpty) {
          globalItemCount[itemId] = (globalItemCount[itemId] ?? 0) + qty;
        }
      }
    }

    final maxPopularity = globalItemCount.values.fold<int>(1, (a, b) => a > b ? a : b);

    final recommendations = <FoodRecommendation>[];

    for (final item in menuItems) {
      final reasons = <String>[];
      var score = 1.0;

      final userCount = userItemCount[item.itemId] ?? 0;
      if (userCount > 0) {
        score += userCount * 1.4;
        reasons.add('Based on your order history');
      }

      final categoryAffinity = userCategoryCount[item.category.toLowerCase()] ?? 0;
      if (categoryAffinity > 0) {
        score += categoryAffinity * 0.4;
        reasons.add('You often choose ${item.category}');
      }

      final popularity = globalItemCount[item.itemId] ?? 0;
      if (popularity > 0) {
        score += (popularity / maxPopularity) * 3.0;
        reasons.add('Popular among students');
      }

      final dietaryScore = _dietaryMatchScore(item, dietaryPrefs);
      if (dietaryScore > 0) {
        score += dietaryScore;
        reasons.add('Matches your dietary preferences');
      }

      final allergyPenalty = _allergyPenalty(item, allergies);
      if (allergyPenalty < 0) {
        score += allergyPenalty;
      }

      final timeBoost = _timeOfDayBoost(item.category, now);
      if (timeBoost > 0) {
        score += timeBoost;
        reasons.add('Great for this time of day');
      }

      recommendations.add(
        FoodRecommendation(
          itemId: item.itemId,
          score: score,
          reasons: reasons.isEmpty ? const ['Fresh recommendation for you'] : reasons,
        ),
      );
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations;
  }

  double _dietaryMatchScore(MenuItem item, List<String> dietaryPrefs) {
    if (dietaryPrefs.isEmpty) {
      return 0;
    }

    final normalizedTags = item.tags.map((e) => e.toLowerCase()).toList();
    var score = 0.0;

    for (final pref in dietaryPrefs) {
      final p = pref.toLowerCase();
      if (p == 'veg' || p == 'vegan' || p == 'jain') {
        if (!normalizedTags.contains('non-veg')) {
          score += 1.8;
        }
      }
      if (p == 'non-veg' && normalizedTags.contains('non-veg')) {
        score += 1.2;
      }
    }

    return score;
  }

  double _allergyPenalty(MenuItem item, List<String> allergies) {
    if (allergies.isEmpty || allergies.contains('None')) {
      return 0;
    }

    final ingredients = item.ingredients.map((e) => e.toLowerCase()).toList();
    for (final allergy in allergies) {
      final needle = allergy.toLowerCase();
      if (ingredients.any((ing) => ing.contains(needle))) {
        return -100;
      }
    }
    return 0;
  }

  double _timeOfDayBoost(String category, DateTime now) {
    final hour = now.hour;
    final c = category.toLowerCase();

    if (hour >= 6 && hour < 11 && (c == 'beverages' || c == 'snacks')) {
      return 1.2;
    }
    if (hour >= 11 && hour < 15 && c == 'meals') {
      return 1.8;
    }
    if (hour >= 15 && hour < 19 && (c == 'snacks' || c == 'beverages')) {
      return 1.4;
    }
    if (hour >= 19 && hour < 23 && (c == 'meals' || c == 'desserts')) {
      return 1.6;
    }

    return 0.2;
  }

  int _safeInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
