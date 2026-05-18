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
import '../../models/restaurant_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();
      final savedProvider = context.read<SavedPlacesProvider>();
      if (auth.user != null) {
        final uid = auth.user!.uid;
        await userProvider.loadUser(uid);
        if (mounted) await savedProvider.loadSaved(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final savedProvider = context.watch<SavedPlacesProvider>();
    final savedRestaurants = savedProvider.savedRestaurants;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: _buildHeader(context, user, savedRestaurants.length)),
          SliverToBoxAdapter(
              child: _buildStats(user, savedRestaurants.length, savedProvider.uniqueCityCount)),
          SliverToBoxAdapter(
              child: _buildPassport(savedProvider, savedRestaurants)),
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
              child: user?.photoUrl.isNotEmpty == true
                  ? CachedNetworkImage(
                      imageUrl: user!.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const StripeTile(
                          color: AppColors.terracotta,
                          width: 56,
                          height: 56,
                          borderRadius: BorderRadius.all(Radius.circular(28))),
                      errorWidget: (_, __, ___) => const StripeTile(
                          color: AppColors.terracotta,
                          width: 56,
                          height: 56,
                          borderRadius: BorderRadius.all(Radius.circular(28))),
                    )
                  : const StripeTile(
                      color: AppColors.terracotta,
                      width: 56,
                      height: 56,
                      borderRadius: BorderRadius.all(Radius.circular(28))),
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
                        user.displayName.isNotEmpty ? user.displayName : 'Explorer',
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
                                fontSize: 12, color: AppColors.warmGrey),
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
                          color: _tierColor(user.tier).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _tierColor(user.tier).withOpacity(0.3)),
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
            onPressed: () => Navigator.pushNamed(context, RouteNames.kSettings),
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
                  color: Colors.white, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }

  Widget _buildStats(UserModel? user, int savedCount, int cityCount) {
    final stats = [
      ('${user?.score ?? 0}', 'SCORE'),
      ('$savedCount', 'SAVED'),
      ('$cityCount', 'CITIES'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.6)),
      ),
      child: Row(
        children: stats.map((s) {
          final col = Column(
            children: [
              Text(s.$1,
                  style: GoogleFonts.fraunces(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(s.$2,
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warmGrey,
                      letterSpacing: 1.1)),
            ],
          );
          if (s.$2 == 'SAVED') {
            return Expanded(
              child: GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.kSavedPlaces),
                child: col,
              ),
            );
          }
          return Expanded(child: col);
        }).toList(),
      ),
    );
  }

  Widget _buildPassport(SavedPlacesProvider savedProvider, List<RestaurantModel> restaurants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: SectionLabel('Dining Passport'),
        ),
        if (savedProvider.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (restaurants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Save places to build your passport.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.warmGrey),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: restaurants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final r = restaurants[i];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(
                      context, RouteNames.kRestaurantDetail,
                      arguments: r),
                  child: Container(
                    width: 140,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.lightGrey.withOpacity(0.6)),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 68,
                          width: 140,
                          child: r.mediaUrls.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: r.mediaUrls.first,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      Container(color: r.tileColor),
                                )
                              : Container(color: r.tileColor),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                          child: Text(r.name,
                              style: GoogleFonts.fraunces(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
                          child: Text(r.category,
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: AppColors.warmGrey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
