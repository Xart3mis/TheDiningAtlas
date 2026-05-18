import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/restaurant_model.dart';
import '../../models/review_model.dart';
import '../../providers/review_provider.dart';
import '../../providers/auth_provider.dart';

class WriteReviewScreen extends StatefulWidget {
  final RestaurantModel restaurant;
  const WriteReviewScreen({super.key, required this.restaurant});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  double _rating = 0;
  final Set<String> _selectedVibes = {};
  final _reviewController = TextEditingController();
  final _orderedController = TextEditingController();
  final List<File> _photos = [];
  bool _isSubmitting = false;

  final _vibes = ['Cozy', 'Romantic', 'Lively', 'Quiet', 'Great value', 'Worth the wait', 'Hidden gem'];

  @override
  void dispose() {
    _reviewController.dispose();
    _orderedController.dispose();
    super.dispose();
  }

  Future<void> _onPost() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a rating.')));
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please write a review.')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final review = ReviewModel(
        id: '',
        restaurantId: widget.restaurant.id,
        authorId: auth.user!.uid,
        authorName: auth.user!.displayName ?? 'Anonymous',
        authorPhotoUrl: auth.user!.photoURL ?? '',
        text: _reviewController.text.trim(),
        rating: _rating,
        upvotes: 0,
        createdAt: DateTime.now(),
      );
      await context.read<ReviewProvider>().submitReview(review);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not submit: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onAddPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _photos.add(File(picked.path)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Form(
        key: _formKey,
        child: Column(
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
                width: 32, height: 32,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lightGrey)),
                child: const Icon(Icons.close, size: 16, color: AppColors.ink),
              ),
            ),
            Text('Review',
                style: GoogleFonts.fraunces(
                    fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
            GestureDetector(
              onTap: _isSubmitting ? null : _onPost,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                    color: _isSubmitting ? AppColors.warmGrey : AppColors.ink,
                    borderRadius: BorderRadius.circular(16)),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Post',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
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
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          StripeTile(
              color: widget.restaurant.tileColor,
              width: 44, height: 44,
              borderRadius: BorderRadius.circular(8)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.restaurant.name,
                  style: GoogleFonts.fraunces(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
              Text('${widget.restaurant.category} · ${widget.restaurant.neighborhood}',
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
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warmGrey, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return GestureDetector(
              onTap: () => setState(() => _rating = (i + 1).toDouble()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 36,
                  color: i < _rating ? AppColors.terracotta : AppColors.lightGrey,
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
        Text('The vibe',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _vibes.map((v) {
            final selected = _selectedVibes.contains(v);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) { _selectedVibes.remove(v); } else { _selectedVibes.add(v); }
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
                    style: GoogleFonts.inter(
                        fontSize: 13, color: selected ? Colors.white : AppColors.ink)),
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
        Text('What you ordered',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: TextField(
            controller: _orderedController,
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
        Text('Tell the story',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.white, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: TextField(
            controller: _reviewController,
            maxLines: null, expands: true,
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
      children: [
        ..._photos.take(3).map((f) => Expanded(
          child: Container(
            height: 72, margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.lightGrey),
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.file(f, fit: BoxFit.cover),
          ),
        )),
        if (_photos.length < 3)
          Expanded(
            child: GestureDetector(
              onTap: _onAddPhoto,
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.white, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.lightGrey),
                ),
                child: const Icon(Icons.add, color: AppColors.warmGrey, size: 22),
              ),
            ),
          ),
      ],
    );
  }
}
