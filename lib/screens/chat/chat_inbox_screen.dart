import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/interfaces/i_chat_service.dart';
import '../../services/interfaces/i_user_service.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../core/constants/route_names.dart';
import '../../core/service_provider.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  List<_ConversationRow>? _rows;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!mounted) return;
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) {
      setState(() { _loading = false; });
      return;
    }
    try {
      final chatService = context.read<IChatService>();
      final userService = context.read<IUserService>();
      final chats = await chatService.fetchUserChats(uid);
      final rows = <_ConversationRow>[];
      for (final chat in chats) {
        final otherUid = chat.participantUids.firstWhere(
          (id) => id != uid,
          orElse: () => '',
        );
        if (otherUid.isEmpty) continue;
        final other = await userService.fetchUser(otherUid);
        rows.add(_ConversationRow(chat: chat, otherUid: otherUid, otherName: other?.displayName ?? 'User'));
      }
      if (!mounted) return;
      setState(() { _rows = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Text('Messages',
            style: GoogleFonts.fraunces(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, RouteNames.kUserSearch)
                  .then((_) => _load()),
              backgroundColor: AppColors.terracotta,
              child: const Icon(Icons.edit_outlined, color: Colors.white),
            ),
      body: uid == null
          ? _buildUnauthenticated()
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError()
                  : _rows == null || _rows!.isEmpty
                      ? _buildEmpty()
                      : _buildList(),
    );
  }

  Widget _buildUnauthenticated() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppColors.warmGrey),
            const SizedBox(height: 12),
            Text('Sign in to view messages',
                style: GoogleFonts.inter(color: AppColors.warmGrey, fontSize: 15)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, RouteNames.kLogin),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
              child: Text('Sign in', style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.warmGrey),
            const SizedBox(height: 12),
            Text('No conversations yet',
                style: GoogleFonts.fraunces(fontSize: 18, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text('Tap + to message someone',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.warmGrey)),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load messages',
                style: GoogleFonts.inter(color: AppColors.warmGrey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
              child: Text('Retry', style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        ),
      );

  Widget _buildList() {
    final uid = context.read<AuthProvider>().user!.uid;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _rows!.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) {
          final row = _rows![i];
          return _InboxTile(
            row: row,
            onTap: () => Navigator.pushNamed(
              context,
              RouteNames.kChatThread,
              arguments: {
                'otherUid': row.otherUid,
                'placeId': row.chat.relatedPlaceId,
                'otherName': row.otherName,
              },
            ).then((_) => _load()),
          );
        },
      ),
    );
  }
}

class _ConversationRow {
  final ChatModel chat;
  final String otherUid;
  final String otherName;
  const _ConversationRow({required this.chat, required this.otherUid, required this.otherName});
}

class _InboxTile extends StatelessWidget {
  final _ConversationRow row;
  final VoidCallback onTap;
  const _InboxTile({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = row.otherName.isNotEmpty ? row.otherName[0].toUpperCase() : '?';
    final ts = _formatTime(row.chat.lastUpdated);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.terracotta,
        child: Text(initials,
            style: GoogleFonts.fraunces(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      title: Text(row.otherName,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.ink, fontSize: 15)),
      subtitle: Text(
        row.chat.lastMessage.isEmpty ? 'No messages yet' : row.chat.lastMessage,
        style: GoogleFonts.inter(color: AppColors.warmGrey, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(ts, style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }
}
