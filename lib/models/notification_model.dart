import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String relatedId;
  final DateTime createdAt;
  final bool read;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.relatedId,
    required this.createdAt,
    required this.read,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      type: d['type'] ?? '',
      relatedId: d['relatedId'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: d['read'] ?? false,
    );
  }
}
