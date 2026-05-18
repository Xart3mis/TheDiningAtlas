# UI Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement 30+ UI fixes and enhancements across Auth, Onboarding, Atlas, Trips, and Profile screens in 3 phases.

**Architecture:** Pure UI changes — no new service interfaces needed. New data fields are added to `UserModel` and `OnboardingPrefsModel`, wired through existing providers. New UI constants (`kCountryCities`, `kSupportedCountries`, `kEditorPicks`) go in `app_constants.dart`. Tab switching from `AtlasScreen` uses a `GlobalKey<_MainShellState>` exposed on `MainShell`.

**Tech Stack:** Flutter/Dart, Provider, Firebase Auth + Storage, `image_picker`, `shimmer`, `cached_network_image`, `google_fonts`.

---

## Phase 1 — Auth & Sign-Up

---

### Task 1: Extend UserModel with username, countryCode, onboardingCountryId

**Files:**
- Modify: `lib/models/user_model.dart`

- [ ] **Step 1: Add three new fields to `UserModel`**

Replace the class definition in `lib/models/user_model.dart` with:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final String tier;
  final int score;
  final bool isPremium;
  final bool onboardingComplete;
  final ChatPrivacy chatPrivacy;
  final DateTime createdAt;
  final String username;
  final String countryCode;       // ISO-2, e.g. 'EG'
  final String onboardingCountryId; // e.g. 'egypt'

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.tier,
    required this.score,
    required this.isPremium,
    required this.onboardingComplete,
    required this.chatPrivacy,
    required this.createdAt,
    this.username = '',
    this.countryCode = '',
    this.onboardingCountryId = '',
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: d['displayName'] ?? '',
      email: d['email'] ?? '',
      photoUrl: d['photoUrl'] ?? '',
      tier: d['tier'] ?? 'explorer',
      score: d['score'] ?? 0,
      isPremium: d['isPremium'] ?? false,
      onboardingComplete: d['onboardingComplete'] ?? false,
      chatPrivacy: ChatPrivacy.fromMap(d['chatPrivacy'] ?? {}),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      username: d['username'] ?? '',
      countryCode: d['countryCode'] ?? '',
      onboardingCountryId: d['onboardingCountryId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
    'tier': tier,
    'score': score,
    'isPremium': isPremium,
    'onboardingComplete': onboardingComplete,
    'chatPrivacy': chatPrivacy.toMap(),
    'createdAt': FieldValue.serverTimestamp(),
    'username': username,
    'countryCode': countryCode,
    'onboardingCountryId': onboardingCountryId,
  };
}

class ChatPrivacy {
  final String mode;
  final String? scheduleStart;
  final String? scheduleEnd;
  final List<String> scheduleDays;

  const ChatPrivacy({
    required this.mode,
    this.scheduleStart,
    this.scheduleEnd,
    this.scheduleDays = const [],
  });

  factory ChatPrivacy.fromMap(Map<String, dynamic> m) => ChatPrivacy(
    mode: m['mode'] ?? 'public',
    scheduleStart: m['scheduleStart'],
    scheduleEnd: m['scheduleEnd'],
    scheduleDays: List<String>.from(m['scheduleDays'] ?? []),
  );

  Map<String, dynamic> toMap() => {
    'mode': mode,
    'scheduleStart': scheduleStart,
    'scheduleEnd': scheduleEnd,
    'scheduleDays': scheduleDays,
  };
}
```

- [ ] **Step 2: Run `flutter analyze` to confirm no type errors**

```
cd TheDiningAtlas && flutter analyze lib/models/user_model.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/models/user_model.dart
git commit -m "feat: add username, countryCode, onboardingCountryId to UserModel"
```

---

### Task 2: Extend OnboardingPrefsModel — rename cityId → countryId

**Files:**
- Modify: `lib/models/onboarding_prefs_model.dart`
- Modify: `lib/providers/onboarding_provider.dart`

- [ ] **Step 1: Update `OnboardingPrefsModel`**

Replace `lib/models/onboarding_prefs_model.dart` with:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingPrefsModel {
  final List<String> vibes;
  final String budget;
  final List<String> atmosphere;
  final String countryId;           // was cityId
  final Map<String, double> aiWeights;

  const OnboardingPrefsModel({
    required this.vibes,
    required this.budget,
    required this.atmosphere,
    required this.countryId,
    required this.aiWeights,
  });

  factory OnboardingPrefsModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OnboardingPrefsModel(
      vibes: List<String>.from(d['vibes'] ?? []),
      budget: d['budget'] ?? r'$',
      atmosphere: List<String>.from(d['atmosphere'] ?? []),
      countryId: d['countryId'] ?? d['cityId'] ?? '',  // fallback reads old field
      aiWeights: Map<String, double>.from(
        (d['aiWeights'] ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vibes': vibes,
    'budget': budget,
    'atmosphere': atmosphere,
    'countryId': countryId,
    'aiWeights': aiWeights,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
```

- [ ] **Step 2: Update `OnboardingProvider` — rename cityId/setCity → countryId/setCountry, add countryCode getter**

Replace `lib/providers/onboarding_provider.dart` with:

