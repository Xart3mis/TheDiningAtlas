import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/seed_data_provider.dart';
import '../../models/trip_model.dart';
import '../../core/constants/route_names.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<SeedDataProvider>().load();
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) {
        context.read<TripProvider>().loadTrips(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();

    TripDayModel? currentDay;
    int spotCount = 0;
    if (tripProvider.trips.isNotEmpty) {
      final trip = tripProvider.trips.first;
      currentDay = trip.days.isNotEmpty
          ? trip.days[_selectedDayIndex % trip.days.length]
          : null;
      spotCount = currentDay?.spots.length ?? 0;
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: _buildHeader(
                  tripProvider.trips.isNotEmpty ? tripProvider.trips.first : null)),
          if (tripProvider.isLoading)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator())))
          else if (tripProvider.trips.isEmpty)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child:
                        Center(child: Text('No trips yet. Plan your first!'))))
          else ...[
            SliverToBoxAdapter(
                child: _buildDaySelector(tripProvider.trips.first)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _SpotCard(spot: currentDay!.spots[i]),
                childCount: spotCount,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(TripModel? trip) {
    final cityDisplay = trip != null
        ? trip.cityId
            .split('_')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
            .join(' ')
        : 'My Trips';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MY TRIPS',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warmGrey,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.fraunces(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                    children: [
                      TextSpan(
                          text: cityDisplay,
                          style: GoogleFonts.fraunces(
                              fontStyle: FontStyle.italic,
                              color: AppColors.terracotta)),
                      if (trip != null)
                        TextSpan(
                            text:
                                ', ${_monthName(trip.startDate.month)} ${trip.startDate.year}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, RouteNames.kPlanTrip),
            icon: const Icon(Icons.add, size: 16),
            label: Text('Plan Trip',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(TripModel trip) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(trip.days.length, (i) {
          final day = trip.days[i];
          final selected = i == _selectedDayIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin:
                    EdgeInsets.only(right: i < trip.days.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.ink : AppColors.parchment,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          selected ? Colors.transparent : AppColors.lightGrey),
                ),
                child: Column(
                  children: [
                    Text(
                      _dayLabel(day.date),
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: selected ? Colors.white70 : AppColors.warmGrey,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text('${day.date.day}',
                        style: GoogleFonts.fraunces(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : AppColors.ink)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _dayLabel(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

<<<<<<< HEAD
  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }
}

class _SpotCard extends StatelessWidget {
  final TripSpotModel spot;
  const _SpotCard({required this.spot});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(spot.time,
                      style: GoogleFonts.dmMono(
                          fontSize: 11, color: AppColors.warmGrey)),
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
                    Text(spot.mealType,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warmGrey,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.lightGrey.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          const StripeTile(
                            color: AppColors.teal,
                            width: 56,
                            height: 56,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(spot.name,
                                    style: GoogleFonts.fraunces(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink)),
                                const SizedBox(height: 2),
                                Text(spot.neighborhood,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.warmGrey)),
                              ],
                            ),
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
    );
  }
}
