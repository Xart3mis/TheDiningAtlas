import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

// ─── Diagonal stripe tile (placeholder for images) ──────────────────────────
class StripeTile extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final String? label;
  final BorderRadius? borderRadius;

  const StripeTile({
    super.key,
    required this.color,
    this.width = 60,
    this.height = 60,
    this.label,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _StripePainter(color: color),
          child: label != null
              ? Center(
                  child: Text(
                    label!,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  final Color color;
  const _StripePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final stripePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    const spacing = 16.0;
    final diag = size.width + size.height;
    for (double i = -diag; i < diag * 2; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.color != color;
}

// ─── Star rating row ─────────────────────────────────────────────────────────
class StarRating extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double size;

  const StarRating({super.key, required this.rating, this.reviewCount = 0, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: AppColors.terracotta, size: size),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        if (reviewCount > 0) ...[
          const SizedBox(width: 3),
          Text(
            '($reviewCount)',
            style: GoogleFonts.inter(fontSize: size - 1, color: AppColors.warmGrey),
          ),
        ],
      ],
    );
  }
}

// ─── Price/status dot row ─────────────────────────────────────────────────────
class MetaDots extends StatelessWidget {
  final List<String> items;
  final double fontSize;

  const MetaDots({super.key, required this.items, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items
          .expand((item) => [
                Text(item, style: GoogleFonts.inter(fontSize: fontSize, color: AppColors.warmGrey)),
                if (item != items.last)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('·', style: GoogleFonts.inter(fontSize: fontSize, color: AppColors.warmGrey)),
                  ),
              ])
          .toList(),
    );
  }
}

// ─── Section label (all-caps, spaced) ────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.warmGrey,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ─── Pill / chip ─────────────────────────────────────────────────────────────
class AtlasPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? selectedColor;

  const AtlasPill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? (selectedColor ?? AppColors.ink) : Colors.transparent,
          border: Border.all(color: selected ? Colors.transparent : AppColors.lightGrey),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Bottom nav ───────────────────────────────────────────────────────────────
class AtlasBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AtlasBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.language_outlined, 'Atlas'),
      (Icons.favorite_border_outlined, 'For You'),
      (Icons.play_circle_outline, 'Stories'),
      (Icons.chat_bubble_outline, 'Messages'),
      (Icons.luggage_outlined, 'Trips'),
      (Icons.person_outline, 'You'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.lightGrey.withOpacity(0.6))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              final iconColor = selected ? AppColors.terracotta : AppColors.warmGrey;

              Widget iconWidget = Icon(items[i].$1, size: 22, color: iconColor);

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      iconWidget,
                      const SizedBox(height: 2),
                      Text(
                        items[i].$2,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Notification badge icon ──────────────────────────────────────────────────
class _BadgeIcon extends StatelessWidget {
  final Widget icon;
  final int count;
  const _BadgeIcon({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────
class AtlasSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final bool showVoice;

  const AtlasSearchBar({super.key, required this.hint, this.onTap, this.showVoice = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.parchment,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.lightGrey),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(Icons.search, size: 18, color: AppColors.warmGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(hint, style: GoogleFonts.inter(fontSize: 14, color: AppColors.warmGrey)),
            ),
            if (showVoice) const Icon(Icons.mic_none, size: 18, color: AppColors.terracotta),
          ],
        ),
      ),
    );
  }
}