```dart
import 'package:flutter/material.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/interfaces/i_ai_service.dart';
import '../models/onboarding_prefs_model.dart';

const _kCountryCodeMap = {
  'france': 'FR', 'spain': 'ES', 'united_states': 'US', 'china': 'CN',
  'italy': 'IT', 'turkey': 'TR', 'mexico': 'MX', 'thailand': 'TH',
  'germany': 'DE', 'united_kingdom': 'GB', 'japan': 'JP', 'greece': 'GR',
  'austria': 'AT', 'egypt': 'EG', 'malaysia': 'MY',
};

const _kCountryNameMap = {
  'france': 'France', 'spain': 'Spain', 'united_states': 'United States',
  'china': 'China', 'italy': 'Italy', 'turkey': 'Turkey', 'mexico': 'Mexico',
  'thailand': 'Thailand', 'germany': 'Germany', 'united_kingdom': 'United Kingdom',
  'japan': 'Japan', 'greece': 'Greece', 'austria': 'Austria',
  'egypt': 'Egypt', 'malaysia': 'Malaysia',
};

class OnboardingProvider extends ChangeNotifier {
  final IUserService _userService;
  final IAiService _aiService;
  OnboardingProvider(this._userService, this._aiService);

  final List<String> _vibes = [];
  String _budget = r'$$';
  final List<String> _atmosphere = [];
  String _countryId = 'japan';
  bool _isLoading = false;
  bool _completed = false;

  List<String> get vibes => List.unmodifiable(_vibes);
  String get budget => _budget;
  List<String> get atmosphere => List.unmodifiable(_atmosphere);
  String get countryId => _countryId;
  String get countryCode => _kCountryCodeMap[_countryId] ?? '';
  String get countryName => _kCountryNameMap[_countryId] ?? _countryId;
  bool get isLoading => _isLoading;
  bool get completed => _completed;

  void toggleVibe(String id) {
    if (_vibes.contains(id)) {
      _vibes.remove(id);
    } else {
      _vibes.add(id);
    }
    notifyListeners();
  }

  void setBudget(String value) {
    _budget = value;
    notifyListeners();
  }

  void toggleAtmosphere(String id) {
    if (_atmosphere.contains(id)) {
      _atmosphere.remove(id);
    } else {
      _atmosphere.add(id);
    }
    notifyListeners();
  }

  void setCountry(String id) {
    _countryId = id;
    notifyListeners();
  }

  Future<void> completeOnboarding(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = OnboardingPrefsModel(
        vibes: _vibes,
        budget: _budget,
        atmosphere: _atmosphere,
        countryId: _countryId,
        aiWeights: {},
      );
      final weights = await _aiService.generateTasteWeights(prefs);
      final prefsWithWeights = OnboardingPrefsModel(
        vibes: _vibes,
        budget: _budget,
        atmosphere: _atmosphere,
        countryId: _countryId,
        aiWeights: weights,
      );
      await _userService.savePreferences(uid, prefsWithWeights);
      await _userService.markOnboardingComplete(uid);
      _completed = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

- [ ] **Step 3: Run `flutter analyze` to confirm no errors**

```
flutter analyze lib/models/onboarding_prefs_model.dart lib/providers/onboarding_provider.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/models/onboarding_prefs_model.dart lib/providers/onboarding_provider.dart
git commit -m "feat: rename cityId→countryId in OnboardingPrefsModel and provider, add countryCode/countryName getters"
```

---

### Task 3: Add kSupportedCountries, kCountryCities, kEditorPicks to app_constants.dart

**Files:**
- Modify: `lib/core/constants/app_constants.dart`

- [ ] **Step 1: Add the three new constants**

Append to `lib/core/constants/app_constants.dart` (keep existing `AppConstants` class, add below it):

```dart
const kSupportedCountries = [
  {'id': 'france',         'name': 'France',         'code': 'FR'},
  {'id': 'spain',          'name': 'Spain',           'code': 'ES'},
  {'id': 'united_states',  'name': 'United States',   'code': 'US'},
  {'id': 'china',          'name': 'China',           'code': 'CN'},
  {'id': 'italy',          'name': 'Italy',           'code': 'IT'},
  {'id': 'turkey',         'name': 'Turkey',          'code': 'TR'},
  {'id': 'mexico',         'name': 'Mexico',          'code': 'MX'},
  {'id': 'thailand',       'name': 'Thailand',        'code': 'TH'},
  {'id': 'germany',        'name': 'Germany',         'code': 'DE'},
  {'id': 'united_kingdom', 'name': 'United Kingdom',  'code': 'GB'},
  {'id': 'japan',          'name': 'Japan',           'code': 'JP'},
  {'id': 'greece',         'name': 'Greece',          'code': 'GR'},
  {'id': 'austria',        'name': 'Austria',         'code': 'AT'},
  {'id': 'egypt',          'name': 'Egypt',           'code': 'EG'},
  {'id': 'malaysia',       'name': 'Malaysia',        'code': 'MY'},
];

