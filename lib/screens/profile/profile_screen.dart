import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/saved_places_provider.dart';
import '../../core/constants/route_names.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<UserProvider>().loadUser(auth.user!.uid);
        context.read<SavedPlacesProvider>().loadSaved(auth.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final savedCount = context.watch<SavedPlacesProvider>().savedIds.length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, user, savedCount)),
          SliverToBoxAdapter(child: _buildStats(user, savedCount)),
          SliverToBoxAdapter(child: _buildPassport()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, int savedCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Row(
        children: [
          const StripeTile(
            color: AppColors.terracotta,
            width: 56, height: 56,
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Explorer',
                  style: GoogleFonts.fraunces(
                      fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                Text('@local · DiningAtlas',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _tierColor(user?.tier ?? 'explorer').withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _tierColor(user?.tier ?? 'explorer').withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _tierLabel(user?.tier ?? 'explorer').toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _tierColor(user?.tier ?? 'explorer'),
                        letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.ink),
            onPressed: () => Navigator.pushNamed(context, RouteNames.kSettings),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(dynamic user, int savedCount) {
    final stats = [
      ('${user?.score ?? 0}', 'SCORE'),
      ('$savedCount', 'SAVED'),
      ('0', 'REVIEWS'),
      ('1', 'CITIES'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Column(
              children: [
                Text(s.$1,
                    style: GoogleFonts.fraunces(
                        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(s.$2,
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warmGrey,
                        letterSpacing: 1.1)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPassport() {
    final cities = ['🇯🇵 Tokyo', '🇵🇹 Lisbon', '🇲🇽 CDMX', '🇹🇭 Bangkok', '🇮🇹 Rome'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: SectionLabel('Dining Passport'),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: cities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.lightGrey),
              ),
              child: Text(cities[i],
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink)),
            ),
          ),
        ),
      ],
    );
  }

  String _tierLabel(String tier) => switch (tier) {
    'local' => 'Local',
    'super_local' => 'Super Local',
    'city_legend' => 'City Legend',
    _ => 'Explorer',
  };

  Color _tierColor(String tier) => switch (tier) {
    'local' => AppColors.teal,
    'super_local' => AppColors.terracotta,
    'city_legend' => AppColors.gold,
    _ => AppColors.warmGrey,
  };
}
