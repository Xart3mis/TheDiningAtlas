import 'package:flutter/material.dart';
import '../models/ai_summary_model.dart';

class AiProvider extends ChangeNotifier {
  final Map<String, AiSummaryModel> _summaries = {};
  bool _isGenerating = false;

  bool get isGenerating => _isGenerating;

  AiSummaryModel? summaryFor(String restaurantId) => _summaries[restaurantId];

  Future<void> loadSummary(String restaurantId) async {
    _isGenerating = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    _summaries[restaurantId] = AiSummaryModel(
      restaurantId: restaurantId,
      vibeOneLiner: 'A focused counter where every seat faces the chef — intimacy is the whole point.',
      topAspects: ['Freshness', 'Service', 'Atmosphere'],
      caveats: ['Queue can be 2h+'],
      bestTime: 'Open at 5am · arrive by 4:30am',
      generatedAt: DateTime.now(),
    );
    _isGenerating = false;
    notifyListeners();
  }
}