const kCountryCities = <String, List<String>>{
  'france':         ['Paris', 'Lyon', 'Marseille', 'Nice', 'Bordeaux', 'Toulouse', 'Strasbourg', 'Nantes'],
  'spain':          ['Madrid', 'Barcelona', 'Seville', 'Valencia', 'Bilbao', 'Granada', 'Malaga', 'Zaragoza'],
  'united_states':  ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Miami', 'San Francisco', 'Las Vegas', 'New Orleans'],
  'china':          ['Beijing', 'Shanghai', 'Guangzhou', 'Chengdu', "Xi'an", 'Hangzhou', 'Shenzhen', 'Chongqing'],
  'italy':          ['Rome', 'Milan', 'Florence', 'Venice', 'Naples', 'Bologna', 'Turin', 'Palermo'],
  'turkey':         ['Istanbul', 'Ankara', 'Izmir', 'Antalya', 'Bursa', 'Gaziantep', 'Konya', 'Cappadocia'],
  'mexico':         ['Mexico City', 'Guadalajara', 'Monterrey', 'Oaxaca', 'Cancun', 'Puebla', 'Merida', 'Tulum'],
  'thailand':       ['Bangkok', 'Chiang Mai', 'Phuket', 'Pattaya', 'Hua Hin', 'Krabi', 'Koh Samui', 'Ayutthaya'],
  'germany':        ['Berlin', 'Munich', 'Hamburg', 'Frankfurt', 'Cologne', 'Stuttgart', 'Dresden', 'Düsseldorf'],
  'united_kingdom': ['London', 'Edinburgh', 'Manchester', 'Birmingham', 'Bristol', 'Glasgow', 'Liverpool', 'Bath'],
  'japan':          ['Tokyo', 'Osaka', 'Kyoto', 'Hiroshima', 'Sapporo', 'Fukuoka', 'Nara', 'Kobe'],
  'greece':         ['Athens', 'Thessaloniki', 'Santorini', 'Mykonos', 'Rhodes', 'Heraklion', 'Corfu', 'Nafplio'],
  'austria':        ['Vienna', 'Salzburg', 'Innsbruck', 'Graz', 'Linz', 'Hallstatt', 'Bregenz', 'Klagenfurt'],
  'egypt':          ['Cairo', 'Alexandria', 'Luxor', 'Aswan', 'Hurghada', 'Sharm El Sheikh', 'Dahab', 'El Gouna'],
  'malaysia':       ['Kuala Lumpur', 'Penang', 'Johor Bahru', 'Kota Kinabalu', 'Kuching', 'Malacca', 'Langkawi', 'Ipoh'],
};

const kEditorPicks = <String, List<String>>{
  'paris':         ['Le Comptoir du Relais', 'Septime', 'L\'Ami Jean'],
  'tokyo':         ['Sukiyabashi Jiro', 'Narisawa', 'Den'],
  'rome':          ['Da Enzo al 29', 'Roscioli', 'Pizzarium'],
  'barcelona':     ['Bar Cañete', 'Tickets', 'El Xampanyet'],
  'istanbul':      ['Karaköy Lokantası', 'Çiya Sofrası', 'Mikla'],
  'mexico city':   ['Pujol', 'Quintonil', 'El Hidalguense'],
  'bangkok':       ['Nahm', 'Bo.lan', 'Jay Fai'],
  'london':        ['St. John', 'Dishoom', 'The Ledbury'],
  'new york':      ['Lucali', 'Katz\'s Deli', 'Gramercy Tavern'],
  'cairo':         ['Koshary El Tahrir', 'Abou El Sid', 'Zooba'],
};
```

- [ ] **Step 2: Run `flutter analyze`**

```
flutter analyze lib/core/constants/app_constants.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/app_constants.dart
git commit -m "feat: add kSupportedCountries, kCountryCities, kEditorPicks constants"
```

---

### Task 4: Add kPlanTrip route constant and stub route

**Files:**
- Modify: `lib/core/constants/route_names.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add the route constant**

In `lib/core/constants/route_names.dart`, add inside the `RouteNames` class:

```dart
static const String kPlanTrip = '/plan-trip';
```

- [ ] **Step 2: Add the stub route in `main.dart`**

In `lib/main.dart`, inside `_generateRoute`, add before `default:`:

```dart
case RouteNames.kPlanTrip:
  return MaterialPageRoute(
    builder: (_) => Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: Text('Plan a Trip',
            style: GoogleFonts.fraunces(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: Center(
        child: Text('Coming soon',
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.warmGrey)),
      ),
    ),
  );
```

Also add the import at the top if not present: `import 'theme/app_theme.dart';` (already present).

- [ ] **Step 3: Run `flutter analyze`**

```
flutter analyze lib/core/constants/route_names.dart lib/main.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants/route_names.dart lib/main.dart
git commit -m "feat: add kPlanTrip route constant and Coming Soon stub screen"
```

---

### Task 5: Register screen — add username, country picker, PFP upload, fix nav

**Files:**
- Modify: `lib/screens/auth/register_screen.dart`
- Modify: `lib/providers/auth_provider.dart`

- [ ] **Step 1: Update `AuthProvider.signUp` to accept username and countryCode**

In `lib/providers/auth_provider.dart`, change the `signUp` signature and body. The auth state listener in `AuthProvider` auto-creates the Firestore user doc when it sees a new UID — we need to pass `username` and `countryCode` through so that doc gets the fields. The simplest approach: store them temporarily in `AuthProvider` so the listener can use them.

