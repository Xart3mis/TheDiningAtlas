import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/saved_places_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/review_provider.dart';
import '../../services/interfaces/i_storage_service.dart';
import '../../models/user_model.dart';
import '../../core/constants/route_names.dart';
import '../../widgets/shared_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final privacy = user?.chatPrivacy ?? const ChatPrivacy(mode: 'public');

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.fraunces(
                fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
        backgroundColor: AppColors.cream,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Profile'),
          _ProfileAvatarTile(user: user),
          _EditFieldTile(
            label: 'Display Name',
            value: user?.displayName ?? '',
            onSave: (val) =>
                context.read<UserProvider>().updateProfile(displayName: val),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
          ),
          _EditFieldTile(
            label: 'Username',
            value: user?.username ?? '',
            prefix: '@',
            onSave: (val) =>
                context.read<UserProvider>().updateProfile(username: val),
            validator: (v) {
              if (v == null || v.trim().length < 3) return 'At least 3 characters';
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                return 'Letters, numbers, and underscores only';
              }
              if (v.trim().length > 20) return 'Max 20 characters';
              return null;
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'Chat'),
          ListTile(
            title: Text('My Chats',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
            subtitle: Text('Chat with locals and AI assistant',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.warmGrey),
            onTap: () {
              if (context.read<AuthProvider>().user == null) {
                Navigator.pushNamed(context, RouteNames.kLogin);
                return;
              }
              Navigator.pushNamed(
                context,
                RouteNames.kChatThread,
                arguments: {
                  'otherUid': 'ai_assistant',
                  'placeId': '',
                  'otherName': 'AI Assistant',
                },
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'Chat Privacy'),
          RadioListTile<String>(
            title: Text('Public — Anyone can message me',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink)),
            value: 'public',
            groupValue: privacy.mode,
            activeColor: AppColors.terracotta,
            onChanged: (v) => _updateChatMode(context, v!, user, privacy),
          ),
          RadioListTile<String>(
            title: Text('Private — No messages',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink)),
            value: 'private',
            groupValue: privacy.mode,
            activeColor: AppColors.terracotta,
            onChanged: (v) => _updateChatMode(context, v!, user, privacy),
          ),
          RadioListTile<String>(
            title: Text('Scheduled — Set availability hours',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink)),
            value: 'scheduled',
            groupValue: privacy.mode,
            activeColor: AppColors.terracotta,
            onChanged: (v) => _updateChatMode(context, v!, user, privacy),
          ),
          if (privacy.mode == 'scheduled')
            _ScheduleEditor(privacy: privacy, user: user),
          const Divider(),
          const _SectionHeader(title: 'Subscription'),
          ListTile(
            title: Text('Upgrade to Premium',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
            subtitle: Text('Unlimited saves, AI features, no ads',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.warmGrey),
            onTap: () => Navigator.pushNamed(context, RouteNames.kPremiumUpgrade),
          ),
          const Divider(),
          const _SectionHeader(title: 'Account'),
          ListTile(
            title: Text('Sign Out',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red)),
            onTap: () async {
              final navigator = Navigator.of(context);
              context.read<UserProvider>().reset();
              context.read<ChatProvider>().reset();
              context.read<SavedPlacesProvider>().reset();
              context.read<TripProvider>().reset();
              context.read<NotificationProvider>().reset();
              context.read<ReviewProvider>().reset();
              await context.read<AuthProvider>().signOut();
              navigator.pushNamedAndRemoveUntil('/', (_) => false);
            },
          ),
        ],
      ),
    );
  }

  void _updateChatMode(
      BuildContext context, String mode, UserModel? user, ChatPrivacy current) {
    if (user == null) return;
    // Keep existing schedule fields when toggling back to 'scheduled'
    context.read<UserProvider>().updateChatPrivacy(ChatPrivacy(
          mode: mode,
          scheduleStart: current.scheduleStart,
          scheduleEnd: current.scheduleEnd,
          scheduleDays: current.scheduleDays,
        ));
  }
}

// ---------------------------------------------------------------------------
// Schedule editor — shown only when mode == 'scheduled'
// ---------------------------------------------------------------------------

class _ScheduleEditor extends StatelessWidget {
  final ChatPrivacy privacy;
  final UserModel? user;

  static const _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  const _ScheduleEditor({required this.privacy, required this.user});

