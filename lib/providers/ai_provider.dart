import 'package:flutter/material.dart';
import '../services/interfaces/i_ai_service.dart';
import '../services/interfaces/i_review_service.dart';
import '../models/place_summary_model.dart';

class AiProvider extends ChangeNotifier {
  final IAiService _aiService;
  final IReviewService _reviewService;
  AiProvider(this._aiService, this._reviewService);

  final Map<String, PlaceSummaryModel?> _summaries = {};
  bool _isGenerating = false;

  PlaceSummaryModel? summaryFor(String restaurantId) => _summaries[restaurantId];
  bool get isGenerating => _isGenerating;

  Future<void> loadSummary(String restaurantId) async {
    if (_summaries.containsKey(restaurantId)) return;
    _isGenerating = true;
    notifyListeners();
    try {
      final reviews = await _reviewService.fetchReviews(restaurantId, limit: 50);
      if (reviews.length < 5) { _summaries[restaurantId] = null; return; }
      _summaries[restaurantId] = await _aiService.summarizeReviews(
        restaurantId: restaurantId, reviews: reviews,
      );
    } catch (_) {
      _summaries[restaurantId] = null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}
