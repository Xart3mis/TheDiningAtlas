import 'package:flutter/material.dart';
import '../services/interfaces/i_chat_service.dart';
import '../services/interfaces/i_ai_service.dart';
import '../services/interfaces/i_notification_service.dart';
import '../services/interfaces/i_user_service.dart';
import '../models/chat_model.dart';

class ChatProvider extends ChangeNotifier {
  final IChatService _chatService;
  final IAiService _aiService;
  final INotificationService _notificationService;
  final IUserService _userService;

  ChatProvider(
    this._chatService,
    this._aiService,
    this._notificationService,
    this._userService,
  );

  ChatModel? _currentChat;
  Stream<List<MessageModel>>? _messagesStream;
  final Map<String, String> _translations = {};
  String? _error;

  // Display name of the current user — set when opening a chat so we can
  // include it in push notifications without an extra Firestore read per send.
  String _currentUserName = 'Someone';

  ChatModel? get currentChat => _currentChat;
  Stream<List<MessageModel>>? get messagesStream => _messagesStream;
  String? get error => _error;
  String? translationFor(String messageId, String lang) =>
      _translations['${messageId}_$lang'];

  Future<void> openChat({
    required String currentUid,
    required String otherUid,
    required String placeId,
    String? currentUserName,
  }) async {
    if (currentUserName != null) _currentUserName = currentUserName;
    _currentChat = await _chatService.getOrCreateChat(
      currentUid: currentUid,
      otherUid: otherUid,
      placeId: placeId,
    );
    _messagesStream = _chatService.messagesStream(_currentChat!.id);
    notifyListeners();
  }

  Future<void> sendMessage({
    required String senderId,
    required String text,
  }) async {
    if (_currentChat == null) return;
    await _chatService.sendMessage(
      chatId: _currentChat!.id,
      senderId: senderId,
      text: text,
    );

    // Notify the other participant
    final recipientUid = _currentChat!.participantUids
        .firstWhere((uid) => uid != senderId, orElse: () => '');
    if (recipientUid.isNotEmpty) {
      _sendChatPushNotification(
        recipientUid: recipientUid,
        senderName: _currentUserName,
        messagePreview: text.length > 80 ? '${text.substring(0, 80)}…' : text,
        chatId: _currentChat!.id,
      );
    }
  }

  // Fire-and-forget — notification failure must never block the send flow.
  void _sendChatPushNotification({
    required String recipientUid,
    required String senderName,
    required String messagePreview,
    required String chatId,
  }) {
    _notificationService
        .sendChatNotification(
          recipientUid: recipientUid,
          senderName: senderName,
          messagePreview: messagePreview,
          chatId: chatId,
        )
        .catchError((_) {});
  }

  Future<void> translateMessage({
    required String messageId,
    required String text,
    required String targetLang,
  }) async {
    final key = '${messageId}_$targetLang';
    if (_translations.containsKey(key)) return;
    if (_currentChat == null) return;
    final cached = await _chatService.fetchMessageTranslation(
      chatId: _currentChat!.id,
      messageId: messageId,
      targetLang: targetLang,
    );
    if (cached != null) {
      _translations[key] = cached;
      notifyListeners();
      return;
    }
    final translated =
        await _aiService.translate(text: text, targetLang: targetLang);
    await _chatService.cacheMessageTranslation(
      chatId: _currentChat!.id,
      messageId: messageId,
      targetLang: targetLang,
      translatedText: translated,
    );
    _translations[key] = translated;
    notifyListeners();
  }

  void reset() {
    _currentChat = null;
    _messagesStream = null;
    _translations.clear();
    _error = null;
    _currentUserName = 'Someone';
    notifyListeners();
  }
}
