import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/models.dart';
import 'restaurant_detail_screen.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  String _activeFilter = 'All 48';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildHowWePick()),
          SliverToBoxAdapter(child: _buildFilters()),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _RecommendationCard(
                restaurant: sampleRestaurants[i % sampleRestaurants.length],
                rank: i + 1,
                reason: _reasons[i % _reasons.length],
              ),
              childCount: sampleRestaurants.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  final _reasons = [
    _Reason('Cuisine match', '— Because you loved Sukiyabashi Jiro', AppColors.terracotta),
    _Reason('Nearby', '— Within 5 min walk', AppColors.teal),
    _Reason('Trending locals', '— Locals rate it 4.9 this week', AppColors.gold),
    _Reason('Friends saved', '— 3 people you follow', AppColors.dustyBlue),
    _Reason('Hidden gem', '— Under the radar this season', AppColors.sageGreen),
    _Reason('Editor pick', '— Featured in Spring 2026 guide', AppColors.warmGrey),
  ];

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FOR YOU · TOKYO', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warmGrey, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: GoogleFonts.fraunces(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.ink),
              children: [
                const TextSpan(text: 'Hand-picked for '),
                TextSpan(text: 'Maya', style: GoogleFonts.fraunces(fontStyle: FontStyle.italic, color: AppColors.terracotta)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('48 places · refreshed this morning',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.warmGrey)),
        ],
      ),
    );
  }

  Widget _buildHowWePick() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 14, color: AppColors.terracotta),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HOW WE PICK',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.terracotta, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink, height: 1.5),
                    children: [
                      const TextSpan(text: 'We blend your '),
                      TextSpan(text: 'saved places', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const TextSpan(text: ', '),
                      TextSpan(text: 'cuisine taste', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const TextSpan(text: ', where '),
                      TextSpan(text: 'locals and tourists', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const TextSpan(text: ' are going this week, and what '),
                      TextSpan(text: 'your friends', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const TextSpan(text: ' are bookmarking.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['All 48', 'Nearby 12', 'Cuisine 22', 'Trending'];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => AtlasPill(
          label: filters[i],
          selected: filters[i] == _activeFilter,
          onTap: () => setState(() => _activeFilter = filters[i]),
        ),
      ),
    );
  }
}

class _Reason {
  final String label;
  final String detail;
  final Color color;
  const _Reason(this.label, this.detail, this.color);
}

class _RecommendationCard extends StatelessWidget {
  final Restaurant restaurant;
  final int rank;
  final _Reason reason;

  const _RecommendationCard({required this.restaurant, required this.rank, required this.reason});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: restaurant)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey.withOpacity(0.6)),
        ),
        clipBehavior: Clip.hardEdge,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  StripeTile(
                    color: restaurant.tileColor,
                    width: 88,
                    height: 88,
                    label: 'PHOTO',
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      bottomLeft: Radius.circular(11),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('#$rank', style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.warmGrey)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${restaurant.cuisine} · ${restaurant.neighborhood}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StarRating(rating: restaurant.rating, size: 11),
                          const SizedBox(width: 6),
                          Text('· ${restaurant.priceRange}',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.warmGrey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: reason.color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: reason.color)),
                            const SizedBox(width: 6),
                            Text(reason.label,
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: reason.color)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(reason.detail,
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.warmGrey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
