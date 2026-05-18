import 'package:flutter/material.dart';
import '../services/interfaces/i_review_service.dart';
import '../services/interfaces/i_ai_service.dart';
import '../models/review_model.dart';

class ReviewProvider extends ChangeNotifier {
  final IReviewService _reviewService;
  final IAiService _aiService;
  ReviewProvider(this._reviewService, this._aiService);

  final Map<String, List<ReviewModel>> _reviews = {};
  final Map<String, String> _translations = {}; // key: 'reviewId_lang'
  bool _isLoading = false;
  String? _error;

  List<ReviewModel> reviewsFor(String restaurantId) => _reviews[restaurantId] ?? [];
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? translationFor(String reviewId, String lang) => _translations['${reviewId}_$lang'];

  Future<void> loadReviews(String restaurantId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _reviews[restaurantId] = await _reviewService.fetchReviews(restaurantId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitReview(ReviewModel review) async {
    try {
      await _reviewService.submitReview(review);
      _reviews[review.restaurantId] = [review, ...reviewsFor(review.restaurantId)];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteReview({required String restaurantId, required String reviewId}) async {
    await _reviewService.deleteReview(restaurantId: restaurantId, reviewId: reviewId);
    _reviews[restaurantId]?.removeWhere((r) => r.id == reviewId);
    notifyListeners();
  }

  Future<void> editReview({
    required String restaurantId,
    required String reviewId,
    required String text,
    required double rating,
  }) async {
    await _reviewService.editReview(
      restaurantId: restaurantId,
      reviewId: reviewId,
      text: text,
      rating: rating,
    );
    final list = _reviews[restaurantId];
    if (list != null) {
      final idx = list.indexWhere((r) => r.id == reviewId);
      if (idx != -1) {
        final old = list[idx];
        _reviews[restaurantId]![idx] = ReviewModel(
          id: reviewId,
          restaurantId: restaurantId,
          authorId: old.authorId,
          authorName: old.authorName,
          authorPhotoUrl: old.authorPhotoUrl,
          text: text,
          rating: rating,
          upvotes: old.upvotes,
          createdAt: old.createdAt,
        );
      }
    }
    notifyListeners();
  }

  Future<void> upvote({required String restaurantId, required String reviewId}) async {
    await _reviewService.upvoteReview(restaurantId: restaurantId, reviewId: reviewId);
    notifyListeners();
  }

  Future<void> translate({required String restaurantId, required String reviewId, required String text, required String targetLang}) async {
    final key = '${reviewId}_$targetLang';
    if (_translations.containsKey(key)) return;

    final cached = await _reviewService.fetchTranslation(
      restaurantId: restaurantId, reviewId: reviewId, targetLang: targetLang,
    );
    if (cached != null) { _translations[key] = cached; notifyListeners(); return; }

    final translated = await _aiService.translate(text: text, targetLang: targetLang);
    await _reviewService.cacheTranslation(
      restaurantId: restaurantId, reviewId: reviewId,
      targetLang: targetLang, translatedText: translated,
    );
    _translations[key] = translated;
    notifyListeners();
  }

  void reset() {
    _reviews.clear();
    _translations.clear();
    _error = null;
    notifyListeners();
  }
}
