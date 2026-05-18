import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/interfaces/i_user_service.dart';
import '../../models/user_model.dart';
import '../../core/constants/route_names.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<UserModel> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() { _results = []; _loading = false; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    final myUid = context.read<AuthProvider>().user?.uid ?? '';
    try {
      final userService = context.read<IUserService>();
      final results = await userService.searchUsers(query: query, excludeUid: myUid);
      if (!mounted) return;
      setState(() { _results = results; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openChat(UserModel other) {
    Navigator.pushNamed(
      context,
      RouteNames.kChatThread,
      arguments: {
        'otherUid': other.uid,
        'placeId': '',
        'otherName': other.displayName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Text('New Message',
            style: GoogleFonts.fraunces(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or username…',
                hintStyle: GoogleFonts.inter(color: AppColors.warmGrey),
                prefixIcon: const Icon(Icons.search, color: AppColors.warmGrey),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(
      child: Text('Error: $_error', style: GoogleFonts.inter(color: AppColors.warmGrey)),
    );
    if (_controller.text.trim().isEmpty) return Center(
      child: Text('Search for someone to message',
          style: GoogleFonts.inter(color: AppColors.warmGrey, fontSize: 14)),
    );
    if (_results.isEmpty) return Center(
      child: Text('No users found',
          style: GoogleFonts.inter(color: AppColors.warmGrey, fontSize: 14)),
    );
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final user = _results[i];
        final initials = user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?';
        return ListTile(
          onTap: () => _openChat(user),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.teal,
            child: Text(initials,
                style: GoogleFonts.fraunces(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          title: Text(user.displayName,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.ink)),
          subtitle: user.username.isNotEmpty
              ? Text('@${user.username}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey))
              : null,
          trailing: _TierBadge(tier: user.tier),
        );
      },
    );
  }
}

class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final label = switch (tier) {
      'city_legend' => 'Legend',
      'super_local' => 'Super Local',
      'local' => 'Local',
      _ => 'Explorer',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.sageGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w600)),
    );
  }
}
