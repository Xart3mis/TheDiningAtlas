import 'package:flutter/material.dart';
import '../models/review_model.dart';

class ReviewProvider extends ChangeNotifier {
  final Map<String, List<ReviewModel>> _reviews = {};
  final Map<String, Map<String, String>> _translations = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<ReviewModel> reviewsFor(String restaurantId) =>
      _reviews[restaurantId] ?? [];

  String? translationFor(String reviewId, String lang) =>
      _translations[reviewId]?[lang];

  Future<void> loadReviews(String restaurantId) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _reviews[restaurantId] = [
      ReviewModel(
        id: 'r1',
        restaurantId: restaurantId,
        authorId: 'u1',
        authorName: 'Yuki T.',
        authorPhotoUrl: '',
        text: 'Incredible omakase experience. Chef is attentive and the fish is pristine.',
        rating: 5.0,
        upvotes: 42,
        createdAt: DateTime(2026, 3, 10),
      ),
      ReviewModel(
        id: 'r2',
        restaurantId: restaurantId,
        authorId: 'u2',
        authorName: 'Marco L.',
        authorPhotoUrl: '',
        text: 'Worth the early morning queue. Life-changing tuna.',
        rating: 4.9,
        upvotes: 31,
        createdAt: DateTime(2026, 2, 15),
      ),
    ];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> submitReview(ReviewModel review) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final list = List<ReviewModel>.from(_reviews[review.restaurantId] ?? []);
    list.insert(0, ReviewModel(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: review.restaurantId,
      authorId: review.authorId,
      authorName: review.authorName,
      authorPhotoUrl: review.authorPhotoUrl,
      text: review.text,
      rating: review.rating,
      upvotes: 0,
      createdAt: DateTime.now(),
    ));
    _reviews[review.restaurantId] = list;
    notifyListeners();
  }

  Future<void> upvote({required String restaurantId, required String reviewId}) async {
    final list = _reviews[restaurantId];
    if (list == null) return;
    final idx = list.indexWhere((r) => r.id == reviewId);
    if (idx == -1) return;
    final r = list[idx];
    list[idx] = ReviewModel(
      id: r.id, restaurantId: r.restaurantId, authorId: r.authorId,
      authorName: r.authorName, authorPhotoUrl: r.authorPhotoUrl,
      text: r.text, rating: r.rating, upvotes: r.upvotes + 1, createdAt: r.createdAt,
    );
    notifyListeners();
  }

  Future<void> translate({
    required String restaurantId,
    required String reviewId,
    required String text,
    required String targetLang,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _translations[reviewId] = {targetLang: '[Translated] $text'};
    notifyListeners();
  }
}
