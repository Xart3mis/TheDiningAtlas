import '../interfaces/i_review_service.dart';
import '../../models/review_model.dart';

final _kSampleReviews = [
  ReviewModel(
    id: 'rev1', restaurantId: 'r1', authorId: 'u2', authorName: 'Maya Chen',
    authorPhotoUrl: '', text: 'Absolutely incredible. Worth every minute of the wait.',
    rating: 5.0, upvotes: 42, createdAt: DateTime(2024, 3, 15),
  ),
  ReviewModel(
    id: 'rev2', restaurantId: 'r1', authorId: 'u3', authorName: 'Ryo Tanaka',
    authorPhotoUrl: '', text: 'Best omakase under 3000 yen. A Tokyo institution.',
    rating: 5.0, upvotes: 38, createdAt: DateTime(2024, 2, 20),
  ),
];

class MockReviewService implements IReviewService {
  final _reviews = List<ReviewModel>.from(_kSampleReviews);

  @override
  Future<List<ReviewModel>> fetchReviews(String restaurantId, {int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _reviews.where((r) => r.restaurantId == restaurantId).take(limit).toList();
  }

  @override
  Future<void> submitReview(ReviewModel review) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _reviews.add(review);
  }

  @override
  Future<void> editReview({required String restaurantId, required String reviewId, required String text, required double rating}) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> deleteReview({required String restaurantId, required String reviewId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _reviews.removeWhere((r) => r.id == reviewId);
  }

  @override
  Future<void> upvoteReview({required String restaurantId, required String reviewId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<String?> fetchTranslation({required String restaurantId, required String reviewId, required String targetLang}) async {
    return null;
  }

  @override
  Future<void> cacheTranslation({required String restaurantId, required String reviewId, required String targetLang, required String translatedText}) async {}
}
