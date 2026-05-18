import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingPrefsModel {
  final List<String> vibes;       // e.g. ['hidden_cafe','street_food','rooftop_bar']
  final String budget;            // '$' | '$$' | '$$$'
  final List<String> atmosphere;  // e.g. ['quiet','outdoor','artsy']
  final String countryId;
  final Map<String, double> aiWeights; // category → weight score

  const OnboardingPrefsModel({
    required this.vibes,
    required this.budget,
    required this.atmosphere,
    required this.countryId,
    required this.aiWeights,
  });

  factory OnboardingPrefsModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OnboardingPrefsModel(
      vibes: List<String>.from(d['vibes'] ?? []),
      budget: d['budget'] ?? '\$',
      atmosphere: List<String>.from(d['atmosphere'] ?? []),
      countryId: d['countryId'] ?? '',
      aiWeights: Map<String, double>.from(
        (d['aiWeights'] ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vibes': vibes,
    'budget': budget,
    'atmosphere': atmosphere,
    'countryId': countryId,
    'aiWeights': aiWeights,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
