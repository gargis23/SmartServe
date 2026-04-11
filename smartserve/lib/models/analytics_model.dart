class TopItemMetric {
  final String name;
  final int quantitySold;
  final double revenue;

  const TopItemMetric({
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });
}

class TrendMetric {
  final double current;
  final double previous;

  const TrendMetric({
    required this.current,
    required this.previous,
  });

  double get deltaPercent {
    if (previous == 0) {
      return current == 0 ? 0 : 100;
    }
    return ((current - previous) / previous) * 100;
  }

  bool get isPositive => deltaPercent >= 0;
}

class AnalyticsOverview {
  final DateTime startDate;
  final DateTime endDate;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int activeCustomers;
  final int repeatCustomers;
  final double totalRevenue;
  final double averageOrderValue;
  final double completionRate;
  final double cancellationRate;
  final double repeatCustomerRate;
  final double averagePrepTime;
  final int peakHour;
  final Map<String, double> dailyRevenue;
  final Map<String, int> dailyOrders;
  final Map<String, int> paymentMethodDistribution;
  final Map<String, double> categoryRevenue;
  final Map<int, int> hourlyOrders;
  final List<TopItemMetric> topItems;
  final TrendMetric revenueTrend;
  final TrendMetric ordersTrend;
  final TrendMetric averageOrderValueTrend;

  const AnalyticsOverview({
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.activeCustomers,
    required this.repeatCustomers,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.completionRate,
    required this.cancellationRate,
    required this.repeatCustomerRate,
    required this.averagePrepTime,
    required this.peakHour,
    required this.dailyRevenue,
    required this.dailyOrders,
    required this.paymentMethodDistribution,
    required this.categoryRevenue,
    required this.hourlyOrders,
    required this.topItems,
    required this.revenueTrend,
    required this.ordersTrend,
    required this.averageOrderValueTrend,
  });

  factory AnalyticsOverview.empty() {
    final now = DateTime.now();
    return AnalyticsOverview(
      startDate: now,
      endDate: now,
      totalOrders: 0,
      completedOrders: 0,
      cancelledOrders: 0,
      activeCustomers: 0,
      repeatCustomers: 0,
      totalRevenue: 0,
      averageOrderValue: 0,
      completionRate: 0,
      cancellationRate: 0,
      repeatCustomerRate: 0,
      averagePrepTime: 0,
      peakHour: 0,
      dailyRevenue: {},
      dailyOrders: {},
      paymentMethodDistribution: {},
      categoryRevenue: {},
      hourlyOrders: {},
      topItems: [],
      revenueTrend: const TrendMetric(current: 0, previous: 0),
      ordersTrend: const TrendMetric(current: 0, previous: 0),
      averageOrderValueTrend: const TrendMetric(current: 0, previous: 0),
    );
  }
}
