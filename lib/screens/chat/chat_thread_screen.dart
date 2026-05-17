import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_model.dart';

class ChatThreadScreen extends StatefulWidget {
  final String otherUid;
  final String placeId;
  final String otherName;
  const ChatThreadScreen({
    super.key,
    required this.otherUid,
    required this.placeId,
    required this.otherName,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = context.read<AuthProvider>();
      context.read<ChatProvider>().openChat(
            currentUid: auth.user!.uid,
            otherUid: widget.otherUid,
            placeId: widget.placeId,
          );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthProvider>();
    context.read<ChatProvider>().sendMessage(senderId: auth.user!.uid, text: text);
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final auth = context.read<AuthProvider>();
    final myUid = auth.user!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherName,
                style: GoogleFonts.fraunces(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
            Text('Local contributor',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.messagesStream == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<MessageModel>>(
                    stream: chatProvider.messagesStream,
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final messages = snap.data!;
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final msg = messages[i];
                          final isMe = msg.senderId == myUid;
                          final translation =
                              chatProvider.translationFor(msg.id, 'en');
                          return _MessageBubble(
                            message: msg,
                            isMe: isMe,
                            translation: translation,
                            onTranslate: () => chatProvider.translateMessage(
                              messageId: msg.id,
                              text: msg.text,
                              targetLang: 'en',
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          _ChatInputBar(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? translation;
  final VoidCallback onTranslate;
  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.translation,
    required this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.terracotta : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text,
                style: GoogleFonts.inter(
                    color: isMe ? Colors.white : AppColors.ink, fontSize: 14)),
            if (translation != null) ...[
              const Divider(height: 12),
              Text(translation!,
                  style: GoogleFonts.inter(
                      color: isMe ? Colors.white70 : AppColors.warmGrey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ] else if (!isMe) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onTranslate,
                child: Text('Translate',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.teal,
                        decoration: TextDecoration.underline)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _ChatInputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Ask the local…',
                hintStyle: GoogleFonts.inter(color: AppColors.warmGrey),
                filled: true,
                fillColor: AppColors.cream,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
