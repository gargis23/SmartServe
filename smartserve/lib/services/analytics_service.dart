import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/analytics_model.dart';

class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<AnalyticsOverview> streamOverview({int lookbackDays = 30}) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: lookbackDays - 1));
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return streamOverviewForRange(startDate: start, endDate: end);
  }

  Stream<AnalyticsOverview> streamOverviewForRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _db.collection('orders').snapshots().asyncMap((snapshot) async {
      final menuSnapshot = await _db.collection('menu_items').get();
      final categoryByItemId = <String, String>{
        for (final doc in menuSnapshot.docs)
          doc.id: (doc.data()['category'] ?? 'Other').toString(),
      };

      return _buildOverview(
        docs: snapshot.docs,
        startDate: startDate,
        endDate: endDate,
        categoryByItemId: categoryByItemId,
      );
    });
  }

  AnalyticsOverview _buildOverview({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, String> categoryByItemId,
  }) {
    if (docs.isEmpty) {
      return AnalyticsOverview.empty();
    }

    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    final periodDays = normalizedEnd.difference(normalizedStart).inDays + 1;
    final previousEnd = normalizedStart.subtract(const Duration(milliseconds: 1));
    final previousStart = DateTime(
      previousEnd.year,
      previousEnd.month,
      previousEnd.day,
    ).subtract(Duration(days: periodDays - 1));

    final current = _AnalyticsBucket();
    final previous = _AnalyticsBucket();

    for (final doc in docs) {
      final data = doc.data();
      final createdAt = _parseDate(data['createdAt']);

      if (_isWithin(createdAt, normalizedStart, normalizedEnd)) {
        current.addOrder(
          order: data,
          createdAt: createdAt,
          categoryByItemId: categoryByItemId,
          dayKeyBuilder: _dayKey,
        );
      } else if (_isWithin(createdAt, previousStart, previousEnd)) {
        previous.addOrder(
          order: data,
          createdAt: createdAt,
          categoryByItemId: categoryByItemId,
          dayKeyBuilder: _dayKey,
        );
      }
    }

    final top = current.itemQty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topItems = top.take(6).map((entry) {
      return TopItemMetric(
        name: entry.key,
        quantitySold: entry.value,
        revenue: current.itemRevenue[entry.key] ?? 0,
      );
    }).toList();

    final totalOrders = current.totalOrders;
    final totalRevenue = current.revenue;
    final averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    final completionRate =
        totalOrders > 0 ? (current.completedOrders / totalOrders) * 100 : 0.0;
    final cancellationRate =
        totalOrders > 0 ? (current.cancelledOrders / totalOrders) * 100 : 0.0;
    final repeatCustomerRate = current.customerIds.isNotEmpty
        ? (current.repeatCustomers / current.customerIds.length) * 100
        : 0.0;

    final previousAverageOrderValue = previous.totalOrders > 0
        ? previous.revenue / previous.totalOrders
        : 0.0;

    return AnalyticsOverview(
      startDate: normalizedStart,
      endDate: normalizedEnd,
      totalOrders: totalOrders,
      completedOrders: current.completedOrders,
      cancelledOrders: current.cancelledOrders,
      activeCustomers: current.customerIds.length,
      repeatCustomers: current.repeatCustomers,
      totalRevenue: totalRevenue,
      averageOrderValue: averageOrderValue,
      completionRate: completionRate,
      cancellationRate: cancellationRate,
      repeatCustomerRate: repeatCustomerRate,
      averagePrepTime: current.averagePrepTime,
      peakHour: _peakHour(current.hourlyOrders),
      dailyRevenue: current.dailyRevenue,
      dailyOrders: current.dailyOrders,
      paymentMethodDistribution: current.paymentMethods,
      categoryRevenue: current.categoryRevenue,
      hourlyOrders: current.hourlyOrders,
      topItems: topItems,
      revenueTrend: TrendMetric(current: totalRevenue, previous: previous.revenue),
      ordersTrend: TrendMetric(
        current: totalOrders.toDouble(),
        previous: previous.totalOrders.toDouble(),
      ),
      averageOrderValueTrend: TrendMetric(
        current: averageOrderValue,
        previous: previousAverageOrderValue,
      ),
    );
  }

  int _peakHour(Map<int, int> hourlyCount) {
    if (hourlyCount.isEmpty) {
      return 0;
    }

    var bestHour = 0;
    var bestCount = -1;
    hourlyCount.forEach((hour, orderCount) {
      if (orderCount > bestCount) {
        bestHour = hour;
        bestCount = orderCount;
      }
    });
    return bestHour;
  }

  bool _isWithin(DateTime value, DateTime start, DateTime end) {
    return !value.isBefore(start) && !value.isAfter(end);
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
}