  String _fmt(String? hhmm) {
    if (hhmm == null) return 'Not set';
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1].padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final current = isStart ? privacy.scheduleStart : privacy.scheduleEnd;
    TimeOfDay initial = TimeOfDay.now();
    if (current != null) {
      final p = current.split(':');
      if (p.length == 2) {
        initial = TimeOfDay(
            hour: int.tryParse(p[0]) ?? 0, minute: int.tryParse(p[1]) ?? 0);
      }
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !context.mounted) return;
    final hhmm =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    context.read<UserProvider>().updateChatPrivacy(ChatPrivacy(
          mode: privacy.mode,
          scheduleStart: isStart ? hhmm : privacy.scheduleStart,
          scheduleEnd: isStart ? privacy.scheduleEnd : hhmm,
          scheduleDays: privacy.scheduleDays,
        ));
  }

  void _toggleDay(BuildContext context, String day) {
    final days = List<String>.from(privacy.scheduleDays);
    days.contains(day) ? days.remove(day) : days.add(day);
    context.read<UserProvider>().updateChatPrivacy(ChatPrivacy(
          mode: privacy.mode,
          scheduleStart: privacy.scheduleStart,
          scheduleEnd: privacy.scheduleEnd,
          scheduleDays: days,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time range row
          Row(
            children: [
              Expanded(
                child: _TimeTile(
                  label: 'From',
                  time: _fmt(privacy.scheduleStart),
                  onTap: () => _pickTime(context, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeTile(
                  label: 'Until',
                  time: _fmt(privacy.scheduleEnd),
                  onTap: () => _pickTime(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Day toggles
          Text('Available days',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warmGrey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = _days[i];
              final selected = privacy.scheduleDays.contains(day);
              return GestureDetector(
                onTap: () => _toggleDay(context, day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.terracotta : AppColors.cream,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: selected
                            ? AppColors.terracotta
                            : AppColors.warmGrey.withOpacity(0.4)),
                  ),
                  alignment: Alignment.center,
                  child: Text(_labels[i],
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.ink)),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  const _TimeTile(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warmGrey.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.warmGrey)),
            const SizedBox(height: 2),
            Text(time,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared profile widgets
// ---------------------------------------------------------------------------

class _ProfileAvatarTile extends StatelessWidget {
  final UserModel? user;
  const _ProfileAvatarTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: ClipOval(
          child: user?.photoUrl.isNotEmpty == true
              ? CachedNetworkImage(
                  imageUrl: user!.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const StripeTile(
                      color: AppColors.terracotta,
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.all(Radius.circular(24))),
                  errorWidget: (_, __, ___) => const StripeTile(
                      color: AppColors.terracotta,
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.all(Radius.circular(24))),
                )
              : const StripeTile(
                  color: AppColors.terracotta,
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.all(Radius.circular(24))),
        ),
      ),
      title: Text('Change Photo',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.warmGrey),
      onTap: () async {
        final picker = ImagePicker();
        final picked =
            await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (picked == null || !context.mounted) return;
        final uid = context.read<AuthProvider>().user?.uid;
        if (uid == null) return;
        try {
          final storageService = context.read<IStorageService>();
          final url = await storageService.uploadImage(
            filePath: picked.path,
            storagePath: 'avatars/$uid.jpg',
          );
          if (context.mounted) {
            await context.read<UserProvider>().updateProfile(photoUrl: url);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload photo: $e')),
            );
          }
        }
      },
    );
  }
}

class _EditFieldTile extends StatelessWidget {
  final String label;
  final String value;
  final String? prefix;
  final Future<void> Function(String) onSave;
  final String? Function(String?)? validator;

  const _EditFieldTile({
    required this.label,
    required this.value,
    this.prefix,
    required this.onSave,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink)),
      subtitle: Text(
        value.isEmpty ? 'Not set' : (prefix != null ? '$prefix$value' : value),
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.warmGrey),
      onTap: () => _showEditDialog(context),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: value);
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $label',
            style: GoogleFonts.fraunces(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              prefixText: prefix,
              border: const OutlineInputBorder(),
            ),
            validator: validator,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                await onSave(controller.text.trim());
              }
            },
            child: Text('Save',
                style: GoogleFonts.inter(color: AppColors.terracotta)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.warmGrey,
              letterSpacing: 1.1)),
    );
  }
}
