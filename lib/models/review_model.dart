import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String restaurantId;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String text;
  final double rating;
  final int upvotes;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.restaurantId,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.text,
    required this.rating,
    required this.upvotes,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      restaurantId: d['restaurantId'] ?? '',
      authorId: d['authorId'] ?? '',
      authorName: d['authorName'] ?? '',
      authorPhotoUrl: d['authorPhotoUrl'] ?? '',
      text: d['text'] ?? '',
      rating: (d['rating'] ?? 0.0).toDouble(),
      upvotes: d['upvotes'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'restaurantId': restaurantId,
    'authorId': authorId,
    'authorName': authorName,
    'authorPhotoUrl': authorPhotoUrl,
    'text': text,
    'rating': rating,
    'upvotes': upvotes,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
