import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceSummaryModel {
  final String vibeOneLiner;
  final List<String> topAspects;
  final String mainDish;
  final List<String> caveats;
  final String bestTime;
  final DateTime generatedAt;
  final int reviewCountAtGeneration;

  const PlaceSummaryModel({
    required this.vibeOneLiner,
    required this.topAspects,
    required this.mainDish,
    required this.caveats,
    required this.bestTime,
    required this.generatedAt,
    required this.reviewCountAtGeneration,
  });

  factory PlaceSummaryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PlaceSummaryModel(
      vibeOneLiner: d['vibeOneLiner'] ?? '',
      topAspects: List<String>.from(d['topAspects'] ?? []),
      mainDish: d['mainDish'] ?? '',
      caveats: List<String>.from(d['caveats'] ?? []),
      bestTime: d['bestTime'] ?? '',
      generatedAt: (d['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewCountAtGeneration: d['reviewCountAtGeneration'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vibeOneLiner': vibeOneLiner,
    'topAspects': topAspects,
    'mainDish': mainDish,
    'caveats': caveats,
    'bestTime': bestTime,
    'generatedAt': FieldValue.serverTimestamp(),
    'reviewCountAtGeneration': reviewCountAtGeneration,
  };
}
