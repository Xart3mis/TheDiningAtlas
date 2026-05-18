import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  File? _pickedImage;
  Map<String, String>? _selectedCountry;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── PFP picker ────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  // ── Country picker ────────────────────────────────────────────────────────

  Future<void> _openCountryPicker() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CountryPickerSheet(),
    );
    if (result != null) {
      setState(() => _selectedCountry = result);
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your country of birth')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      username: _usernameController.text.trim(),
      countryCode: _selectedCountry!['code']!,
      displayName: _nameController.text.trim(),
    );
    if (success && mounted) {
      Navigator.pushNamed(context, RouteNames.kOnboarding);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // ── Header ────────────────────────────────────────────────
                Text(
                  'Create\nYour Account',
                  style: GoogleFonts.fraunces(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join the community of curious travelers.',
                  style: GoogleFonts.fraunces(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: AppColors.terracotta,
                  ),
                ),
                const SizedBox(height: 32),

                // ── 2.1 PFP avatar ────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: _pickedImage != null
                        ? CircleAvatar(
                            radius: 45,
                            backgroundImage: FileImage(_pickedImage!),
                          )
                        : const _DashedAvatarPlaceholder(),
                  ),
                ),
                const SizedBox(height: 28),

                // ── 2.4 Full Name (1st text field) ────────────────────────
                _buildLabel('FULL NAME'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
                  decoration: _inputDecoration('Maya Kowalski'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── 2.2 Username ──────────────────────────────────────────
                _buildLabel('USERNAME'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _usernameController,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
                  decoration: _inputDecoration('e.g. maya_kowalski'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Username is required';
                    }
                    if (v.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                      return 'Only letters, numbers, and underscores allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── 2.3 Country of Birth ──────────────────────────────────
                _buildLabel('COUNTRY OF BIRTH'),
                const SizedBox(height: 6),
                _CountryField(
                  selectedCountry: _selectedCountry,
                  onTap: _openCountryPicker,
                  inputDecoration: _inputDecoration('Select your country'),
                ),
                const SizedBox(height: 18),

                // ── Email ─────────────────────────────────────────────────
                _buildLabel('EMAIL'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
                  decoration: _inputDecoration('your@email.com'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── Password ──────────────────────────────────────────────
                _buildLabel('PASSWORD'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
                  decoration: _inputDecoration('At least 6 characters').copyWith(
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.warmGrey,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── Confirm Password ──────────────────────────────────────
                _buildLabel('CONFIRM PASSWORD'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
                  decoration: _inputDecoration('Re-enter password'),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // ── Error message ─────────────────────────────────────────
                Consumer<AuthProvider>(
                  builder: (_, auth, __) {
                    if (auth.error == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        auth.error!,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.red.shade700),
                      ),
                    );
                  },
                ),

                // ── Sign-up button ────────────────────────────────────────
                Consumer<AuthProvider>(
                  builder: (_, auth, __) {
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _onRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                'Create Account',
                                style: GoogleFonts.inter(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),

                // ── Login link ────────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen())),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.warmGrey),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign In',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.warmGrey,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.warmGrey.withValues(alpha: 0.6)),
      filled: true,
      fillColor: AppColors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.terracotta, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
    );
  }
}

// ── Dashed avatar placeholder ────────────────────────────────────────────────

class _DashedAvatarPlaceholder extends StatelessWidget {
  const _DashedAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCirclePainter(color: AppColors.terracotta),
      child: SizedBox(
        width: 90,
        height: 90,
        child: Center(
          child: Icon(Icons.camera_alt_outlined,
              size: 30, color: AppColors.terracotta),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;
    const dashCount = 24;
    const dashAngle = 3.14159265 * 2 / dashCount;
    const gapFraction = 0.45; // fraction of each segment that is a gap

    for (int i = 0; i < dashCount; i++) {
      final startAngle = dashAngle * i;
      final sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ── Country tappable field ────────────────────────────────────────────────────

class _CountryField extends StatelessWidget {
  final Map<String, String>? selectedCountry;
  final VoidCallback onTap;
  final InputDecoration inputDecoration;

  const _CountryField({
    required this.selectedCountry,
    required this.onTap,
    required this.inputDecoration,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedCountry != null;
    final displayText =
        hasValue ? selectedCountry!['name']! : inputDecoration.hintText ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: inputDecoration.copyWith(
          hintText: null,
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: AppColors.warmGrey),
        ),
        child: Text(
          displayText,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: hasValue
                ? AppColors.ink
                : AppColors.warmGrey.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ── Country picker bottom sheet ───────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  static const List<Map<String, String>> _allCountries = [
    {'name': 'Afghanistan', 'code': 'AF'},
    {'name': 'Albania', 'code': 'AL'},
    {'name': 'Algeria', 'code': 'DZ'},
    {'name': 'Argentina', 'code': 'AR'},
    {'name': 'Australia', 'code': 'AU'},
    {'name': 'Austria', 'code': 'AT'},
    {'name': 'Bangladesh', 'code': 'BD'},
    {'name': 'Belgium', 'code': 'BE'},
    {'name': 'Bolivia', 'code': 'BO'},
    {'name': 'Bosnia and Herzegovina', 'code': 'BA'},
    {'name': 'Brazil', 'code': 'BR'},
    {'name': 'Bulgaria', 'code': 'BG'},
    {'name': 'Cambodia', 'code': 'KH'},
    {'name': 'Cameroon', 'code': 'CM'},
    {'name': 'Canada', 'code': 'CA'},
    {'name': 'Chile', 'code': 'CL'},
    {'name': 'China', 'code': 'CN'},
    {'name': 'Colombia', 'code': 'CO'},
    {'name': 'Croatia', 'code': 'HR'},
    {'name': 'Czech Republic', 'code': 'CZ'},
    {'name': 'Denmark', 'code': 'DK'},
    {'name': 'Ecuador', 'code': 'EC'},
    {'name': 'Egypt', 'code': 'EG'},
    {'name': 'Ethiopia', 'code': 'ET'},
    {'name': 'Finland', 'code': 'FI'},
    {'name': 'France', 'code': 'FR'},
    {'name': 'Germany', 'code': 'DE'},
    {'name': 'Ghana', 'code': 'GH'},
    {'name': 'Greece', 'code': 'GR'},
    {'name': 'Hungary', 'code': 'HU'},
    {'name': 'India', 'code': 'IN'},
    {'name': 'Indonesia', 'code': 'ID'},
    {'name': 'Iran', 'code': 'IR'},
    {'name': 'Iraq', 'code': 'IQ'},
    {'name': 'Ireland', 'code': 'IE'},
    {'name': 'Israel', 'code': 'IL'},
    {'name': 'Italy', 'code': 'IT'},
    {'name': 'Japan', 'code': 'JP'},
    {'name': 'Jordan', 'code': 'JO'},
    {'name': 'Kenya', 'code': 'KE'},
    {'name': 'South Korea', 'code': 'KR'},
    {'name': 'Kuwait', 'code': 'KW'},
    {'name': 'Lebanon', 'code': 'LB'},
    {'name': 'Libya', 'code': 'LY'},
    {'name': 'Malaysia', 'code': 'MY'},
    {'name': 'Mexico', 'code': 'MX'},
    {'name': 'Morocco', 'code': 'MA'},
    {'name': 'Netherlands', 'code': 'NL'},
    {'name': 'New Zealand', 'code': 'NZ'},
    {'name': 'Nigeria', 'code': 'NG'},
    {'name': 'Norway', 'code': 'NO'},
    {'name': 'Pakistan', 'code': 'PK'},
    {'name': 'Peru', 'code': 'PE'},
    {'name': 'Philippines', 'code': 'PH'},
    {'name': 'Poland', 'code': 'PL'},
    {'name': 'Portugal', 'code': 'PT'},
    {'name': 'Qatar', 'code': 'QA'},
    {'name': 'Romania', 'code': 'RO'},
    {'name': 'Russia', 'code': 'RU'},
    {'name': 'Saudi Arabia', 'code': 'SA'},
    {'name': 'Serbia', 'code': 'RS'},
    {'name': 'Singapore', 'code': 'SG'},
    {'name': 'South Africa', 'code': 'ZA'},
    {'name': 'Spain', 'code': 'ES'},
    {'name': 'Sri Lanka', 'code': 'LK'},
    {'name': 'Sudan', 'code': 'SD'},
    {'name': 'Sweden', 'code': 'SE'},
    {'name': 'Switzerland', 'code': 'CH'},
    {'name': 'Syria', 'code': 'SY'},
    {'name': 'Taiwan', 'code': 'TW'},
    {'name': 'Tanzania', 'code': 'TZ'},
    {'name': 'Thailand', 'code': 'TH'},
    {'name': 'Tunisia', 'code': 'TN'},
    {'name': 'Turkey', 'code': 'TR'},
    {'name': 'Uganda', 'code': 'UG'},
    {'name': 'Ukraine', 'code': 'UA'},
    {'name': 'United Arab Emirates', 'code': 'AE'},
    {'name': 'United Kingdom', 'code': 'GB'},
    {'name': 'United States', 'code': 'US'},
    {'name': 'Uruguay', 'code': 'UY'},
    {'name': 'Venezuela', 'code': 'VE'},
    {'name': 'Vietnam', 'code': 'VN'},
    {'name': 'Yemen', 'code': 'YE'},
    {'name': 'Zimbabwe', 'code': 'ZW'},
  ];

  final _searchController = TextEditingController();
  List<Map<String, String>> _filtered = List.of(_allCountries);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? _allCountries
          : _allCountries
              .where((c) =>
                  c['name']!.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.warmGrey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Country of Birth',
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style:
                  GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Search…',
                hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.warmGrey.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: AppColors.warmGrey),
                filled: true,
                fillColor: AppColors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: AppColors.lightGrey.withValues(alpha: 0.6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: AppColors.lightGrey.withValues(alpha: 0.6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.terracotta, width: 1.5),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final country = _filtered[index];
                return ListTile(
                  onTap: () => Navigator.pop(context, country),
                  title: Text(
                    country['name']!,
                    style:
                        GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      country['code']!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.terracotta,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
