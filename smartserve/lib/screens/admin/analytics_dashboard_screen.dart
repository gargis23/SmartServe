import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/analytics_model.dart';
import '../../services/analytics_service.dart';
import '../../services/app_notification_service.dart';

enum _DateRangePreset {
  last7,
  last30,
  last90,
  custom,
}

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  late DateTimeRange _selectedRange;
  _DateRangePreset _preset = _DateRangePreset.last30;

  @override
  void initState() {
    super.initState();
    _selectedRange = _buildPresetRange(_preset);
  }

  DateTimeRange _buildPresetRange(_DateRangePreset preset) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (preset) {
      case _DateRangePreset.last7:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 6)),
          end: todayEnd,
        );
      case _DateRangePreset.last30:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 29)),
          end: todayEnd,
        );
      case _DateRangePreset.last90:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 89)),
          end: todayEnd,
        );
      case _DateRangePreset.custom:
        return _selectedRange;
    }
  }

  void _applyPreset(_DateRangePreset preset) {
    setState(() {
      _preset = preset;
      if (preset != _DateRangePreset.custom) {
        _selectedRange = _buildPresetRange(preset);
      }
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _preset = _DateRangePreset.custom;
      _selectedRange = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
          999,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Send daily special',
            icon: const Icon(Icons.campaign_outlined),
            onPressed: () => _composePromotion(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRangeSelector(),
          Expanded(
            child: StreamBuilder<AnalyticsOverview>(
              stream: _analyticsService.streamOverviewForRange(
                startDate: _selectedRange.start,
                endDate: _selectedRange.end,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final data = snapshot.data ?? AnalyticsOverview.empty();

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'Reporting window: ${DateFormat('dd MMM yyyy').format(data.startDate)} - ${DateFormat('dd MMM yyyy').format(data.endDate)}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      _buildKpiGrid(data),
                      const SizedBox(height: 14),
                      _buildSectionCard(
                        title: 'Sales Trends',
                        subtitle: 'Revenue and orders over time',
                        child: Column(
                          children: [
                            _buildRevenueTrendChart(data.dailyRevenue),
                            const SizedBox(height: 16),
                            _buildOrdersTrendChart(data.dailyOrders),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSectionCard(
                        title: 'Revenue Mix',
                        subtitle: 'Payment methods and category performance',
                        child: Column(
                          children: [
                            _buildPaymentPieChart(data.paymentMethodDistribution),
                            const SizedBox(height: 16),
                            _buildCategoryBreakdown(data.categoryRevenue),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSectionCard(
                        title: 'Customer Insights',
                        subtitle: 'Engagement and repeat behavior',
                        child: Column(
                          children: [
                            _buildInsightRow(
                              title: 'Active customers',
                              value: data.activeCustomers.toString(),
                            ),
                            _buildInsightRow(
                              title: 'Repeat customers',
                              value: '${data.repeatCustomers} (${data.repeatCustomerRate.toStringAsFixed(1)}%)',
                            ),
                            _buildInsightRow(
                              title: 'Completion rate',
                              value: '${data.completionRate.toStringAsFixed(1)}%',
                            ),
                            _buildInsightRow(
                              title: 'Cancellation rate',
                              value: '${data.cancellationRate.toStringAsFixed(1)}%',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSectionCard(
                        title: 'Operations',
                        subtitle: 'Peak times and preparation efficiency',
                        child: Column(
                          children: [
                            _buildHourlyDemandChart(data.hourlyOrders),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMiniMetric(
                                    'Avg Prep Time',
                                    '${data.averagePrepTime.toStringAsFixed(1)} min',
                                    Icons.timer_outlined,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildMiniMetric(
                                    'Peak Hour',
                                    '${data.peakHour.toString().padLeft(2, '0')}:00',
                                    Icons.schedule,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSectionCard(
                        title: 'Top Selling Items',
                        subtitle: 'Best performers by quantity and revenue',
                        child: _buildTopItemsList(data.topItems),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFDF1F1),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _rangeChip('7D', _preset == _DateRangePreset.last7, () => _applyPreset(_DateRangePreset.last7)),
          _rangeChip('30D', _preset == _DateRangePreset.last30, () => _applyPreset(_DateRangePreset.last30)),
          _rangeChip('90D', _preset == _DateRangePreset.last90, () => _applyPreset(_DateRangePreset.last90)),
          ActionChip(
            avatar: const Icon(Icons.date_range, size: 16),
            label: Text(
              _preset == _DateRangePreset.custom
                  ? '${DateFormat('dd MMM').format(_selectedRange.start)} - ${DateFormat('dd MMM').format(_selectedRange.end)}'
                  : 'Custom',
            ),
            onPressed: _pickCustomRange,
            backgroundColor: _preset == _DateRangePreset.custom
                ? const Color(0xFFFFD6D6)
                : Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _rangeChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFFF6B6B),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 72),
            const SizedBox(height: 14),
            const Text(
              'Unable to load analytics',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid(AnalyticsOverview data) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildKpiCard(
          title: 'Revenue',
          value: 'Rs ${data.totalRevenue.toStringAsFixed(0)}',
          icon: Icons.payments,
          trend: data.revenueTrend,
        ),
        _buildKpiCard(
          title: 'Orders',
          value: data.totalOrders.toString(),
          icon: Icons.receipt_long,
          trend: data.ordersTrend,
        ),
        _buildKpiCard(
          title: 'Avg Order',
          value: 'Rs ${data.averageOrderValue.toStringAsFixed(1)}',
          icon: Icons.trending_up,
          trend: data.averageOrderValueTrend,
        ),
        _buildKpiCard(
          title: 'Completed',
          value: data.completedOrders.toString(),
          icon: Icons.check_circle,
          trend: null,
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required TrendMetric? trend,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 42) / 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFFF6B6B)),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            if (trend != null) ...[
              const SizedBox(height: 8),
              _buildTrendBadge(trend),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendBadge(TrendMetric trend) {
    final isPositive = trend.isPositive;
    final color = isPositive ? Colors.green : Colors.redAccent;
    final delta = trend.deltaPercent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${delta.abs().toStringAsFixed(1)}%',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildRevenueTrendChart(Map<String, double> dailyRevenue) {
    final entries = _sortedDoubleEntries(dailyRevenue, maxPoints: 10);
    if (entries.isEmpty) {
      return _buildNoDataChartState('No revenue trend available for this range.');
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].value));
    }

    final maxY = entries
        .map((entry) => entry.value)
        .fold<double>(0, (prev, value) => value > prev ? value : prev);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY == 0 ? 10 : maxY * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFFF6B6B),
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFF6B6B).withValues(alpha: 0.25),
                    const Color(0xFFFF6B6B).withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY <= 0 ? 2 : maxY / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey[200], strokeWidth: 1);
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _compactNumber(value),
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox.shrink();
                  }

                  final shouldShow = index == 0 ||
                      index == entries.length - 1 ||
                      index % 2 == 0;
                  if (!shouldShow) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _shortDate(entries[index].key),
                      style: TextStyle(color: Colors.grey[700], fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTrendChart(Map<String, int> dailyOrders) {
    final entries = _sortedIntEntries(dailyOrders, maxPoints: 10);
    if (entries.isEmpty) {
      return _buildNoDataChartState('No order trend available for this range.');
    }

    final values = entries.map((entry) => entry.value.toDouble()).toList();
    final labels = entries.map((entry) => _shortDate(entry.key)).toList();

    return _buildVerticalBarChart(
      values: values,
      labels: labels,
      barColor: Colors.blue,
      yLabelFormatter: (value) => value.toInt().toString(),
    );
  }

  Widget _buildPaymentPieChart(Map<String, int> distribution) {
    if (distribution.isEmpty) {
      return _buildNoDataChartState('No payment data available for this range.');
    }

    final total = distribution.values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) {
      return _buildNoDataChartState('No payment data available for this range.');
    }

    final entries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = <Color>[
      const Color(0xFFFF6B6B),
      const Color(0xFF4F8DFD),
      const Color(0xFF55C271),
      const Color(0xFFFFB547),
      const Color(0xFF8F6BFF),
    ];

    return SizedBox(
      height: 210,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 36,
                sectionsSpace: 2,
                sections: List.generate(entries.length, (index) {
                  final entry = entries[index];
                  final percent = (entry.value / total) * 100;
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: entry.value.toDouble(),
                    title: '${percent.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                    radius: 52,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(entries.length, (index) {
                final entry = entries[index];
                final percent = (entry.value / total) * 100;
                final color = colors[index % colors.length];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('${percent.toStringAsFixed(0)}%'),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(Map<String, double> categoryRevenue) {
    if (categoryRevenue.isEmpty) {
      return _buildNoDataChartState('No category-level data available yet.');
    }

    final entries = categoryRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = entries.take(6).toList();
    final maxValue = top
        .map((entry) => entry.value)
        .fold<double>(0, (prev, value) => value > prev ? value : prev);

    return Column(
      children: top.map((entry) {
        final widthFactor = maxValue == 0 ? 0.0 : entry.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 78,
                child: Text(
                  entry.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: widthFactor,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 58,
                child: Text(
                  _compactNumber(entry.value),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHourlyDemandChart(Map<int, int> hourlyOrders) {
    if (hourlyOrders.isEmpty) {
      return _buildNoDataChartState('No hourly demand data available in this range.');
    }

    final hours = List<int>.generate(24, (index) => index);
    final values = hours.map((hour) => (hourlyOrders[hour] ?? 0).toDouble()).toList();
    final labels = hours
        .map((hour) => hour % 3 == 0 ? '${hour.toString().padLeft(2, '0')}:00' : '')
        .toList();

    return _buildVerticalBarChart(
      values: values,
      labels: labels,
      barColor: const Color(0xFF55C271),
      yLabelFormatter: (value) => value.toInt().toString(),
      chartHeight: 190,
    );
  }

  Widget _buildVerticalBarChart({
    required List<double> values,
    required List<String> labels,
    required Color barColor,
    required String Function(double value) yLabelFormatter,
    double chartHeight = 210,
  }) {
    if (values.isEmpty) {
      return _buildNoDataChartState('No data available.');
    }

    final maxY = values.fold<double>(0, (prev, value) => value > prev ? value : prev);

    final barGroups = List.generate(values.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: values[index],
            width: values.length > 16 ? 5 : 8,
            borderRadius: BorderRadius.circular(4),
            color: barColor,
          ),
        ],
      );
    });

    return SizedBox(
      height: chartHeight,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 5 : maxY * 1.2,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY <= 0 ? 1 : maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200], strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text(
                  yLabelFormatter(value),
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  final label = labels[index];
                  if (label.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 9)),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightRow({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF6B6B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemsList(List<TopItemMetric> items) {
    if (items.isEmpty) {
      return _buildNoDataChartState('No top-selling items in this range.');
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final item = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                child: Text('$rank', style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Sold ${item.quantitySold}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  ],
                ),
              ),
              Text('Rs ${item.revenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoDataChartState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.grey[700]),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<MapEntry<String, double>> _sortedDoubleEntries(
    Map<String, double> map, {
    required int maxPoints,
  }) {
    final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    if (entries.length <= maxPoints) {
      return entries;
    }
    return entries.sublist(entries.length - maxPoints);
  }

  List<MapEntry<String, int>> _sortedIntEntries(
    Map<String, int> map, {
    required int maxPoints,
  }) {
    final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    if (entries.length <= maxPoints) {
      return entries;
    }
    return entries.sublist(entries.length - maxPoints);
  }

  String _shortDate(String key) {
    try {
      final parsed = DateTime.parse(key);
      return DateFormat('dd MMM').format(parsed);
    } catch (_) {
      if (key.length >= 5) {
        return key.substring(key.length - 5);
      }
      return key;
    }
  }

  String _compactNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  Future<void> _composePromotion(BuildContext context) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Broadcast daily special'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (shouldSend != true) {
      return;
    }

    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Title and message are required.')),
      );
      return;
    }

    try {
      await AppNotificationService().broadcastNotificationToRole(
        role: 'student',
        title: title,
        body: body,
        type: 'promo',
      );

      messenger.showSnackBar(
        const SnackBar(content: Text('Promotion sent to student users.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to send promotion.')),
      );
    }
  }
}
