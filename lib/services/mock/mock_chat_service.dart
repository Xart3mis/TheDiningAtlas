import '../interfaces/i_chat_service.dart';
import '../../models/chat_model.dart';

class MockChatService implements IChatService {
  final _messages = <String, List<MessageModel>>{};

  @override
  Future<ChatModel> getOrCreateChat({required String currentUid, required String otherUid, required String placeId}) async {
    return ChatModel(id: 'mock_chat_1', participantUids: [currentUid, otherUid],
        relatedPlaceId: placeId, lastMessage: '', lastUpdated: DateTime.now());
  }

  @override
  Stream<List<MessageModel>> messagesStream(String chatId) {
    return Stream.value(_messages[chatId] ?? []);
  }

  @override
  Future<void> sendMessage({required String chatId, required String senderId, required String text}) async {
    _messages.putIfAbsent(chatId, () => []).add(MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}', chatId: chatId,
      senderId: senderId, text: text, status: 'sent', createdAt: DateTime.now(),
    ));
  }

  @override
  Future<List<ChatModel>> fetchUserChats(String uid) async => [];

  @override
  Future<String?> fetchMessageTranslation({required String chatId, required String messageId, required String targetLang}) async => null;

  @override
  Future<void> cacheMessageTranslation({required String chatId, required String messageId, required String targetLang, required String translatedText}) async {}
}
