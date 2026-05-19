import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../services/interfaces/i_user_service.dart';

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
  ChatPrivacy? _otherPrivacy;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid == null) return;

      // Load recipient privacy, current user profile, and open chat together
      final userService = context.read<IUserService>();
      final results = await Future.wait([
        userService.fetchUser(widget.otherUid),
        userService.fetchUser(uid),
      ]);
      if (!mounted) return;
      final currentUser = results[1];
      await context.read<ChatProvider>().openChat(
            currentUid: uid,
            otherUid: widget.otherUid,
            placeId: widget.placeId,
            currentUserName: currentUser?.displayName,
          );

      if (!mounted) return;
      final otherUser = results[0] as UserModel?;
      setState(() {
        _otherPrivacy = otherUser?.chatPrivacy;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Returns null when messaging is allowed, or a human-readable reason when blocked.
  String? _blockedReason() {
    final privacy = _otherPrivacy;
    if (privacy == null) return null; // still loading — optimistically allow
    switch (privacy.mode) {
      case 'private':
        return '${widget.otherName} is not accepting messages right now.';
      case 'scheduled':
        if (!_isWithinSchedule(privacy)) {
          final start = _fmtTime(privacy.scheduleStart);
          final end = _fmtTime(privacy.scheduleEnd);
          final days = _fmtDays(privacy.scheduleDays);
          return '${widget.otherName} only accepts messages $days, $start – $end.';
        }
        return null;
      default:
        return null;
    }
  }

  bool _isWithinSchedule(ChatPrivacy privacy) {
    final now = DateTime.now();
    final dayKey = const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
        [now.weekday - 1]; // DateTime.monday == 1
    if (privacy.scheduleDays.isNotEmpty &&
        !privacy.scheduleDays.contains(dayKey)) {
      return false;
    }
    final start = _parseHhmm(privacy.scheduleStart);
    final end = _parseHhmm(privacy.scheduleEnd);
    if (start == null || end == null) return true; // times not configured yet
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start[0] * 60 + start[1];
    final endMinutes = end[0] * 60 + end[1];
    if (endMinutes > startMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
    // Overnight window (e.g. 22:00 – 02:00)
    return nowMinutes >= startMinutes || nowMinutes < endMinutes;
  }

  List<int>? _parseHhmm(String? hhmm) {
    if (hhmm == null) return null;
    final p = hhmm.split(':');
    if (p.length != 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return [h, m];
  }

  String _fmtTime(String? hhmm) {
    final p = _parseHhmm(hhmm);
    if (p == null) return '?';
    final h = p[0];
    final m = p[1].toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  String _fmtDays(List<String> days) {
    if (days.isEmpty) return 'every day';
    const labels = {
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
    };
    return days.map((d) => labels[d] ?? d).join(', ');
  }

  void _send() {
    if (_blockedReason() != null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final isGuest = auth.user == null;
    context
        .read<ChatProvider>()
        .sendMessage(senderId: isGuest ? 'guest_user' : auth.user!.uid, text: text);
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
    final isGuest = auth.user == null;
    final myUid = isGuest ? 'guest_user' : auth.user!.uid;
    final blockedReason = _blockedReason();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherName,
                style: GoogleFonts.fraunces(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
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
                          return _MessageBubble(
                            message: msg,
                            isMe: msg.senderId == myUid,
                          );
                        },
                      );
                    },
                  ),
          ),
          if (blockedReason != null)
            _PrivacyBanner(reason: blockedReason)
          else
            _ChatInputBar(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PrivacyBanner extends StatelessWidget {
  final String reason;
  const _PrivacyBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppColors.warmGrey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(reason,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.warmGrey)),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final locale = Localizations.localeOf(context).languageCode;
    final translation = chatProvider.translationFor(message.id, locale);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            constraints:
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.terracotta : AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Divider(color: Colors.white24, height: 1),
                  ),
                  Text(translation,
                      style: GoogleFonts.inter(
                          color: isMe ? Colors.white70 : AppColors.warmGrey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          if (!isMe && translation == null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: GestureDetector(
                onTap: () => chatProvider.translateMessage(
                  messageId: message.id,
                  text: message.text,
                  targetLang: locale,
                ),
                child: Text('Translate',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600)),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
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