Replace the `signUp` method and add two fields:

```dart
String _pendingUsername = '';
String _pendingCountryCode = '';

/// Sign up with email/password. Call before navigating to onboarding.
Future<bool> signUp(String email, String password,
    {required String username, required String countryCode}) async {
  _pendingUsername = username;
  _pendingCountryCode = countryCode;
  _setLoading(true);
  try {
    await _authService.signUpWithEmail(email, password);
    _error = null;
    return true;
  } on FirebaseAuthException catch (e) {
    _error = _friendlyError(e.code);
    _pendingUsername = '';
    _pendingCountryCode = '';
    return false;
  } finally {
    _setLoading(false);
  }
}
```

Also update the `_userService.createUser` call inside the `authStateChanges` listener to use the pending fields:

```dart
await _userService.createUser(UserModel(
  uid: user.uid,
  email: user.email ?? '',
  displayName: user.displayName ?? '',
  photoUrl: user.photoURL ?? '',
  tier: 'explorer',
  score: 0,
  isPremium: false,
  onboardingComplete: false,
  chatPrivacy: const ChatPrivacy(mode: 'private'),
  createdAt: DateTime.now(),
  username: _pendingUsername,
  countryCode: _pendingCountryCode,
));
_pendingUsername = '';
_pendingCountryCode = '';
```

- [ ] **Step 2: Rewrite `register_screen.dart`**

