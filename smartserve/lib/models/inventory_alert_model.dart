enum InventoryAlertSeverity {
  low,
  medium,
  high,
  critical,
}

class InventoryAlert {
  final String itemId;
  final String itemName;
  final int currentStock;
  final int predictedNextDayDemand;
  final int recommendedRestock;
  final InventoryAlertSeverity severity;
  final String reason;

  const InventoryAlert({
    required this.itemId,
    required this.itemName,
    required this.currentStock,
    required this.predictedNextDayDemand,
    required this.recommendedRestock,
    required this.severity,
    required this.reason,
  });
}
