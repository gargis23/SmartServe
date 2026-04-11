class FoodRecommendation {
  final String itemId;
  final double score;
  final List<String> reasons;

  const FoodRecommendation({
    required this.itemId,
    required this.score,
    required this.reasons,
  });
}