Replace `lib/screens/auth/register_screen.dart` with the full implementation:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/route_names.dart';
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
  String _countryName = '';
  String _countryCode = '';

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _pickCountry() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CountryPickerSheet(),
    );
    if (result != null) {
      setState(() {
        _countryName = result['name']!;
        _countryCode = result['code']!;
      });
    }
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_countryCode.isEmpty) {
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
      countryCode: _countryCode,
    );
    if (success && mounted) {
      await auth.user?.updateDisplayName(_nameController.text.trim());
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, RouteNames.kOnboarding, (_) => false);
      }
    }
  }

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
                Text('Create\nYour Account',
                    style: GoogleFonts.fraunces(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.1)),
                const SizedBox(height: 8),
                Text('Join the community of curious travelers.',
                    style: GoogleFonts.fraunces(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: AppColors.terracotta)),
                const SizedBox(height: 28),

                // PFP upload
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.terracotta,
                            width: 2,
                            style: _pickedImage == null
                                ? BorderStyle.solid
                                : BorderStyle.solid),
                        color: AppColors.parchment,
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: _pickedImage != null
                          ? Image.file(_pickedImage!, fit: BoxFit.cover)
                          : const Icon(Icons.camera_alt_outlined,
                              color: AppColors.terracotta, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text('Add photo (optional)',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.warmGrey)),
                ),
                const SizedBox(height: 24),

                _buildLabel('FULL NAME'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
                  decoration: _inputDecoration('Maya Kowalski'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                _buildLabel('USERNAME'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _usernameController,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
                  decoration: _inputDecoration('@maya').copyWith(prefixText: '@'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Username is required';
                    if (v.trim().length < 3) return 'At least 3 characters';
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                      return 'Letters, numbers, and underscores only';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildLabel('COUNTRY OF BIRTH'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickCountry,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.lightGrey.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _countryName.isEmpty ? 'Select country' : _countryName,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _countryName.isEmpty
                                    ? AppColors.warmGrey.withValues(alpha: 0.6)
                                    : AppColors.ink),
                          ),
                        ),
                        if (_countryCode.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.parchment,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(_countryCode,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink)),
                          )
                        else
                          const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.warmGrey, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: 16),

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
                          color: AppColors.warmGrey),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildLabel('CONFIRM PASSWORD'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
                  decoration: _inputDecoration('Re-enter password'),
                  validator: (v) =>
                      v != _passwordController.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 24),

                Consumer<AuthProvider>(
                  builder: (_, auth, __) {
                    if (auth.error == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(auth.error!,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.red.shade700)),
                    );
                  },
                ),

                Consumer<AuthProvider>(
                  builder: (_, auth, __) => SizedBox(
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
                          : Text('Create Account',
                              style: GoogleFonts.inter(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
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
                                fontWeight: FontWeight.w600),
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

  Widget _buildLabel(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.warmGrey,
          letterSpacing: 1.2));

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            fontSize: 14, color: AppColors.warmGrey.withValues(alpha: 0.6)),
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.terracotta, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade300)),
      );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = kSupportedCountries
        .where((c) => (c['name'] as String)
            .toLowerCase()
            .contains(_search.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search country…',
                hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.warmGrey.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.warmGrey),
                filled: true,
                fillColor: AppColors.parchment,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final c = filtered[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c['name'] as String,
                      style: GoogleFonts.inter(
                          fontSize: 15, color: AppColors.ink)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.parchment,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(c['code'] as String,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                  ),
                  onTap: () => Navigator.pop(context,
                      {'name': c['name'] as String, 'code': c['code'] as String}),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Run `flutter analyze`**

```
flutter analyze lib/screens/auth/register_screen.dart lib/providers/auth_provider.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/auth/register_screen.dart lib/providers/auth_provider.dart
git commit -m "feat: register screen — PFP upload, username, country picker, navigate to onboarding"
```

---

## Phase 2 — Onboarding Flow

---

### Task 6: Vibe Selector — 12 vibes, 3-col grid, back button

**Files:**
- Modify: `lib/screens/onboarding/vibe_selector_screen.dart`

- [ ] **Step 1: Replace `vibe_selector_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';

const _kVibes = [
  {'id': 'hidden_cafe',  'label': 'Hidden Café',  'emoji': '☕'},
  {'id': 'street_food',  'label': 'Street Food',  'emoji': '🌮'},
  {'id': 'rooftop_bar',  'label': 'Rooftop Bar',  'emoji': '🍸'},
  {'id': 'local_market', 'label': 'Local Market', 'emoji': '🛒'},
  {'id': 'art_gallery',  'label': 'Art Gallery',  'emoji': '🎨'},
  {'id': 'night_life',   'label': 'Nightlife',    'emoji': '🎵'},
  {'id': 'fine_dining',  'label': 'Fine Dining',  'emoji': '🍽️'},
  {'id': 'nature_spot',  'label': 'Nature Spot',  'emoji': '🌿'},
  {'id': 'beach_vibes',  'label': 'Beach Vibes',  'emoji': '🏖️'},
  {'id': 'craft_beer',   'label': 'Craft Beer',   'emoji': '🍺'},
  {'id': 'wellness',     'label': 'Wellness',     'emoji': '🧘'},
  {'id': 'cultural',     'label': 'Cultural',     'emoji': '🎭'},
];

class VibeSelectorScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const VibeSelectorScreen({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's your vibe?",
              style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1C1A))),
          const SizedBox(height: 8),
          Text('Pick everything that speaks to you.',
              style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF6B6560))),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: _kVibes.map((vibe) {
                final selected = provider.vibes.contains(vibe['id']);
                return GestureDetector(
                  onTap: () => provider.toggleVibe(vibe['id']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFC17B4E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected
                              ? const Color(0xFFC17B4E)
                              : const Color(0xFFE0D9D0)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(vibe['emoji']!,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(vibe['label']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF2C2825))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                  onPressed: onBack,
                  child: Text('Back',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF6B6560)))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: provider.vibes.isNotEmpty ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC17B4E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Continue',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run `flutter analyze`**

```
flutter analyze lib/screens/onboarding/vibe_selector_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/vibe_selector_screen.dart
git commit -m "feat: vibe selector — 12 vibes, 3-col grid, add back button"
```

---

### Task 7: Budget Screen — USD tiers

**Files:**
- Modify: `lib/screens/onboarding/budget_screen.dart`

- [ ] **Step 1: Replace options list in `budget_screen.dart`**

Replace the `options` list inside the `build` method:

```dart
final options = [
  {r'$':    r'Under $15 · Budget'},
  {r'$$':   r'$15 – $50 · Mid-range'},
  {r'$$$':  r'$50 – $100 · Upscale'},
  {r'$$$$': r'$100+ · Fine Dining'},
];
```

- [ ] **Step 2: Run `flutter analyze`**

```
flutter analyze lib/screens/onboarding/budget_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/budget_screen.dart
git commit -m "feat: budget screen — replace EGP with USD tiers, add Fine Dining tier"
```

---

### Task 8: Destination Screen — countries (rename city_screen → destination_screen)

**Files:**
- Create: `lib/screens/onboarding/destination_screen.dart`
- Delete: `lib/screens/onboarding/city_screen.dart` (after updating shell)

- [ ] **Step 1: Create `destination_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../core/constants/app_constants.dart';

class DestinationScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const DestinationScreen({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where are you headed?',
              style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1C1A))),
          const SizedBox(height: 8),
          Text('Pick your destination.',
              style: GoogleFonts.inter(
                  fontSize: 16, color: const Color(0xFF6B6560))),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: kSupportedCountries.length,
              itemBuilder: (_, i) {
                final country = kSupportedCountries[i];
                final id = country['id'] as String;
                final name = country['name'] as String;
                final code = country['code'] as String;
                final selected = provider.countryId == id;
                return GestureDetector(
                  onTap: () => provider.setCountry(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFC17B4E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected
                              ? const Color(0xFFC17B4E)
                              : const Color(0xFFE0D9D0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white24
                                : const Color(0xFFF0EBE4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(code,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF555555))),
                        ),
                        const SizedBox(width: 14),
                        Text(name,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF2C2825))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              TextButton(
                  onPressed: onBack,
                  child: Text('Back',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF6B6560)))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC17B4E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Continue',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run `flutter analyze`**

```
flutter analyze lib/screens/onboarding/destination_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/destination_screen.dart
git commit -m "feat: destination screen — 15 supported countries with ISO code badges"
```

---

### Task 9: Update OnboardingShell — swap CityScreen for DestinationScreen, wire back on page 1

**Files:**
- Modify: `lib/screens/onboarding/onboarding_shell.dart`

- [ ] **Step 1: Replace `onboarding_shell.dart`**

```dart
import 'package:flutter/material.dart';
import 'vibe_selector_screen.dart';
import 'budget_screen.dart';
import 'atmosphere_screen.dart';
import 'destination_screen.dart';
import 'profile_ready_screen.dart';

class OnboardingShell extends StatefulWidget {
  const OnboardingShell({super.key});

  @override
  State<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends State<OnboardingShell> {
  final _controller = PageController();
  int _currentPage = 0;

  void _next() {
    if (_currentPage < 4) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _controller.previousPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i == _currentPage
                          ? const Color(0xFFC17B4E)
                          : const Color(0xFFCCC5B9),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) =>
                    setState(() => _currentPage = page),
                children: [
                  VibeSelectorScreen(onNext: _next, onBack: _back),
                  BudgetScreen(onNext: _next, onBack: _back),
                  AtmosphereScreen(onNext: _next, onBack: _back),
                  DestinationScreen(onNext: _next, onBack: _back),
                  const ProfileReadyScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Delete old `city_screen.dart`**

```bash
rm "lib/screens/onboarding/city_screen.dart"
```

- [ ] **Step 3: Run `flutter analyze`**

```
flutter analyze lib/screens/onboarding/
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/onboarding/
git commit -m "feat: onboarding shell — swap CityScreen for DestinationScreen, back on page 1 pops to register"
```

---

### Task 10: Profile Ready Screen — full redesign

**Files:**
- Modify: `lib/screens/onboarding/profile_ready_screen.dart`

- [ ] **Step 1: Replace `profile_ready_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/route_names.dart';
import '../../theme/app_theme.dart';

const _kVibeLabels = {
  'hidden_cafe':  ('Hidden Café',  '☕'),
  'street_food':  ('Street Food',  '🌮'),
  'rooftop_bar':  ('Rooftop Bar',  '🍸'),
  'local_market': ('Local Market', '🛒'),
  'art_gallery':  ('Art Gallery',  '🎨'),
  'night_life':   ('Nightlife',    '🎵'),
  'fine_dining':  ('Fine Dining',  '🍽️'),
  'nature_spot':  ('Nature Spot',  '🌿'),
  'beach_vibes':  ('Beach Vibes',  '🏖️'),
  'craft_beer':   ('Craft Beer',   '🍺'),
  'wellness':     ('Wellness',     '🧘'),
  'cultural':     ('Cultural',     '🎭'),
};

const _kBudgetLabels = {
  r'$':    'Under \$15',
  r'$$':   '\$15 – \$50',
  r'$$$':  '\$50 – \$100',
  r'$$$$': '\$100+',
};

class ProfileReadyScreen extends StatelessWidget {
  const ProfileReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingProvider>();
    final auth = context.read<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text("You're all set!",
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 6),
          Text('Your taste profile is ready.',
              style: GoogleFonts.fraunces(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: AppColors.terracotta)),
          const SizedBox(height: 28),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.lightGrey.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR PROFILE',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warmGrey,
                        letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: onboarding.vibes.map((id) {
                    final label = _kVibeLabels[id];
                    final display = label != null
                        ? '${label.$2} ${label.$1}'
                        : id.replaceAll('_', ' ');
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.terracotta
                                .withValues(alpha: 0.3)),
                      ),
                      child: Text(display,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  '📍 ${onboarding.countryName}  ·  💰 ${_kBudgetLabels[onboarding.budget] ?? onboarding.budget}',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.warmGrey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onboarding.isLoading
                  ? null
                  : () async {
                      final uid = auth.user?.uid;
                      if (uid == null) return;
                      await onboarding.completeOnboarding(uid);
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(
                            context, RouteNames.kMain);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: onboarding.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Start Exploring',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run `flutter analyze`**

```
flutter analyze lib/screens/onboarding/profile_ready_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/profile_ready_screen.dart
git commit -m "feat: profile ready screen — polished redesign with summary card and Start Exploring CTA"
```

---

## Phase 3 — Main App

---

### Task 11: MainShell — conditional FAB + GlobalKey for tab switching

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add `GlobalKey` and expose `switchTab` on `MainShell`**

Replace the `MainShell` class in `lib/main.dart` with:

```dart
final mainShellKey = GlobalKey<_MainShellState>();

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static void switchTab(int index) {
    mainShellKey.currentState?._switchTab(index);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  final _screens = const [
    AtlasScreen(),
    ForYouScreen(),
    StoriesScreen(),
    TripsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AtlasBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
      floatingActionButton: _currentIndex <= 1
          ? FloatingActionButton(
              onPressed: () =>
                  Navigator.pushNamed(context, RouteNames.kAddPlace),
              backgroundColor: AppColors.terracotta,
              child: const Icon(Icons.add_location_alt, color: Colors.white),
            )
          : null,
    );
  }
}
```

Also update the `_generateRoute` case for `RouteNames.kMain` to use `mainShellKey`:

```dart
case RouteNames.kMain:
  return MaterialPageRoute(
      builder: (_) => MainShell(key: mainShellKey));
```

- [ ] **Step 2: Run `flutter analyze`**

```
flutter analyze lib/main.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: MainShell — FAB hidden on Stories/Trips/Profile, add GlobalKey for tab switching"
```

---

### Task 12: Atlas Screen — remove own FAB, PFP→profile, search banner, explore widget, country-aware city chips

**Files:**
- Modify: `lib/screens/home/atlas_screen.dart`

- [ ] **Step 1: Replace `atlas_screen.dart`**

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/restaurant_model.dart';
import '../../core/constants/route_names.dart';
import '../../core/constants/app_constants.dart';
import '../../main.dart' show MainShell;

class AtlasScreen extends StatefulWidget {
  const AtlasScreen({super.key});

  @override
  State<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends State<AtlasScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final countryId = context.read<OnboardingProvider>().countryId;
      final firstCity =
          (kCountryCities[countryId] ?? kCountryCities['japan']!).first;
      context
          .read<RestaurantProvider>()
          .loadFeed(cityId: firstCity.toLowerCase().replaceAll(' ', '_'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = context.watch<RestaurantProvider>();
    final onboardingProvider = context.watch<OnboardingProvider>();
    final countryId = onboardingProvider.countryId;
    final cities = kCountryCities[countryId] ?? kCountryCities['japan']!;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildSearchBanner(context, onboardingProvider.countryName)),
          SliverToBoxAdapter(child: _buildExploreWidget(onboardingProvider, cities.length)),
          SliverToBoxAdapter(child: _buildCityChips(restaurantProvider, cities)),
          SliverToBoxAdapter(child: _buildEditorPicksHeader()),
          if (restaurantProvider.isLoading)
            const SliverToBoxAdapter(child: _FeedShimmer())
          else if (restaurantProvider.feed.isEmpty)
            const SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No places found.'))))
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  scrollDirection: Axis.horizontal,
                  itemCount: restaurantProvider.feed.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) =>
                      _EditorPickCard(restaurant: restaurantProvider.feed[i]),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.fraunces(
                  fontSize: 17, color: AppColors.ink, fontWeight: FontWeight.w600),
              children: [
                const TextSpan(text: 'The '),
                TextSpan(
                  text: 'Dining',
                  style: GoogleFonts.fraunces(
                      fontStyle: FontStyle.italic, color: AppColors.ink),
                ),
                const TextSpan(text: ' Atlas'),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => MainShell.switchTab(4),
            child: SizedBox(
              width: 36,
              height: 36,
              child: ClipOval(
                child: user?.photoUrl.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: user!.photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const StripeTile(
                          color: AppColors.terracotta,
                          width: 36,
                          height: 36,
                          borderRadius:
                              BorderRadius.all(Radius.circular(18)),
                        ),
                        errorWidget: (_, __, ___) => const StripeTile(
                          color: AppColors.terracotta,
                          width: 36,
                          height: 36,
                          borderRadius:
                              BorderRadius.all(Radius.circular(18)),
                        ),
                      )
                    : const StripeTile(
                        color: AppColors.terracotta,
                        width: 36,
                        height: 36,
                        borderRadius:
                            BorderRadius.all(Radius.circular(18)),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBanner(BuildContext context, String countryName) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteNames.kMapSearch),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Search $countryName…',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: Colors.white54)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.terracotta,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('SEARCH',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreWidget(OnboardingProvider provider, int cityCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.lightGrey),
            ),
            alignment: Alignment.center,
            child: Text(provider.countryCode,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.countryName,
                    style: GoogleFonts.fraunces(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                Text('$cityCount cities · restaurants & hidden gems',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.warmGrey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.terracotta.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.terracotta.withValues(alpha: 0.3)),
            ),
            child: Text('Exploring',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.terracotta,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCityChips(RestaurantProvider provider, List<String> cities) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: cities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final citySlug =
              cities[i].toLowerCase().replaceAll(' ', '_');
          return AtlasPill(
            label: cities[i],
            selected: provider.currentCityId == citySlug,
            onTap: () => provider.loadFeed(cityId: citySlug),
          );
        },
      ),
    );
  }

  Widget _buildEditorPicksHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SectionLabel("Editor's Picks"),
          Text('See all',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.terracotta,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _EditorPickCard extends StatelessWidget {
  final RestaurantModel restaurant;
  const _EditorPickCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteNames.kRestaurantDetail,
          arguments: restaurant),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.lightGrey.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 72,
              child: restaurant.mediaUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: restaurant.mediaUrls.first,
                      fit: BoxFit.cover,
                      width: 160,
                      placeholder: (_, __) =>
                          Container(color: restaurant.tileColor),
                      errorWidget: (_, __, ___) =>
                          Container(color: restaurant.tileColor),
                    )
                  : StripeTile(
                      color: restaurant.tileColor,
                      width: 160,
                      height: 72,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name,
                      style: GoogleFonts.fraunces(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${restaurant.category} · ${restaurant.neighborhood}',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.warmGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  StarRating(rating: restaurant.avgRating, size: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedShimmer extends StatelessWidget {
  const _FeedShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0D9D0),
      highlightColor: const Color(0xFFF5EFE6),
      child: SizedBox(
        height: 140,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => Container(
            width: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run `flutter analyze`**

```
flutter analyze lib/screens/home/atlas_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/home/atlas_screen.dart
git commit -m "feat: atlas screen — dark search banner, explore widget, country-aware city chips, PFP→profile tab"
```

---

### Task 13: Trips Screen — add Plan Trip button

**Files:**
- Modify: `lib/screens/trips/trips_screen.dart`

- [ ] **Step 1: Update `_buildHeader()` in `trips_screen.dart`**

Replace the `_buildHeader()` method:

```dart
Widget _buildHeader() {
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
                        text: 'Tokyo',
                        style: GoogleFonts.fraunces(
                            fontStyle: FontStyle.italic,
                            color: AppColors.terracotta)),
                    const TextSpan(text: ', April 2026'),
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
```

- [ ] **Step 2: Run `flutter analyze`**

```
flutter analyze lib/screens/trips/trips_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/trips/trips_screen.dart
git commit -m "feat: trips screen — add Plan Trip button in header"
```

---

### Task 14: Profile Screen — shimmer loading, real username/countryCode, real passport

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart`

- [ ] **Step 1: Replace `_buildHeader` and `_buildPassport` in `profile_screen.dart`**

Replace the `_buildHeader` method:

```dart
Widget _buildHeader(BuildContext context, dynamic user, int savedCount) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
    child: Row(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: ClipOval(
            child: user?.photoUrl?.isNotEmpty == true
                ? CachedNetworkImage(
                    imageUrl: user!.photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const StripeTile(
                        color: AppColors.terracotta,
                        width: 56,
                        height: 56,
                        borderRadius:
                            BorderRadius.all(Radius.circular(28))),
                    errorWidget: (_, __, ___) => const StripeTile(
                        color: AppColors.terracotta,
                        width: 56,
                        height: 56,
                        borderRadius:
                            BorderRadius.all(Radius.circular(28))),
                  )
                : const StripeTile(
                    color: AppColors.terracotta,
                    width: 56,
                    height: 56,
                    borderRadius:
                        BorderRadius.all(Radius.circular(28))),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: user == null
              ? _buildNameShimmer()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName.isNotEmpty
                          ? user.displayName
                          : 'Explorer',
                      style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink),
                    ),
                    Row(
                      children: [
                        Text(
                          '@${user.username.isNotEmpty ? user.username : 'local'}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.warmGrey),
                        ),
                        if (user.countryCode.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.parchment,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(user.countryCode,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _tierColor(user.tier)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _tierColor(user.tier)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _tierLabel(user.tier).toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _tierColor(user.tier),
                            letterSpacing: 1.2),
                      ),
                    ),
                  ],
                ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.ink),
          onPressed: () =>
              Navigator.pushNamed(context, RouteNames.kSettings),
        ),
      ],
    ),
  );
}

Widget _buildNameShimmer() {
  return Shimmer.fromColors(
    baseColor: const Color(0xFFE0D9D0),
    highlightColor: const Color(0xFFF5EFE6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            width: 120,
            height: 18,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 6),
        Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4))),
      ],
    ),
  );
}
```

Replace the `_buildPassport` method:

```dart
Widget _buildPassport(dynamic user) {
  if (user == null) return const SizedBox.shrink();

  final countryId = user.onboardingCountryId as String;
  if (countryId.isEmpty) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Dining Passport'),
          const SizedBox(height: 8),
          Text('Complete onboarding to unlock your passport',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.warmGrey)),
        ],
      ),
    );
  }

  final country = kSupportedCountries.firstWhere(
    (c) => c['id'] == countryId,
    orElse: () => {'id': countryId, 'name': countryId, 'code': ''},
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: SectionLabel('Dining Passport'),
      ),
      SizedBox(
        height: 36,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.lightGrey),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((country['code'] as String).isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.parchment,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(country['code'] as String,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(country['name'] as String,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.ink)),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
```

Update the `build` method's `_buildPassport` call — change `_buildPassport()` → `_buildPassport(user)`:

```dart
SliverToBoxAdapter(child: _buildPassport(user)),
```

Also add missing imports at the top of `profile_screen.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_constants.dart';
```

- [ ] **Step 2: Run `flutter analyze`**

```
flutter analyze lib/screens/profile/profile_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/profile/profile_screen.dart
git commit -m "feat: profile screen — shimmer loading, real username/countryCode subtitle, real passport from onboarding"
```

---

## Self-Review Checklist

After completing all tasks, run:

```bash
flutter analyze lib/
```

Expected: `No issues found!`

Then do a manual smoke test:
- [ ] Register a new account → goes to onboarding (not main)
- [ ] Onboarding page 1: back button returns to register
- [ ] Onboarding page 4: shows country list with ISO codes
- [ ] Onboarding last page: shows polished card with vibes + country + budget
- [ ] Main app: FAB visible on Atlas and ForYou, hidden on Stories/Trips/Profile
- [ ] Atlas screen: tapping PFP switches to Profile tab
- [ ] Atlas screen: city chips show cities for selected country
- [ ] Atlas screen: search banner shows dark banner with country name
- [ ] Trips screen: "Plan Trip" button in header, tapping shows Coming Soon
- [ ] Profile screen: shows real name (shimmer while loading), username, country code badge, passport chip
