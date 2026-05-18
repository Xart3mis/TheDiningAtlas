import 'package:cloud_firestore/cloud_firestore.dart';
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
      // Check Firestore cache first
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('summary')
          .doc('data')
          .get();

      if (doc.exists) {
        final cached = PlaceSummaryModel.fromFirestore(doc);
        final ageInDays = DateTime.now().difference(cached.generatedAt).inDays;
        if (ageInDays < 7) {
          _summaries[restaurantId] = cached;
          return;
        }
      }

      // Cache is stale or missing — generate fresh
      final reviews = await _reviewService.fetchReviews(restaurantId, limit: 50);
      if (reviews.length < 5) {
        _summaries[restaurantId] = null;
        return;
      }
      final summary = await _aiService.summarizeReviews(
        restaurantId: restaurantId,
        reviews: reviews,
      );
      await _aiService.cacheSummary(restaurantId, summary);
      _summaries[restaurantId] = summary;
    } catch (_) {
      _summaries[restaurantId] = null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}
