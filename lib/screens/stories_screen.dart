import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFF6B4A2A), Color(0xFF1A0D00)],
              ),
            ),
          ),
          // Top bar
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      _TabItem(label: 'Following', selected: false, onTap: () {}),
                      const SizedBox(width: 24),
                      _TabItem(label: 'For You', selected: true, onTap: () {}),
                      const SizedBox(width: 24),
                      _TabItem(label: 'Near Me', selected: false, onTap: () {}),
                      const Spacer(),
                      Icon(Icons.search, color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Play button center
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
            ),
          ),
          // Right action buttons
          Positioned(
            right: 16,
            bottom: 180,
            child: Column(
              children: [
                _StoryAction(
                  icon: Icons.favorite_border,
                  label: '42.1K',
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                _StoryAction(
                  icon: Icons.chat_bubble_outline,
                  label: '1284',
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                _StoryAction(
                  icon: Icons.bookmark_border,
                  label: 'Save',
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                _StoryAction(
                  icon: Icons.ios_share_outlined,
                  label: '',
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                // Avatar circle
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    const StripeTile(
                      color: AppColors.terracotta,
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    Positioned(
                      bottom: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.terracotta,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bottom info
          Positioned(
            left: 16,
            right: 80,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text('@noodle.pilgrim',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.6)),
                        ),
                        child: Text('Follow',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '"The best tsukemen in Tokyo is hiding under a train track."',
                  style: GoogleFonts.fraunces(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.white, height: 1.4),
                ),
              ],
            ),
          ),
          // Bottom restaurant card
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const StripeTile(
                      color: AppColors.terracotta,
                      width: 44,
                      height: 44,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Menya Itto',
                              style: GoogleFonts.fraunces(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          Row(
                            children: [
                              Icon(Icons.place_outlined, size: 11, color: AppColors.warmGrey),
                              const SizedBox(width: 2),
                              Text('Tokyo · Ramen',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('View', style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Navigation arrows
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : Colors.white54,
            ),
          ),
          const SizedBox(height: 3),
          if (selected)
            Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.terracotta,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _StoryAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}
