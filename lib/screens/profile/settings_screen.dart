import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../core/constants/route_names.dart';

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
          const _SectionHeader(title: 'Chat Privacy'),
          RadioGroup<String>(
            groupValue: currentMode,
            onChanged: (v) => _updateChatMode(context, v!, user),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text('Public — Anyone can message me',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink)),
                  value: 'public',
                  activeColor: AppColors.terracotta,
                ),
                RadioListTile<String>(
                  title: Text('Private — No messages',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink)),
                  value: 'private',
                  activeColor: AppColors.terracotta,
                ),
                RadioListTile<String>(
                  title: Text('Scheduled — Set availability hours',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink)),
                  value: 'scheduled',
                  activeColor: AppColors.terracotta,
                ),
              ],
            ),
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
              await context.read<AuthProvider>().signOut();
              navigator.pushNamedAndRemoveUntil(RouteNames.kLogin, (_) => false);
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
