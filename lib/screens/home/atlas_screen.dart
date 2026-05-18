import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../providers/restaurant_provider.dart';
import '../../models/restaurant_model.dart';
import '../../core/constants/route_names.dart';

class AtlasScreen extends StatefulWidget {
  const AtlasScreen({super.key});

  @override
  State<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends State<AtlasScreen> {
  final _cities = [
    {'id': 'tokyo', 'name': 'Tokyo'},
    {'id': 'lisbon', 'name': 'Lisbon'},
    {'id': 'mexico_city', 'name': 'Mexico City'},
    {'id': 'bangkok', 'name': 'Bangkok'},
    {'id': 'rome', 'name': 'Rome'},
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<RestaurantProvider>().loadFeed(cityId: 'tokyo');
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = context.watch<RestaurantProvider>();
    return Scaffold(
      backgroundColor: AppColors.cream,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.terracotta,
        onPressed: () => Navigator.pushNamed(context, RouteNames.kAddPlace),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildMapCard()),
          SliverToBoxAdapter(child: _buildCityChips(restaurantProvider)),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildQuickFilters()),
          SliverToBoxAdapter(child: _buildEditorPicksHeader()),
          if (restaurantProvider.isLoading)
            const SliverToBoxAdapter(child: _FeedShimmer())
          else if (restaurantProvider.feed.isEmpty)
            const SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No places found.'))))
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.language_outlined, size: 22, color: AppColors.ink),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.fraunces(
                      fontSize: 17, color: AppColors.ink, fontWeight: FontWeight.w600),
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
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, RouteNames.kSettings),
            child: const StripeTile(
              color: AppColors.terracotta,
              width: 32,
              height: 32,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteNames.kMapSearch),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.parchment,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGrey),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            CustomPaint(
                size: const Size(double.infinity, 200), painter: _MapPainter()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(color: AppColors.ink),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EXPLORE ON MAP',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white54,
                                letterSpacing: 1.2)),
                        Text(
                          context.watch<RestaurantProvider>().currentCityId
                              .replaceAll('_', ' ')
                              .split(' ')
                              .map((w) =>
                                  w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
                              .join(' '),
                          style: GoogleFonts.fraunces(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        size: 16, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityChips(RestaurantProvider provider) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: _cities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => AtlasPill(
          label: _cities[i]['name']!,
          selected: provider.currentCityId == _cities[i]['id'],
          onTap: () =>
              provider.loadFeed(cityId: _cities[i]['id']!),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AtlasSearchBar(
        hint: 'Ramen, kaiseki, late-night…',
        onTap: () {},
        showVoice: true,
      ),
    );
  }

  Widget _buildQuickFilters() {
    final filters = ['Tonight', 'Nearby', 'Cheap eats', 'Michelin'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => AtlasPill(
          label: filters[i],
          selected: i == 0,
          onTap: () {},
        ),
      ),
    );
  }

  Widget _buildEditorPicksHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SectionLabel("Editor's Picks"),
          Text('See all',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.terracotta,
                  fontWeight: FontWeight.w500)),
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
      onTap: () => Navigator.pushNamed(
        context,
        RouteNames.kRestaurantDetail,
        arguments: restaurant,
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.6)),
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
                  Text(
                    restaurant.name,
                    style: GoogleFonts.fraunces(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${restaurant.category} · ${restaurant.neighborhood}',
                    style:
                        GoogleFonts.inter(fontSize: 11, color: AppColors.warmGrey),
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
        height: 140,
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

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.parchment;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);
    final regionPaint = Paint()
      ..color = AppColors.lightGrey.withValues(alpha: 0.6);
    final blobs = [
      Offset(size.width * 0.22, size.height * 0.35),
      Offset(size.width * 0.48, size.height * 0.4),
      Offset(size.width * 0.72, size.height * 0.32),
    ];
    for (final b in blobs) { canvas.drawCircle(b, 36, regionPaint); }
    final dotPaint = Paint()..color = AppColors.ink;
    final dots = [
      Offset(size.width * 0.18, size.height * 0.42),
      Offset(size.width * 0.44, size.height * 0.48),
      Offset(size.width * 0.52, size.height * 0.35),
      Offset(size.width * 0.70, size.height * 0.28),
    ];
    for (final d in dots) { canvas.drawCircle(d, 3, dotPaint); }
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.5), 4,
        Paint()..color = AppColors.terracotta);
  }

  @override
  bool shouldRepaint(_) => false;
}
