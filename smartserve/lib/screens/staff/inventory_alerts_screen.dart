import 'package:flutter/material.dart';

import '../../models/inventory_alert_model.dart';
import '../../services/inventory_service.dart';

class InventoryAlertsScreen extends StatefulWidget {
  const InventoryAlertsScreen({super.key});

  @override
  State<InventoryAlertsScreen> createState() => _InventoryAlertsScreenState();
}

class _InventoryAlertsScreenState extends State<InventoryAlertsScreen> {
  final InventoryService _inventoryService = InventoryService();
  late Future<List<InventoryAlert>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = _inventoryService.getInventoryAlerts();
  }

  Future<void> _refresh() async {
    setState(() {
      _alertsFuture = _inventoryService.getInventoryAlerts();
    });
    await _alertsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Alerts'),
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<InventoryAlert>>(
        future: _alertsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load inventory alerts.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final alerts = snapshot.data ?? const <InventoryAlert>[];
          if (alerts.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(
                    child: Icon(Icons.verified, color: Colors.green, size: 72),
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text('No inventory alerts right now.'),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text('Stock levels look healthy.'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final color = _severityColor(alert.severity);
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: color.withOpacity(0.35)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                alert.itemName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                alert.severity.name.toUpperCase(),
                                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _metricChip('Current Stock', alert.currentStock.toString()),
                            _metricChip('Predicted Demand', alert.predictedNextDayDemand.toString()),
                            _metricChip('Restock Suggestion', alert.recommendedRestock.toString()),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          alert.reason,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _metricChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$title: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _severityColor(InventoryAlertSeverity severity) {
    switch (severity) {
      case InventoryAlertSeverity.critical:
        return Colors.red;
      case InventoryAlertSeverity.high:
        return Colors.deepOrange;
      case InventoryAlertSeverity.medium:
        return Colors.amber[800]!;
      case InventoryAlertSeverity.low:
        return Colors.blueGrey;
    }
  }
}
