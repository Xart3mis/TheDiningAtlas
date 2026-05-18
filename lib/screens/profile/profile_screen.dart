import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/saved_places_provider.dart';
import '../../models/user_model.dart';
import '../../core/constants/route_names.dart';
import '../../core/constants/app_constants.dart';

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
      if (!mounted) return;
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
          SliverToBoxAdapter(child: _buildPassport(user)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user, int savedCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: ClipOval(
              child: user?.photoUrl?.isNotEmpty == true
                  ? CachedNetworkImage(
                      imageUrl: user!.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const StripeTile(
                          color: AppColors.terracotta,
                          width: 56,
                          height: 56,
                          borderRadius:
                              BorderRadius.all(Radius.circular(28))),
                      errorWidget: (_, __, ___) => const StripeTile(
                          color: AppColors.terracotta,
                          width: 56,
                          height: 56,
                          borderRadius:
                              BorderRadius.all(Radius.circular(28))),
                    )
                  : const StripeTile(
                      color: AppColors.terracotta,
                      width: 56,
                      height: 56,
                      borderRadius:
                          BorderRadius.all(Radius.circular(28))),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: user == null
                ? _buildNameShimmer()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName.isNotEmpty
                            ? user.displayName
                            : 'Explorer',
                        style: GoogleFonts.fraunces(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink),
                      ),
                      Row(
                        children: [
                          Text(
                            '@${user.username.isNotEmpty ? user.username : 'local'}',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.warmGrey),
                          ),
                          if (user.countryCode.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.parchment,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(user.countryCode,
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _tierColor(user.tier)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _tierColor(user.tier)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _tierLabel(user.tier).toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _tierColor(user.tier),
                              letterSpacing: 1.2),
                        ),
                      ),
                    ],
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.ink),
            onPressed: () =>
                Navigator.pushNamed(context, RouteNames.kSettings),
          ),
        ],
      ),
    );
  }

  Widget _buildNameShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0D9D0),
      highlightColor: const Color(0xFFF5EFE6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 120,
              height: 18,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }

  Widget _buildStats(UserModel? user, int savedCount) {
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

  Widget _buildPassport(UserModel? user) {
    if (user == null) return const SizedBox.shrink();

    final countryId = user.onboardingCountryId.trim();
    if (countryId.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: SectionLabel('Dining Passport'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Complete onboarding to unlock your passport',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.warmGrey),
            ),
          ),
        ],
      );
    }

    final country = kSupportedCountries.firstWhere(
      (entry) => entry['id'] == countryId,
      orElse: () => {'name': countryId, 'code': ''},
    );
    final countryName = country['name'] ?? countryId;
    final countryCode = country['code'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: SectionLabel('Dining Passport'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (countryCode.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.parchment,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      countryCode,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  countryName,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
                ),
              ],
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
