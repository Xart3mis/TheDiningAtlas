import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/seed_data_provider.dart';
import '../../models/trip_model.dart';
import '../../core/constants/route_names.dart';

class PlanTripScreen extends StatefulWidget {
  const PlanTripScreen({super.key});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  String? _selectedCityId;
  DateTimeRange? _dateRange;
  final _titleController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.terracotta),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  String _formatRange(DateTimeRange r) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = r.end.difference(r.start).inDays + 1;
    return '${months[r.start.month]} ${r.start.day} – ${months[r.end.month]} ${r.end.day} ($days days)';
  }

  Future<void> _create() async {
    if (_selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
      );
      return;
    }
    if (_dateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select travel dates')),
      );
      return;
    }
    setState(() => _isCreating = true);
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      final cityName = _selectedCityId!.replaceAll('_', ' ').split(' ')
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
      final title = _titleController.text.trim().isEmpty
          ? '$cityName Trip'
          : _titleController.text.trim();

      final days = <TripDayModel>[];
      final total = _dateRange!.end.difference(_dateRange!.start).inDays + 1;
      for (int i = 0; i < total; i++) {
        days.add(TripDayModel(
          id: 'day_$i',
          date: _dateRange!.start.add(Duration(days: i)),
          spots: <TripSpotModel>[],
        ));
      }

      final trip = TripModel(
        id: '',
        uid: uid,
        title: title,
        cityId: _selectedCityId!,
        startDate: _dateRange!.start,
        endDate: _dateRange!.end,
        participantUids: [uid],
        days: days,
      );

      await context.read<TripProvider>().createTrip(uid, trip);
      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteNames.kMain);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create trip: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seedProvider = context.watch<SeedDataProvider>();
    final cities = seedProvider.cities;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: Text('Plan a Trip',
            style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('DESTINATION'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCityId,
              hint: Text('Select a city',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.warmGrey)),
              decoration: _inputDecoration(),
              items: cities.map((city) {
                return DropdownMenuItem(
                  value: city.id,
                  child: Text(city.displayName,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.ink)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCityId = v),
            ),
            const SizedBox(height: 20),

            _label('TRAVEL DATES'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDates,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.lightGrey.withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.warmGrey),
                    const SizedBox(width: 10),
                    Text(
                      _dateRange == null
                          ? 'Pick travel dates'
                          : _formatRange(_dateRange!),
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _dateRange == null
                              ? AppColors.warmGrey
                              : AppColors.ink),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _label('TRIP TITLE (OPTIONAL)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
              decoration: _inputDecoration().copyWith(
                hintText: 'e.g. "Tokyo Adventure"',
                hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.warmGrey.withOpacity(0.6)),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Create Trip',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.warmGrey,
          letterSpacing: 1.2));

  InputDecoration _inputDecoration() => InputDecoration(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.lightGrey.withOpacity(0.6))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.lightGrey.withOpacity(0.6))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.terracotta, width: 1.5)),
      );
}
