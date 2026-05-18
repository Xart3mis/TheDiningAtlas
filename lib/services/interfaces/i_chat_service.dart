import '../../models/chat_model.dart';

abstract class IChatService {
  Future<ChatModel> getOrCreateChat({required String currentUid, required String otherUid, required String placeId});
  Stream<List<MessageModel>> messagesStream(String chatId);
  Future<void> sendMessage({required String chatId, required String senderId, required String text});
  Future<List<ChatModel>> fetchUserChats(String uid);
  Future<String?> fetchMessageTranslation({required String chatId, required String messageId, required String targetLang});
  Future<void> cacheMessageTranslation({required String chatId, required String messageId, required String targetLang, required String translatedText});
}
