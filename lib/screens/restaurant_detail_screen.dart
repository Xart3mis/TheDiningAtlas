import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/models.dart';
import 'write_review_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  String _activeTab = 'Overview';
  final _tabs = ['Overview', 'Menu', 'Reviews', 'Photos'];

  void _onSave() {}
  void _onShare() {}
  void _onDirections() {}
  void _onWriteReview() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => WriteReviewScreen(restaurant: widget.restaurant)));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero(context, r)),
          SliverToBoxAdapter(child: _buildTabs()),
          if (_activeTab == 'Overview') ...[
            SliverToBoxAdapter(child: _buildTagline(r)),
            SliverToBoxAdapter(child: _buildInfoGrid(r)),
            SliverToBoxAdapter(child: _buildWalkInfo(r)),
            SliverToBoxAdapter(child: _buildMustTrySection()),
            SliverToBoxAdapter(child: _buildWriteReviewButton()),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, Restaurant r) {
    return Stack(
      children: [
        StripeTile(
          color: r.tileColor,
          width: double.infinity,
          height: 240,
          borderRadius: BorderRadius.zero,
        ),
        // Gradient
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
        // Nav buttons
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.9)),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.ink),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: Row(
            children: [
              _HeroButton(icon: Icons.bookmark_border, onTap: _onSave),
              const SizedBox(width: 8),
              _HeroButton(icon: Icons.ios_share_outlined, onTap: _onShare),
            ],
          ),
        ),
        // Badge + title
        Positioned(
          left: 20,
          right: 20,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.badge != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.terracotta,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(r.badge!, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.2)),
                ),
              Text(r.name, style: GoogleFonts.fraunces(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.ink)),
              Text('${r.cuisine} · ${r.neighborhood}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.warmGrey)),
              const SizedBox(height: 6),
              Row(
                children: [
                  StarRating(rating: r.rating, reviewCount: r.reviewCount),
                  const SizedBox(width: 8),
                  Text('· ${r.priceRange}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
                  const SizedBox(width: 8),
                  Text('· ${r.status}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
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
        border: Border(bottom: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6))),
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
              child: Text(
                tab,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.terracotta : AppColors.warmGrey,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTagline(Restaurant r) {
    if (r.tagline == null) return const SizedBox(height: 20);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.terracotta, width: 3)),
        color: AppColors.parchment,
        borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.tagline!,
            style: GoogleFonts.fraunces(fontSize: 15, fontStyle: FontStyle.italic, color: AppColors.ink, height: 1.5),
          ),
          const SizedBox(height: 6),
          Text('— THE ATLAS, 2025',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warmGrey, letterSpacing: 1.1)),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Restaurant r) {
    final items = [
      ('ADDRESS', r.address ?? '—'),
      ('HOURS', r.hours ?? '—'),
      ('PHONE', r.phone ?? '—'),
      ('RESERVE', r.reserve ?? '—'),
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

  Widget _buildWalkInfo(Restaurant r) {
    if (r.walkInfo == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.parchment, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.place_outlined, color: AppColors.terracotta, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.walkInfo!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
                Text('Chuo City, Tokyo', style: GoogleFonts.inter(fontSize: 11, color: AppColors.warmGrey)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _onDirections,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(20)),
              child: Text('Directions', style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMustTrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: SectionLabel('Must-Try Dishes'),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final colors = [AppColors.dustyBlue, AppColors.warmTan, AppColors.softRed];
              return StripeTile(
                color: colors[i],
                width: 80,
                height: 80,
                borderRadius: BorderRadius.circular(10),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWriteReviewButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: _onWriteReview,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.terracotta,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text('Write a Review',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeroButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.9)),
        child: Icon(icon, size: 18, color: AppColors.ink),
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
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.warmGrey, letterSpacing: 1.1)),
          const SizedBox(height: 3),
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
