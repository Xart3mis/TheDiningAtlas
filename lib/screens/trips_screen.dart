import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../core/constants/mock_data.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  int _selectedDayIndex = 1; // Friday 12 selected

  final _days = [
    (label: 'Thu', day: 11),
    (label: 'Fri', day: 12),
    (label: 'Sat', day: 13),
    (label: 'Sun', day: 14),
  ];

  void _onAddSpot() {}
  void _onRoute() {}
  void _onSpotTap(TripSpot spot) {}

  @override
  Widget build(BuildContext context) {
    final spots = sampleTrip.first.spots;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildDaySelector()),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _SpotCard(spot: spots[i], onTap: () => _onSpotTap(spots[i])),
              childCount: spots.length,
            ),
          ),
          SliverToBoxAdapter(child: _buildAddSpot()),
          SliverToBoxAdapter(child: _buildFooter()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TRIP · 5 DAYS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warmGrey, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: GoogleFonts.fraunces(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink),
              children: [
                TextSpan(text: 'Tokyo', style: GoogleFonts.fraunces(fontStyle: FontStyle.italic, color: AppColors.terracotta)),
                const TextSpan(text: ', April 2026'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text('12 restaurants saved · 3 booked · with Felipe & Aiko',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(_days.length, (i) {
          final d = _days[i];
          final selected = i == _selectedDayIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(right: i < _days.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.ink : AppColors.parchment,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? Colors.transparent : AppColors.lightGrey,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      d.label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: selected ? Colors.white70 : AppColors.warmGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d.day}',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAddSpot() {
    return GestureDetector(
      onTap: _onAddSpot,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightGrey, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.warmGrey),
            const SizedBox(width: 6),
            Text('Add a spot', style: GoogleFonts.inter(fontSize: 13, color: AppColors.warmGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Icon(Icons.directions_walk, size: 16, color: AppColors.warmGrey),
          const SizedBox(width: 6),
          Text('42 min total walking · 3.1 km today',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
          const Spacer(),
          GestureDetector(
            onTap: _onRoute,
            child: Text('Route', style: GoogleFonts.inter(fontSize: 13, color: AppColors.terracotta, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  final TripSpot spot;
  final VoidCallback onTap;

  const _SpotCard({required this.spot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(spot.time, style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.warmGrey)),
                  const SizedBox(height: 4),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.terracotta, width: 2),
                      color: AppColors.cream,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 1,
                      color: AppColors.lightGrey,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.mealType,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warmGrey, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: [
                            StripeTile(
                              color: spot.tileColor,
                              width: 56,
                              height: 56,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(spot.name,
                                      style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                                  const SizedBox(height: 2),
                                  Text(spot.neighborhood,
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
                                  const SizedBox(height: 6),
                                  StatusBadge(
                                    label: spot.statusLabel,
                                    color: spot.statusColor,
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
          ],
        ),
      ),
    );
  }
}
