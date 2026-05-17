import 'package:flutter/material.dart';
import '../models/chat_model.dart';

class ChatProvider extends ChangeNotifier {
  Stream<List<MessageModel>>? _messagesStream;
  final Map<String, Map<String, String>> _translations = {};
  final List<MessageModel> _mockMessages = [];

  Stream<List<MessageModel>>? get messagesStream => _messagesStream;

  String? translationFor(String messageId, String lang) =>
      _translations[messageId]?[lang];

  void openChat({
    required String currentUid,
    required String otherUid,
    required String placeId,
  }) {
    _messagesStream = Stream.value([
      MessageModel(
        id: 'm1',
        senderId: otherUid,
        text: 'Hey! Happy to answer questions about this place.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ]).asBroadcastStream();
    notifyListeners();
  }

  Future<void> sendMessage({required String senderId, required String text}) async {
    final msg = MessageModel(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
    );
    _mockMessages.add(msg);
    notifyListeners();
  }

  Future<void> translateMessage({
    required String messageId,
    required String text,
    required String targetLang,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _translations[messageId] = {targetLang: '[Translated] $text'};
    notifyListeners();
  }
}
