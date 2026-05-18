import '../../models/review_model.dart';

abstract class IReviewService {
  Future<List<ReviewModel>> fetchReviews(String restaurantId, {int limit = 20});
  Future<void> submitReview(ReviewModel review);
  Future<void> editReview({required String restaurantId, required String reviewId, required String text, required double rating});
  Future<void> deleteReview({required String restaurantId, required String reviewId});
  Future<void> upvoteReview({required String restaurantId, required String reviewId});
  Future<String?> fetchTranslation({required String restaurantId, required String reviewId, required String targetLang});
  Future<void> cacheTranslation({required String restaurantId, required String reviewId, required String targetLang, required String translatedText});
}
