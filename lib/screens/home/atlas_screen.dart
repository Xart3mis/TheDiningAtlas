import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/seed_data_provider.dart';
import '../../models/restaurant_model.dart';
import '../../models/seed_data_model.dart';
import '../../models/user_model.dart';
import '../../core/constants/route_names.dart';
import '../../core/constants/app_constants.dart';
// TODO(Task 7): move MainShell to its own file (lib/shell/main_shell.dart) and update import
import '../../main.dart' show MainShell;

class AtlasScreen extends StatefulWidget {
  const AtlasScreen({super.key});

  @override
  State<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends State<AtlasScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final seedProvider = context.read<SeedDataProvider>();
      final user = context.read<UserProvider>().user;
      final onboarding = context.read<OnboardingProvider>();
      final countryId = (user?.onboardingCountryId.isNotEmpty == true)
          ? user!.onboardingCountryId
          : onboarding.countryId;
      await seedProvider.load();
      if (!mounted) return;
      final countryCities = seedProvider.citiesForCountry(countryId);
      final defaultCity = countryCities.isEmpty ? null : countryCities.first;
      if (defaultCity != null) {
        seedProvider.loadCityDetails(defaultCity.id);
        context.read<RestaurantProvider>().loadFeed(cityId: defaultCity.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = context.watch<RestaurantProvider>();
    final onboardingProvider = context.watch<OnboardingProvider>();
    final seedProvider = context.watch<SeedDataProvider>();
    final user = context.watch<UserProvider>().user;

    final countryId = (user?.onboardingCountryId.isNotEmpty == true)
        ? user!.onboardingCountryId
        : onboardingProvider.countryId;
    final countryCities = seedProvider.citiesForCountry(countryId);
    final effectiveCountryCode = countryCities.isNotEmpty
        ? countryCities.first.countryCode
        : onboardingProvider.countryCode;
    final effectiveCountryName = countryCities.isNotEmpty
        ? countryCities.first.country
        : onboardingProvider.countryName;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(user)),
          SliverToBoxAdapter(child: _buildSearchBanner(effectiveCountryName)),
          SliverToBoxAdapter(
              child: _buildExploreWidget(effectiveCountryCode,
                  effectiveCountryName, countryCities.length)),
          SliverToBoxAdapter(
              child: _buildCityChips(restaurantProvider, countryCities)),
          SliverToBoxAdapter(child: _buildEditorPicksHeader()),
          if (restaurantProvider.isLoading)
            const SliverToBoxAdapter(child: _FeedShimmer())
          else if (restaurantProvider.feed.isEmpty)
            const SliverToBoxAdapter(
                child: SizedBox(
                    height: 120,
                    child: Center(
                        child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No places found.')))))
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 152,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  scrollDirection: Axis.horizontal,
                  itemCount: restaurantProvider.feed.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) =>
                      _EditorPickCard(restaurant: restaurantProvider.feed[i]),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(UserModel? user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.language_outlined,
                  size: 22, color: AppColors.ink),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.fraunces(
                      fontSize: 17,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600),
                  children: [
                    const TextSpan(text: 'The '),
                    TextSpan(
                      text: 'Dining',
                      style: GoogleFonts.fraunces(
                          fontStyle: FontStyle.italic, color: AppColors.ink),
                    ),
                    const TextSpan(text: ' Atlas'),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Map button
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.kMapSearch),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.parchment,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: const Icon(Icons.map_outlined,
                      size: 18, color: AppColors.ink),
                ),
              ),
              // TODO(Task 7): insert chat icon here
              // Avatar / profile
              GestureDetector(
                onTap: () => MainShell.switchTab(5),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: ClipOval(
                    child: user?.photoUrl.isNotEmpty == true
                        ? CachedNetworkImage(
                            imageUrl: user!.photoUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const StripeTile(
                              color: AppColors.terracotta,
                              width: 36,
                              height: 36,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(18)),
                            ),
                            errorWidget: (_, __, ___) => const StripeTile(
                              color: AppColors.terracotta,
                              width: 36,
                              height: 36,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(18)),
                            ),
                          )
                        : const StripeTile(
                            color: AppColors.terracotta,
                            width: 36,
                            height: 36,
                            borderRadius:
                                BorderRadius.all(Radius.circular(18)),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBanner(String countryName) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteNames.kSearch),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Search $countryName…',
                  style:
                      GoogleFonts.inter(fontSize: 14, color: Colors.white54)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.terracotta,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('SEARCH',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreWidget(
      String countryCode, String countryName, int cityCount) {
    return GestureDetector(
      onTap: () => _showDestinationPicker(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGrey.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.parchment,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lightGrey),
              ),
              alignment: Alignment.center,
              child: Text(countryCode,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(countryName,
                      style: GoogleFonts.fraunces(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  Text('$cityCount cities · Restaurants & Hidden Gems',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.warmGrey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.terracotta.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.terracotta.withOpacity(0.3)),
              ),
              child: Text('Change',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.terracotta,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDestinationPicker(BuildContext context) async {
    final seedProvider = context.read<SeedDataProvider>();
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();
    final restaurantProvider = context.read<RestaurantProvider>();

    await seedProvider.load();
    if (!mounted) return;

    // Build unique country list from seed data
    // countryId stored as country name (matches citiesForCountry lookup)
    final cities = seedProvider.cities;
    final seen = <String>{};
    final countries = <({String code, String id, String name})>[];
    for (final city in cities) {
      if (seen.add(city.country)) {
        countries.add((code: city.countryCode, id: city.country, name: city.country));
      }
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Change Destination',
                  style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 16),
              ...countries.map((c) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.parchment,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(c.code,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                ),
                title: Text(c.name,
                    style: GoogleFonts.inter(fontSize: 15, color: AppColors.ink)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final uid = authProvider.user?.uid;
                  if (uid != null) {
                    await userProvider.updateCountry(uid, c.id);
                  }
                  if (!mounted) return;
                  final countryCities = seedProvider.citiesForCountry(c.id);
                  if (countryCities.isNotEmpty) {
                    seedProvider.loadCityDetails(countryCities.first.id);
                    restaurantProvider.loadFeed(cityId: countryCities.first.id);
                  }
                },
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCityChips(
      RestaurantProvider provider, List<SeedCityModel> cities) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: cities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => AtlasPill(
          label: cities[i].name,
          selected: provider.currentCityId == cities[i].id,
          onTap: () {
            context.read<SeedDataProvider>().loadCityDetails(cities[i].id);
            provider.loadFeed(cityId: cities[i].id);
          },
        ),
      ),
    );
  }

  Widget _buildEditorPicksHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SectionLabel("Editor's Picks"),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, RouteNames.kMapSearch),
            child: Text('See all',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.terracotta,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _EditorPickCard extends StatelessWidget {
  final RestaurantModel restaurant;
  const _EditorPickCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteNames.kRestaurantDetail,
          arguments: restaurant),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey.withOpacity(0.6)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 72,
              child: restaurant.mediaUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: restaurant.mediaUrls.first,
                      fit: BoxFit.cover,
                      width: 160,
                      placeholder: (_, __) =>
                          Container(color: restaurant.tileColor),
                      errorWidget: (_, __, ___) =>
                          Container(color: restaurant.tileColor),
                    )
                  : StripeTile(
                      color: restaurant.tileColor,
                      width: 160,
                      height: 72,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name,
                      style: GoogleFonts.fraunces(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${restaurant.category} · ${restaurant.neighborhood}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.warmGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  StarRating(rating: restaurant.avgRating, size: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedShimmer extends StatelessWidget {
  const _FeedShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0D9D0),
      highlightColor: const Color(0xFFF5EFE6),
      child: SizedBox(
        height: 152,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => Container(
            width: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
