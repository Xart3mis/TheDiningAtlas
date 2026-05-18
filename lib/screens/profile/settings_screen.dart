import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
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
    final currentMode = user?.chatPrivacy.mode ?? 'public';

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
          const _SectionHeader(title: 'Chat Privacy'),
          RadioListTile<String>(
            title: Text('Public — Anyone can message me',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink)),
            value: 'public',
            groupValue: currentMode,
            activeColor: AppColors.terracotta,
            onChanged: (v) => _updateChatMode(context, v!, user),
          ),
          RadioListTile<String>(
            title: Text('Private — No messages',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink)),
            value: 'private',
            groupValue: currentMode,
            activeColor: AppColors.terracotta,
            onChanged: (v) => _updateChatMode(context, v!, user),
          ),
          RadioListTile<String>(
            title: Text('Scheduled — Set availability hours',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink)),
            value: 'scheduled',
            groupValue: currentMode,
            activeColor: AppColors.terracotta,
            onChanged: (v) => _updateChatMode(context, v!, user),
          ),

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
              // Reset all user-scoped state BEFORE sign-out
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

  void _updateChatMode(BuildContext context, String mode, UserModel? user) {
    if (user == null) return;
    context.read<UserProvider>().updateChatPrivacy(ChatPrivacy(mode: mode));
  }
}

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
