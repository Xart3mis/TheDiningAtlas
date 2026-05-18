class AiSummaryModel {
  final String restaurantId;
  final String vibeOneLiner;
  final List<String> topAspects;
  final List<String> caveats;
  final String bestTime;
  final DateTime generatedAt;

  const AiSummaryModel({
    required this.restaurantId,
    required this.vibeOneLiner,
    required this.topAspects,
    required this.caveats,
    required this.bestTime,
    required this.generatedAt,
  });
}
