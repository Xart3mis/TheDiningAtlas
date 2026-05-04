import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/models.dart';

class WriteReviewScreen extends StatefulWidget {
  final Restaurant restaurant;
  const WriteReviewScreen({super.key, required this.restaurant});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  int _starRating = 0;
  final Set<String> _selectedVibes = {};
  final _orderController = TextEditingController();
  final _storyController = TextEditingController();

  final _vibes = ['Cozy', 'Romantic', 'Lively', 'Quiet', 'Great value', 'Worth the wait', 'Skip the line', 'Tourist friendly', 'Hidden gem'];

  void _onPost() {}
  void _onAddPhoto() {}

  @override
  void dispose() {
    _orderController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRestaurantHeader(),
                  const SizedBox(height: 24),
                  _buildStarRating(),
                  const SizedBox(height: 24),
                  _buildVibeSection(),
                  const SizedBox(height: 20),
                  _buildOrderedSection(),
                  const SizedBox(height: 20),
                  _buildStorySection(),
                  const SizedBox(height: 20),
                  _buildPhotoRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.lightGrey)),
                child: const Icon(Icons.close, size: 16, color: AppColors.ink),
              ),
            ),
            Text('Review', style: GoogleFonts.fraunces(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
            GestureDetector(
              onTap: _onPost,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('Post', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          StripeTile(color: widget.restaurant.tileColor, width: 44, height: 44, borderRadius: BorderRadius.circular(8)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.restaurant.name,
                  style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
              Text('${widget.restaurant.cuisine} · ${widget.restaurant.neighborhood}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    return Column(
      children: [
        Text('HOW WAS IT?',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warmGrey, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return GestureDetector(
              onTap: () => setState(() => _starRating = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  i < _starRating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 36,
                  color: i < _starRating ? AppColors.terracotta : AppColors.lightGrey,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildVibeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('The vibe', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _vibes.map((v) {
            final selected = _selectedVibes.contains(v);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) _selectedVibes.remove(v); else _selectedVibes.add(v);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? Colors.transparent : AppColors.lightGrey),
                ),
                child: Text(v,
                    style: GoogleFonts.inter(fontSize: 13, color: selected ? Colors.white : AppColors.ink)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOrderedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What you ordered', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: TextField(
            controller: _orderController,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: "e.g. Chef's omakase, 15 pieces",
              hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.warmGrey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tell the story', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: TextField(
            controller: _storyController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'What made it special? What should the next traveler know?',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.warmGrey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoRow() {
    return Row(
      children: List.generate(3, (_) => Expanded(
        child: GestureDetector(
          onTap: _onAddPhoto,
          child: Container(
            height: 72,
            margin: EdgeInsets.only(right: _ < 2 ? 10 : 0),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: const Icon(Icons.add, color: AppColors.warmGrey, size: 22),
          ),
        ),
      )),
    );
  }
}
