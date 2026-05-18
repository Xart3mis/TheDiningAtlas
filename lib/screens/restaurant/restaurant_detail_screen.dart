import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/restaurant_model.dart';
import '../../models/place_summary_model.dart';
import '../../providers/review_provider.dart';
import '../../providers/saved_places_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ai_provider.dart';
import '../../core/constants/route_names.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final RestaurantModel restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  String _activeTab = 'Overview';
  final _tabs = ['Overview', 'Reviews', 'Photos'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ReviewProvider>().loadReviews(widget.restaurant.id);
      context.read<AiProvider>().loadSummary(widget.restaurant.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final savedProvider = context.watch<SavedPlacesProvider>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero(context, r, savedProvider, authProvider)),
          SliverToBoxAdapter(child: _buildTabs()),
          if (_activeTab == 'Overview') ...[
            SliverToBoxAdapter(child: _buildTagline(r)),
            SliverToBoxAdapter(child: _buildInfoGrid(r)),
            SliverToBoxAdapter(child: _buildActions(r)),
          ] else if (_activeTab == 'Reviews') ...[
            SliverToBoxAdapter(
                child: _AiSummaryCard(restaurantId: r.id)),
            SliverToBoxAdapter(child: _buildReviewsList(r)),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, RestaurantModel r,
      SavedPlacesProvider savedProvider, AuthProvider authProvider) {
    final isSaved = savedProvider.isSaved(r.id);
    return Stack(
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child: r.mediaUrls.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: r.mediaUrls.first,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: r.tileColor),
                  errorWidget: (_, __, ___) =>
                      Container(color: r.tileColor),
                )
              : StripeTile(
                  color: r.tileColor,
                  width: double.infinity,
                  height: 240,
                  borderRadius: BorderRadius.zero,
                ),
        ),
        Container(
          height: 240,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, AppColors.cream],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.9)),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.ink),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final uid = authProvider.user?.uid ?? 'guest_user';
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await savedProvider.toggleSave(uid: uid, restaurant: r);
                  } catch (e) {
                    messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())));
                  }
                },
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.9)),
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                    color: isSaved ? AppColors.terracotta : AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9)),
                child: const Icon(Icons.ios_share_outlined,
                    size: 18, color: AppColors.ink),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20, right: 20, bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.name,
                  style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              Text('${r.category} · ${r.neighborhood}',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.warmGrey)),
              const SizedBox(height: 6),
              Row(
                children: [
                  StarRating(rating: r.avgRating, reviewCount: r.reviewCount),
                  const SizedBox(width: 8),
                  Text('· ${r.priceRange}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.warmGrey)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border(
            bottom: BorderSide(color: AppColors.lightGrey.withOpacity(0.6))),
      ),
      child: Row(
        children: _tabs.map((tab) {
          final selected = tab == _activeTab;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = tab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? AppColors.terracotta : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(tab,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.terracotta : AppColors.warmGrey,
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTagline(RestaurantModel r) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.terracotta, width: 3)),
        color: AppColors.parchment,
        borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
      ),
      child: Text(r.tagline,
          style: GoogleFonts.fraunces(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: AppColors.ink,
              height: 1.5)),
    );
  }

  Widget _buildInfoGrid(RestaurantModel r) {
    final items = [
      ('NEIGHBORHOOD', r.neighborhood),
      ('PRICE', r.priceRange),
      ('CATEGORY', r.category),
      ('STATUS', r.status),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.4,
        children: items.map((item) => _InfoCell(label: item.$1, value: item.$2)).toList(),
      ),
    );
  }

  Widget _buildActions(RestaurantModel r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                  context, RouteNames.kWriteReview, arguments: r),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Write a Review',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                RouteNames.kChatThread,
                arguments: {
                  'otherUid': r.contributorId,
                  'placeId': r.id,
                  'otherName': 'Local',
                },
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Ask a local'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.lightGrey),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(RestaurantModel r) {
    final reviewProvider = context.watch<ReviewProvider>();
    final reviews = reviewProvider.reviewsFor(r.id);
    final locale = Localizations.localeOf(context).languageCode;

    if (reviewProvider.isLoading) {
      return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()));
    }
    if (reviews.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No reviews yet. Be the first!')));
    }
    return Column(
      children: reviews.map((review) {
        final translation = reviewProvider.translationFor(review.id, locale);
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey.withOpacity(0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.parchment,
                    child: Text(review.authorName[0],
                        style: GoogleFonts.fraunces(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.authorName,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink)),
                      StarRating(rating: review.rating, size: 11),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => reviewProvider.upvote(
                        restaurantId: r.id, reviewId: review.id),
                    child: Row(
                      children: [
                        const Icon(Icons.thumb_up_outlined,
                            size: 14, color: AppColors.warmGrey),
                        const SizedBox(width: 4),
                        Text('${review.upvotes}',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.warmGrey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(review.text,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.ink, height: 1.5)),
              if (translation != null) ...[
                const Divider(height: 16),
                Text(translation,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.warmGrey,
                        fontStyle: FontStyle.italic)),
              ] else ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => reviewProvider.translate(
                    restaurantId: r.id,
                    reviewId: review.id,
                    text: review.text,
                    targetLang: locale,
                  ),
                  child: Text('Translate',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.teal,
                          decoration: TextDecoration.underline)),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AiSummaryCard extends StatelessWidget {
  final String restaurantId;
  const _AiSummaryCard({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AiProvider>();
    final summary = aiProvider.summaryFor(restaurantId);

    if (aiProvider.isGenerating) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFFE0D9D0),
        highlightColor: const Color(0xFFF5EFE6),
        child: Container(
          height: 120,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    if (summary == null) return const SizedBox.shrink();
    return _AiSummaryContent(summary: summary);
  }
}

class _AiSummaryContent extends StatelessWidget {
  final PlaceSummaryModel summary;
  const _AiSummaryContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppColors.teal),
              const SizedBox(width: 6),
              Text('AI Summary',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: AppColors.teal,
                      letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 8),
          Text(summary.vibeOneLiner,
              style: GoogleFonts.fraunces(
                  fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.ink)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: summary.topAspects
                .map((a) => Chip(
                      label: Text(a,
                          style: GoogleFonts.inter(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
          if (summary.caveats.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Watch out: ${summary.caveats.join(', ')}',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
          ],
          Text('Best time: ${summary.bestTime}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warmGrey,
                  letterSpacing: 1.1)),
          const SizedBox(height: 3),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
