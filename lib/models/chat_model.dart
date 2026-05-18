import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participantUids;
  final String relatedPlaceId;
  final String lastMessage;
  final DateTime lastUpdated;

  const ChatModel({
    required this.id,
    required this.participantUids,
    required this.relatedPlaceId,
    required this.lastMessage,
    required this.lastUpdated,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participantUids: List<String>.from(d['participants'] ?? []),
      relatedPlaceId: d['relatedPlaceId'] ?? '',
      lastMessage: d['lastMessage'] ?? '',
      lastUpdated: (d['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String status; // 'sent' | 'delivered' | 'read'
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.status,
    required this.createdAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: d['chatId'] ?? '',
      senderId: d['senderId'] ?? '',
      text: d['text'] ?? '',
      status: d['status'] ?? 'sent',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'chatId': chatId,
    'senderId': senderId,
    'text': text,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
