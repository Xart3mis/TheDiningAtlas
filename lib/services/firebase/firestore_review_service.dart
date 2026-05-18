import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_review_service.dart';
import '../../models/review_model.dart';
import '../../core/constants/app_constants.dart';

class FirestoreReviewService implements IReviewService {
  final _db = FirebaseFirestore.instance;

  CollectionReference _reviewsCol(String restaurantId) => _db
      .collection(AppConstants.kColRestaurants)
      .doc(restaurantId)
      .collection(AppConstants.kColReviews);

  DocumentReference _restaurantRef(String restaurantId) =>
      _db.collection(AppConstants.kColRestaurants).doc(restaurantId);

  DocumentReference _userRef(String uid) =>
      _db.collection(AppConstants.kColUsers).doc(uid);

  // ─── Tier calculation helper ──────────────────────────────────────────────
  String _tierForScore(int score) {
    if (score >= 2000) return 'city_legend';
    if (score >= 500) return 'super_local';
    if (score >= 100) return 'local';
    return 'explorer';
  }

  // ─── Read all ratings and compute average ─────────────────────────────────
  Future<Map<String, dynamic>> _computeRatingStats(String restaurantId) async {
    final snap = await _reviewsCol(restaurantId).get();
    if (snap.docs.isEmpty) return {'avgRating': 0.0, 'reviewCount': 0};
    final total = snap.docs.fold<double>(
      0,
      (acc, doc) => acc + ((doc.data() as Map<String, dynamic>)['rating'] as num? ?? 0).toDouble(),
    );
    final avg = (total / snap.docs.length * 10).round() / 10;
    return {'avgRating': avg, 'reviewCount': snap.docs.length};
  }

  @override
  Future<List<ReviewModel>> fetchReviews(String restaurantId, {int limit = 20}) async {
    final snap = await _reviewsCol(restaurantId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(ReviewModel.fromFirestore).toList();
  }

  @override
  Future<void> submitReview(ReviewModel review) async {
    // 1. Write the review document
    final reviewRef = _reviewsCol(review.restaurantId).doc();
    await reviewRef.set(review.toFirestore());

    // 2. Recompute avg rating and update restaurant doc
    final stats = await _computeRatingStats(review.restaurantId);
    await _restaurantRef(review.restaurantId).update(stats);

    // 3. Award +5 score to the restaurant's contributor (real users only)
    final restaurantDoc = await _restaurantRef(review.restaurantId).get();
    final data = restaurantDoc.data() as Map<String, dynamic>?;
    final contributorId = data?['contributorId'] as String?;
    if (contributorId != null &&
        contributorId.isNotEmpty &&
        !contributorId.startsWith('seed:')) {
      await _db.runTransaction((tx) async {
        final userSnap = await tx.get(_userRef(contributorId));
        final currentScore = (userSnap.data() as Map<String, dynamic>?)?['score'] as int? ?? 0;
        final newScore = currentScore + 5;
        final newTier = _tierForScore(newScore);
        tx.set(
          _userRef(contributorId),
          {'score': newScore, 'tier': newTier},
          SetOptions(merge: true),
        );
      });
    }
  }

  @override
  Future<void> editReview({
    required String restaurantId,
    required String reviewId,
    required String text,
    required double rating,
  }) async {
    // 1. Update the review text & rating
    await _reviewsCol(restaurantId).doc(reviewId).update({
      'text': text,
      'rating': rating,
    });

    // 2. Recompute avg rating after edit
    final stats = await _computeRatingStats(restaurantId);
    await _restaurantRef(restaurantId).update(stats);
  }

  @override
  Future<void> deleteReview({
    required String restaurantId,
    required String reviewId,
  }) async {
    // 1. Delete the review
    await _reviewsCol(restaurantId).doc(reviewId).delete();

    // 2. Recompute avg rating after deletion
    final stats = await _computeRatingStats(restaurantId);
    await _restaurantRef(restaurantId).update(stats);
  }

  @override
  Future<void> upvoteReview({
    required String restaurantId,
    required String reviewId,
    required String uid,
  }) async {
    final ref = _reviewsCol(restaurantId).doc(reviewId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() as Map<String, dynamic>?;
      final liked = List<String>.from(data?['likedBy'] ?? []);
      if (liked.contains(uid)) return; // already liked — no-op
      tx.update(ref, {
        'upvotes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([uid]),
      });
    });
  }

  @override
  Future<String?> fetchTranslation({
    required String restaurantId,
    required String reviewId,
    required String targetLang,
  }) async {
    final doc = await _reviewsCol(restaurantId)
        .doc(reviewId)
        .collection(AppConstants.kColTranslations)
        .doc(targetLang)
        .get();
    return doc.data()?['translatedText'] as String?;
  }

  @override
  Future<void> cacheTranslation({
    required String restaurantId,
    required String reviewId,
    required String targetLang,
    required String translatedText,
  }) async {
    await _reviewsCol(restaurantId)
        .doc(reviewId)
        .collection(AppConstants.kColTranslations)
        .doc(targetLang)
        .set({
      'translatedText': translatedText,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
