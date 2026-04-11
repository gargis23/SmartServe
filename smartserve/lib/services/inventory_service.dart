import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inventory_alert_model.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, int>> predictNextDayDemand() async {
    final ordersSnapshot = await _db.collection('orders').get();

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 14));

    final itemDailyCounts = <String, Map<String, int>>{};

    for (final doc in ordersSnapshot.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'cancelled') {
        continue;
      }

      final createdAt = _parseDate(data['createdAt']);
      if (createdAt.isBefore(cutoff)) {
        continue;
      }

      final dayKey = _dayKey(createdAt);
      final items = List<Map<String, dynamic>>.from(data['items'] ?? const []);
      for (final item in items) {
        final itemId = (item['itemId'] ?? '').toString();
        if (itemId.isEmpty) {
          continue;
        }

        final qty = _safeInt(item['quantity'], fallback: 1);
        final perDay = itemDailyCounts.putIfAbsent(itemId, () => <String, int>{});
        perDay[dayKey] = (perDay[dayKey] ?? 0) + qty;
      }
    }

    final predictions = <String, int>{};
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final isWeekend = tomorrow.weekday == DateTime.saturday || tomorrow.weekday == DateTime.sunday;

    itemDailyCounts.forEach((itemId, perDay) {
      final recent = <int>[];
      for (var i = 0; i < 7; i++) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        recent.add(perDay[_dayKey(day)] ?? 0);
      }

      const weights = [0.35, 0.24, 0.16, 0.11, 0.07, 0.04, 0.03];
      var weighted = 0.0;
      for (var i = 0; i < recent.length; i++) {
        weighted += recent[i] * weights[i];
      }

      if (isWeekend) {
        weighted *= 1.15;
      }

      final prediction = weighted.round();
      predictions[itemId] = prediction > 0 ? prediction : 1;
    });

    return predictions;
  }

  Future<List<InventoryAlert>> getInventoryAlerts() async {
    final predictions = await predictNextDayDemand();
    final menuSnapshot = await _db.collection('menu_items').get();

    final alerts = <InventoryAlert>[];

    for (final doc in menuSnapshot.docs) {
      final data = doc.data();
      final itemId = doc.id;
      final itemName = (data['name'] ?? 'Unnamed Item').toString();
      final currentStock = _safeInt(data['stockQuantity'], fallback: 20);
      final predictedDemand = predictions[itemId] ?? 0;

      if (predictedDemand <= 0 && currentStock > 8) {
        continue;
      }

      final demandBaseline = predictedDemand <= 0 ? 1 : predictedDemand;
      final coverage = currentStock / demandBaseline;

      InventoryAlertSeverity? severity;
      if (coverage < 0.5) {
        severity = InventoryAlertSeverity.critical;
      } else if (coverage < 0.9) {
        severity = InventoryAlertSeverity.high;
      } else if (coverage < 1.3 || currentStock < 6) {
        severity = InventoryAlertSeverity.medium;
      } else if (currentStock < 10) {
        severity = InventoryAlertSeverity.low;
      }

      if (severity == null) {
        continue;
      }

      final suggestedBuffer = (predictedDemand * 0.2).ceil().clamp(2, 20);
      final recommendedRestock =
          (predictedDemand + suggestedBuffer - currentStock) > 0
              ? (predictedDemand + suggestedBuffer - currentStock)
              : 0;

      final reason = predictedDemand > 0
          ? 'Predicted demand is $predictedDemand for tomorrow with stock at $currentStock.'
          : 'Stock is running low and this item should be monitored.';

      alerts.add(
        InventoryAlert(
          itemId: itemId,
          itemName: itemName,
          currentStock: currentStock,
          predictedNextDayDemand: predictedDemand,
          recommendedRestock: recommendedRestock,
          severity: severity,
          reason: reason,
        ),
      );
    }

    alerts.sort((a, b) {
      final severityCompare = _severityWeight(b.severity).compareTo(_severityWeight(a.severity));
      if (severityCompare != 0) {
        return severityCompare;
      }
      return b.recommendedRestock.compareTo(a.recommendedRestock);
    });

    return alerts;
  }

  int _severityWeight(InventoryAlertSeverity severity) {
    switch (severity) {
      case InventoryAlertSeverity.critical:
        return 4;
      case InventoryAlertSeverity.high:
        return 3;
      case InventoryAlertSeverity.medium:
        return 2;
      case InventoryAlertSeverity.low:
        return 1;
    }
  }

  String _dayKey(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
}
