import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) {
        context.read<NotificationProvider>().loadNotifications(uid);
        context.read<NotificationProvider>().clearBadge();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.notifications;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: Text('Notifications',
            style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none_outlined,
                      size: 48, color: AppColors.warmGrey),
                  const SizedBox(height: 12),
                  Text('No notifications yet',
                      style: GoogleFonts.inter(
                          fontSize: 15, color: AppColors.warmGrey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = notifications[i];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.parchment,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      n.type == 'new_review'
                          ? Icons.rate_review_outlined
                          : n.type == 'nearby_saved'
                              ? Icons.location_on_outlined
                              : Icons.chat_bubble_outline,
                      color: AppColors.terracotta,
                      size: 18,
                    ),
                  ),
                  title: Text(n.title,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink)),
                  subtitle: Text(n.body,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.warmGrey)),
                );
              },
            ),
    );
  }
}
