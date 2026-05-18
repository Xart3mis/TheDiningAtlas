import 'package:flutter/material.dart';
import '../services/interfaces/i_chat_service.dart';
import '../services/interfaces/i_ai_service.dart';
import '../models/chat_model.dart';

class ChatProvider extends ChangeNotifier {
  final IChatService _chatService;
  final IAiService _aiService;
  ChatProvider(this._chatService, this._aiService);

  ChatModel? _currentChat;
  Stream<List<MessageModel>>? _messagesStream;
  final Map<String, String> _translations = {};
  String? _error;

  ChatModel? get currentChat => _currentChat;
  Stream<List<MessageModel>>? get messagesStream => _messagesStream;
  String? get error => _error;
  String? translationFor(String messageId, String lang) => _translations['${messageId}_$lang'];

  Future<void> openChat({required String currentUid, required String otherUid, required String placeId}) async {
    _currentChat = await _chatService.getOrCreateChat(
      currentUid: currentUid, otherUid: otherUid, placeId: placeId,
    );
    _messagesStream = _chatService.messagesStream(_currentChat!.id);
    notifyListeners();
  }

  Future<void> sendMessage({required String senderId, required String text}) async {
    if (_currentChat == null) return;
    await _chatService.sendMessage(chatId: _currentChat!.id, senderId: senderId, text: text);
  }

  Future<void> translateMessage({required String messageId, required String text, required String targetLang}) async {
    final key = '${messageId}_$targetLang';
    if (_translations.containsKey(key)) return;
    if (_currentChat == null) return;
    final cached = await _chatService.fetchMessageTranslation(
      chatId: _currentChat!.id, messageId: messageId, targetLang: targetLang,
    );
    if (cached != null) { _translations[key] = cached; notifyListeners(); return; }
    final translated = await _aiService.translate(text: text, targetLang: targetLang);
    await _chatService.cacheMessageTranslation(
      chatId: _currentChat!.id, messageId: messageId,
      targetLang: targetLang, translatedText: translated,
    );
    _translations[key] = translated;
    notifyListeners();
  }

  void reset() {
    _currentChat = null;
    _messagesStream = null;
    _translations.clear();
    _error = null;
    notifyListeners();
  }
}