class _AnalyticsBucket {
  int totalOrders = 0;
  int completedOrders = 0;
  int cancelledOrders = 0;
  double revenue = 0;
  double prepTimeTotal = 0;
  int prepTimeSamples = 0;

  final Set<String> customerIds = <String>{};
  final Map<String, int> userOrderCount = <String, int>{};
  final Map<String, double> dailyRevenue = <String, double>{};
  final Map<String, int> dailyOrders = <String, int>{};
  final Map<String, int> paymentMethods = <String, int>{};
  final Map<String, int> itemQty = <String, int>{};
  final Map<String, double> itemRevenue = <String, double>{};
  final Map<String, double> categoryRevenue = <String, double>{};
  final Map<int, int> hourlyOrders = <int, int>{};

  void addOrder({
    required Map<String, dynamic> order,
    required DateTime createdAt,
    required Map<String, String> categoryByItemId,
    required String Function(DateTime date) dayKeyBuilder,
  }) {
    totalOrders += 1;

    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    final amount = _safeDouble(order['totalAmount']);
    final userId = (order['userId'] ?? '').toString();
    if (userId.isNotEmpty) {
      customerIds.add(userId);
      userOrderCount[userId] = (userOrderCount[userId] ?? 0) + 1;
    }

    final dayKey = dayKeyBuilder(createdAt);
    dailyOrders[dayKey] = (dailyOrders[dayKey] ?? 0) + 1;
    hourlyOrders[createdAt.hour] = (hourlyOrders[createdAt.hour] ?? 0) + 1;

    final paymentMethod = (order['paymentMethod'] ?? 'unknown').toString().toLowerCase();
    paymentMethods[paymentMethod] = (paymentMethods[paymentMethod] ?? 0) + 1;

    final contributesRevenue =
        status == 'completed' || status == 'confirmed' || status == 'preparing' || status == 'ready';

    if (contributesRevenue) {
      revenue += amount;
      dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) + amount;
    }

    if (status == 'completed') {
      completedOrders += 1;
    }

    if (status == 'cancelled') {
      cancelledOrders += 1;
    }

    final prepTime = _safeDouble(order['estimatedPrepTime']);
    if (prepTime > 0) {
      prepTimeTotal += prepTime;
      prepTimeSamples += 1;
    }

    final items = List<Map<String, dynamic>>.from(order['items'] ?? const []);
    for (final item in items) {
      final name = (item['name'] ?? 'Unknown').toString();
      final qty = _safeInt(item['quantity']);
      final itemPrice = _safeDouble(item['price']);
      final itemId = (item['itemId'] ?? '').toString();

      itemQty[name] = (itemQty[name] ?? 0) + qty;
      itemRevenue[name] = (itemRevenue[name] ?? 0) + (itemPrice * qty);

      final category = (categoryByItemId[itemId] ?? 'Other').toString();
      categoryRevenue[category] = (categoryRevenue[category] ?? 0) + (itemPrice * qty);
    }
  }

  int get repeatCustomers {
    return userOrderCount.values.where((orderCount) => orderCount > 1).length;
  }

  double get averagePrepTime {
    if (prepTimeSamples == 0) {
      return 0;
    }
    return prepTimeTotal / prepTimeSamples;
  }

  int _safeInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 1;
    }
    return 1;
  }

  double _safeDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
