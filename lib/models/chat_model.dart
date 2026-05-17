import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      text: d['text'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'text': text,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
