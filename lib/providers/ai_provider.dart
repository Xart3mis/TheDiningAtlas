import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../services/interfaces/i_ai_service.dart';
import '../services/interfaces/i_review_service.dart';
import '../models/place_summary_model.dart';

class AiProvider extends ChangeNotifier {
  final IAiService _aiService;
  final IReviewService _reviewService;
  AiProvider(this._aiService, this._reviewService);

  final Map<String, PlaceSummaryModel?> _summaries = {};
  final Set<String> _errors = {};
  final Set<String> _requested = {};
  bool _isGenerating = false;

  PlaceSummaryModel? summaryFor(String restaurantId) => _summaries[restaurantId];
  bool get isGenerating => _isGenerating;
  bool hasError(String restaurantId) => _errors.contains(restaurantId);
  bool hasBeenRequested(String restaurantId) => _requested.contains(restaurantId);

  Future<void> loadSummary(String restaurantId) async {
    if (_summaries.containsKey(restaurantId) ||
        (_errors.contains(restaurantId) && _requested.contains(restaurantId))) return;

    _requested.add(restaurantId);
    _isGenerating = true;
    _errors.remove(restaurantId);
    notifyListeners();
    try {
      // Check Firestore cache first
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.kColRestaurants)
          .doc(restaurantId)
          .collection(AppConstants.kDocSummary)
          .doc('data')
          .get();

      if (doc.exists) {
        final cached = PlaceSummaryModel.fromFirestore(doc);
        final ageInDays = DateTime.now().difference(cached.generatedAt).inDays;
        if (ageInDays < AppConstants.kSummaryTtlDays) {
          _summaries[restaurantId] = cached;
          return;
        }
      }

      // Cache is stale or missing — generate fresh from all available reviews
      final reviews = await _reviewService.fetchReviews(restaurantId, limit: AppConstants.kSummaryBatchSize);
      final summary = await _aiService.summarizeReviews(
        restaurantId: restaurantId,
        reviews: reviews,
      );
      await _aiService.cacheSummary(restaurantId, summary);
      _summaries[restaurantId] = summary;
    } catch (_) {
      _errors.add(restaurantId);
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}
