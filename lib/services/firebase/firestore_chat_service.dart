import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_chat_service.dart';
import '../../models/chat_model.dart';
import '../../core/constants/app_constants.dart';

class FirestoreChatService implements IChatService {
  final _db = FirebaseFirestore.instance;

  @override
  Future<ChatModel> getOrCreateChat({required String currentUid, required String otherUid, required String placeId}) async {
    final participants = [currentUid, otherUid]..sort();
    final existing = await _db.collection(AppConstants.kColChats)
        .where('participants', isEqualTo: participants)
        .where('relatedPlaceId', isEqualTo: placeId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return ChatModel.fromFirestore(existing.docs.first);

    final ref = await _db.collection(AppConstants.kColChats).add({
      'participants': participants,
      'relatedPlaceId': placeId,
      'lastMessage': '',
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    final doc = await ref.get();
    return ChatModel.fromFirestore(doc);
  }

  @override
  Stream<List<MessageModel>> messagesStream(String chatId) {
    return _db
        .collection(AppConstants.kColChats)
        .doc(chatId)
        .collection(AppConstants.kColMessages)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());
  }

  @override
  Future<void> sendMessage({required String chatId, required String senderId, required String text}) async {
    final batch = _db.batch();
    final msgRef = _db
        .collection(AppConstants.kColChats)
        .doc(chatId)
        .collection(AppConstants.kColMessages)
        .doc();
    batch.set(msgRef, MessageModel(
      id: msgRef.id, chatId: chatId, senderId: senderId,
      text: text, status: 'sent', createdAt: DateTime.now(),
    ).toFirestore());
    batch.update(_db.collection(AppConstants.kColChats).doc(chatId), {
      'lastMessage': text, 'lastUpdated': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<List<ChatModel>> fetchUserChats(String uid) async {
    final snap = await _db.collection(AppConstants.kColChats)
        .where('participants', arrayContains: uid)
        .orderBy('lastUpdated', descending: true)
        .get();
    return snap.docs.map(ChatModel.fromFirestore).toList();
  }

  @override
  Future<String?> fetchMessageTranslation({required String chatId, required String messageId, required String targetLang}) async {
    final doc = await _db
        .collection(AppConstants.kColChats).doc(chatId)
        .collection(AppConstants.kColMessages).doc(messageId)
        .collection(AppConstants.kColTranslations).doc(targetLang).get();
    if (!doc.exists) return null;
    return (doc.data() as Map<String, dynamic>)['translatedText'] as String?;
  }

  @override
  Future<void> cacheMessageTranslation({required String chatId, required String messageId, required String targetLang, required String translatedText}) async {
    await _db
        .collection(AppConstants.kColChats).doc(chatId)
        .collection(AppConstants.kColMessages).doc(messageId)
        .collection(AppConstants.kColTranslations).doc(targetLang)
        .set({'translatedText': translatedText, 'cachedAt': FieldValue.serverTimestamp()});
  }
}
