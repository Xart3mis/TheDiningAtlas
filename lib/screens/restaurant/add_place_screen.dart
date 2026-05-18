import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/restaurant_model.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _pageController = PageController();
  int _step = 0;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _tipController = TextEditingController();
  final _dishController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _neighborhoodController = TextEditingController();

  String _category = 'Restaurant';
  String _priceRange = '\$\$';
  final List<File> _photos = [];
  bool _isSubmitting = false;

  final _categories = ['Restaurant', 'Cafe', 'Street Food', 'Bar', 'Market', 'Nature', 'Art'];
  final _priceTiers = ['\$', '\$\$', '\$\$\$'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _tipController.dispose();
    _dishController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _neighborhoodController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final restaurant = RestaurantModel(
        id: '',
        name: _nameController.text.trim(),
        category: _category,
        cityId: 'tokyo',
        neighborhood: _neighborhoodController.text.trim(),
        geopoint: GeoPoint(
          double.tryParse(_latController.text) ?? 0,
          double.tryParse(_lngController.text) ?? 0,
        ),
        description: _descController.text.trim(),
        tip: _tipController.text.trim(),
        dish: _dishController.text.trim(),
        mediaUrls: [],
        contributorId: auth.user!.uid,
        status: 'pending',
        avgRating: 0,
        reviewCount: 0,
        saveCount: 0,
        priceRange: _priceRange,
        tileColor: AppColors.teal,
        tagline: _descController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await context.read<RestaurantProvider>().addRestaurant(restaurant);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Place submitted! It will be reviewed shortly.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add a Place (${_step + 1}/3)'),
        backgroundColor: AppColors.cream,
        elevation: 0,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (p) => setState(() => _step = p),
        children: [_step1Info(), _step2Location(), _step3Photos()],
      ),
    );
  }

  Widget _step1Info() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Place name *'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description *'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tipController,
            decoration: const InputDecoration(labelText: 'Local tip (insider advice)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dishController,
            decoration: const InputDecoration(labelText: 'Recommended dish'),
          ),
          const SizedBox(height: 16),
          Row(
            children: _priceTiers.map((p) {
              final sel = _priceRange == p;
              return GestureDetector(
                onTap: () => setState(() => _priceRange = p),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.terracotta : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: sel ? AppColors.terracotta : AppColors.lightGrey),
                  ),
                  child: Text(p,
                      style: TextStyle(
                          color: sel ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          _NextButton(
              onTap: _nameController.text.isNotEmpty ? _next : null),
        ],
      ),
    );
  }

  Widget _step2Location() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _neighborhoodController,
            decoration: const InputDecoration(labelText: 'Neighborhood *'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _latController,
            decoration: const InputDecoration(labelText: 'Latitude'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lngController,
            decoration: const InputDecoration(labelText: 'Longitude'),
            keyboardType: TextInputType.number,
          ),
          const Spacer(),
          _NextButton(onTap: _next),
        ],
      ),
    );
  }

  Widget _step3Photos() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                ..._photos.map((f) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(f, fit: BoxFit.cover),
                    )),
                if (_photos.length < 5)
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                          source: ImageSource.gallery, imageQuality: 80);
                      if (picked != null) {
                        setState(() => _photos.add(File(picked.path)));
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.lightGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined,
                          size: 32, color: AppColors.warmGrey),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _isSubmitting
              ? const CircularProgressIndicator()
              : _NextButton(label: 'Submit Place', onTap: _next),
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  const _NextButton({this.onTap, this.label = 'Continue'});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
