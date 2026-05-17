# DiningAtlas — Bedo's UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire every screen in DiningAtlas to real providers, build all missing screens (onboarding, chat, add place, settings, premium), and ship a fully navigable app with real data flowing end-to-end.

**Architecture:** All screens consume providers via `context.watch<XProvider>()` and call provider methods on interaction. Screens never call Firebase directly — only through providers. During Phase 1, providers are backed by mock services (Joe writes these on Day 1). When Joe ships real Firebase services, screens require zero changes.

**Tech Stack:** Flutter/Dart, Provider, Google Maps Flutter, cached_network_image, shimmer, connectivity_plus

---

## Phase 1 — Foundation (Day 1, do before anything else)

---

### Task 1: Set up named routing and wire all providers into main.dart

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/core/constants/route_names.dart` *(coordinate with Joe — he creates this, you consume it)*

- [ ] **Step 1: Add missing packages to pubspec.yaml**

```yaml
dependencies:
  shimmer: ^3.0.0
  connectivity_plus: ^6.0.0
  cached_network_image: ^3.3.0
  google_maps_flutter: ^2.5.0
```

Run: `flutter pub get`

- [ ] **Step 2: Set up Google Maps API key**

Android — add to `android/app/src/main/AndroidManifest.xml` inside `<application>`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

iOS — add to `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

- [ ] **Step 3: Update `lib/main.dart` with named routes**

Replace the `MaterialApp` routes section with `onGenerateRoute`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/constants/route_names.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/onboarding/onboarding_shell.dart';
import 'screens/restaurant/restaurant_detail_screen.dart';
import 'screens/restaurant/write_review_screen.dart';
import 'screens/restaurant/add_place_screen.dart';
import 'screens/map/map_search_screen.dart';
import 'screens/chat/chat_thread_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/premium/premium_upgrade_screen.dart';
import 'screens/auth/auth_gate.dart';
import 'models/restaurant_model.dart';

// main() and providers registered by Joe in main.dart
// Bedo owns the route table only

Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case RouteNames.kLogin:
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case RouteNames.kRegister:
      return MaterialPageRoute(builder: (_) => const RegisterScreen());
    case RouteNames.kForgotPassword:
      return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
    case RouteNames.kOnboarding:
      return MaterialPageRoute(builder: (_) => const OnboardingShell());
    case RouteNames.kRestaurantDetail:
      final restaurant = settings.arguments as RestaurantModel;
      return MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: restaurant));
    case RouteNames.kWriteReview:
      final restaurant = settings.arguments as RestaurantModel;
      return MaterialPageRoute(builder: (_) => WriteReviewScreen(restaurant: restaurant));
    case RouteNames.kAddPlace:
      return MaterialPageRoute(builder: (_) => const AddPlaceScreen());
    case RouteNames.kMapSearch:
      return MaterialPageRoute(builder: (_) => const MapSearchScreen());
    case RouteNames.kChatThread:
      final args = settings.arguments as Map<String, String>;
      return MaterialPageRoute(builder: (_) => ChatThreadScreen(
        otherUid: args['otherUid']!,
        placeId: args['placeId']!,
        otherName: args['otherName']!,
      ));
    case RouteNames.kSettings:
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    case RouteNames.kPremiumUpgrade:
      return MaterialPageRoute(builder: (_) => const PremiumUpgradeScreen());
    default:
      return MaterialPageRoute(builder: (_) => const AuthGate());
  }
}
```

Add `onGenerateRoute: generateRoute` to your `MaterialApp`.

- [ ] **Step 4: Update `AuthGate` to check `onboardingComplete`**

In `lib/screens/auth/auth_gate.dart`, after confirming the user is authenticated, check `UserProvider` for `onboardingComplete`. If false, push `RouteNames.kOnboarding`.

```dart
// Inside AuthGate, after user is confirmed authenticated:
final userProvider = context.read<UserProvider>();
await userProvider.loadUser(firebaseUser.uid);
if (!(userProvider.user?.onboardingComplete ?? true)) {
  Navigator.pushReplacementNamed(context, RouteNames.kOnboarding);
  return;
}
// else show main shell
```

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/screens/auth/auth_gate.dart android/app/src/main/AndroidManifest.xml ios/Runner/AppDelegate.swift pubspec.yaml pubspec.lock
git commit -m "feat: set up named routing and Google Maps API key"
```

---

## Phase 2 — Onboarding Screens

### Task 2: Onboarding shell and vibe selector

**Files:**
- Create: `lib/screens/onboarding/onboarding_shell.dart`
- Create: `lib/screens/onboarding/vibe_selector_screen.dart`
- Create: `lib/screens/onboarding/budget_screen.dart`
- Create: `lib/screens/onboarding/atmosphere_screen.dart`
- Create: `lib/screens/onboarding/city_screen.dart`
- Create: `lib/screens/onboarding/profile_ready_screen.dart`

- [ ] **Step 1: Create `lib/screens/onboarding/onboarding_shell.dart`**

```dart
import 'package:flutter/material.dart';
import 'vibe_selector_screen.dart';
import 'budget_screen.dart';
import 'atmosphere_screen.dart';
import 'city_screen.dart';
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
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _controller.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6), // AppColors.cream
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i == _currentPage
                        ? const Color(0xFFC17B4E) // AppColors.terracotta
                        : const Color(0xFFCCC5B9),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  VibeSelectorScreen(onNext: _next),
                  BudgetScreen(onNext: _next, onBack: _back),
                  AtmosphereScreen(onNext: _next, onBack: _back),
                  CityScreen(onNext: _next, onBack: _back),
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

- [ ] **Step 2: Create `lib/screens/onboarding/vibe_selector_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';

const _kVibes = [
  {'id': 'hidden_cafe', 'label': 'Hidden Café', 'emoji': '☕'},
  {'id': 'street_food', 'label': 'Street Food', 'emoji': '🌮'},
  {'id': 'rooftop_bar', 'label': 'Rooftop Bar', 'emoji': '🍸'},
  {'id': 'local_market', 'label': 'Local Market', 'emoji': '🛒'},
  {'id': 'art_gallery', 'label': 'Art Gallery', 'emoji': '🎨'},
  {'id': 'night_life', 'label': 'Nightlife', 'emoji': '🎵'},
  {'id': 'fine_dining', 'label': 'Fine Dining', 'emoji': '🍽️'},
  {'id': 'nature_spot', 'label': 'Nature Spot', 'emoji': '🌿'},
];

class VibeSelectorScreen extends StatelessWidget {
  final VoidCallback onNext;
  const VibeSelectorScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What\'s your vibe?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Pick everything that speaks to you.',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B6560))),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: _kVibes.map((vibe) {
                final selected = provider.vibes.contains(vibe['id']);
                return GestureDetector(
                  onTap: () {
                    final current = List<String>.from(provider.vibes);
                    if (selected) current.remove(vibe['id']);
                    else current.add(vibe['id']!);
                    provider.vibes = current;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFC17B4E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? const Color(0xFFC17B4E) : const Color(0xFFE0D9D0),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(vibe['emoji']!, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(vibe['label']!,
                            style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : const Color(0xFF2C2825),
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.vibes.isNotEmpty ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC17B4E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create `lib/screens/onboarding/budget_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';

class BudgetScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const BudgetScreen({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final options = [
      {'\$': 'Under 100 EGP'},
      {'\$\$': '100 – 300 EGP'},
      {'\$\$\$': '300+ EGP'},
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What\'s your budget?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Per meal or outing, roughly.',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B6560))),
          const SizedBox(height: 32),
          ...options.map((opt) {
            final key = opt.keys.first;
            final label = opt.values.first;
            final selected = provider.budget == key;
            return GestureDetector(
              onTap: () => provider.budget = key,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFC17B4E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? const Color(0xFFC17B4E) : const Color(0xFFE0D9D0),
                  ),
                ),
                child: Row(
                  children: [
                    Text(key, style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFFC17B4E),
                    )),
                    const SizedBox(width: 16),
                    Text(label, style: TextStyle(
                      fontSize: 16,
                      color: selected ? Colors.white : const Color(0xFF2C2825),
                    )),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          Row(children: [
            TextButton(onPressed: onBack, child: const Text('Back')),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC17B4E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue', style: TextStyle(color: Colors.white, fontSize: 16)),
            )),
          ]),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Create `lib/screens/onboarding/atmosphere_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';

const _kAtmospheres = [
  {'id': 'quiet', 'label': 'Quiet & intimate'},
  {'id': 'lively', 'label': 'Lively & social'},
  {'id': 'outdoor', 'label': 'Outdoor & scenic'},
  {'id': 'artsy', 'label': 'Artsy & alternative'},
  {'id': 'family', 'label': 'Family-friendly'},
  {'id': 'late_night', 'label': 'Late night'},
];

class AtmosphereScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const AtmosphereScreen({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What\'s the vibe you\'re after?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Pick all that fit you.',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B6560))),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _kAtmospheres.map((a) {
              final selected = provider.atmosphere.contains(a['id']);
              return FilterChip(
                label: Text(a['label']!),
                selected: selected,
                onSelected: (_) {
                  final current = List<String>.from(provider.atmosphere);
                  if (selected) current.remove(a['id']);
                  else current.add(a['id']!);
                  provider.atmosphere = current;
                },
                selectedColor: const Color(0xFFC17B4E),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF2C2825),
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected ? const Color(0xFFC17B4E) : const Color(0xFFE0D9D0),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          Row(children: [
            TextButton(onPressed: onBack, child: const Text('Back')),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: provider.atmosphere.isNotEmpty ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC17B4E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue', style: TextStyle(color: Colors.white, fontSize: 16)),
            )),
          ]),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Create `lib/screens/onboarding/city_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';

const _kCities = [
  {'id': 'cairo', 'name': 'Cairo', 'flag': '🇪🇬'},
  {'id': 'tokyo', 'name': 'Tokyo', 'flag': '🇯🇵'},
  {'id': 'lisbon', 'name': 'Lisbon', 'flag': '🇵🇹'},
  {'id': 'bangkok', 'name': 'Bangkok', 'flag': '🇹🇭'},
  {'id': 'rome', 'name': 'Rome', 'flag': '🇮🇹'},
  {'id': 'mexico_city', 'name': 'Mexico City', 'flag': '🇲🇽'},
];

class CityScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const CityScreen({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Where are you headed?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Pick your city to start exploring.',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B6560))),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(children: _kCities.map((city) {
              final selected = provider.cityId == city['id'];
              return GestureDetector(
                onTap: () => provider.cityId = city['id']!,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFC17B4E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? const Color(0xFFC17B4E) : const Color(0xFFE0D9D0),
                    ),
                  ),
                  child: Row(children: [
                    Text(city['flag']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Text(city['name']!, style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF2C2825),
                    )),
                  ]),
                ),
              );
            }).toList()),
          ),
          Row(children: [
            TextButton(onPressed: onBack, child: const Text('Back')),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC17B4E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue', style: TextStyle(color: Colors.white, fontSize: 16)),
            )),
          ]),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Create `lib/screens/onboarding/profile_ready_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/route_names.dart';

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
          const Text('Your taste profile is ready!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ...onboarding.vibes.map((v) => Chip(label: Text(v.replaceAll('_', ' ')))),
              Chip(label: Text(onboarding.budget)),
              ...onboarding.atmosphere.map((a) => Chip(label: Text(a.replaceAll('_', ' ')))),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onboarding.isLoading ? null : () async {
                final uid = auth.user?.uid;
                if (uid == null) return;
                await onboarding.completeOnboarding(uid);
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, RouteNames.kMain);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC17B4E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: onboarding.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Let's go!", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Commit**

```bash
git add lib/screens/onboarding/
git commit -m "feat: add all 5 onboarding screens with OnboardingProvider wiring"
```

---

## Phase 2 — Wire Existing Screens to Providers

### Task 3: Wire AtlasScreen (home feed) to RestaurantProvider

**Files:**
- Modify: `lib/screens/home/atlas_screen.dart` *(currently at `lib/screens/atlas_screen.dart` — move to `lib/screens/home/`)*

- [ ] **Step 1: Move `atlas_screen.dart` to `lib/screens/home/atlas_screen.dart`**

Create `lib/screens/home/` directory and move the file. Update all imports.

- [ ] **Step 2: Replace hardcoded restaurant list with provider data**

At the top of `AtlasScreen`'s `build` method, add:
```dart
final restaurantProvider = context.watch<RestaurantProvider>();
```

Replace hardcoded `_editorPicks` list with `restaurantProvider.feed`.

In `initState` (or wrap in `didChangeDependencies`), trigger:
```dart
Future.microtask(() => context.read<RestaurantProvider>().loadFeed(cityId: 'tokyo'));
```

- [ ] **Step 3: Add loading shimmer while feed fetches**

```dart
if (restaurantProvider.isLoading)
  SliverToBoxAdapter(child: _FeedShimmer())
else if (restaurantProvider.feed.isEmpty)
  const SliverToBoxAdapter(child: Center(child: Text('No places found.')))
else
  SliverList(...)
```

`_FeedShimmer` widget:
```dart
class _FeedShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0D9D0),
      highlightColor: const Color(0xFFF5EFE6),
      child: Column(
        children: List.generate(3, (_) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        )),
      ),
    );
  }
}
```

- [ ] **Step 4: Wire city chip tap to `RestaurantProvider.loadFeed(cityId: ...)`**

```dart
GestureDetector(
  onTap: () => context.read<RestaurantProvider>().loadFeed(cityId: city['id']),
  child: _CityChip(city: city, selected: restaurantProvider.currentCityId == city['id']),
)
```

- [ ] **Step 5: Wire restaurant card tap to navigate to detail**

```dart
onTap: () => Navigator.pushNamed(
  context,
  RouteNames.kRestaurantDetail,
  arguments: restaurant,
),
```

- [ ] **Step 6: Commit**

```bash
git add lib/screens/home/atlas_screen.dart
git commit -m "feat: wire AtlasScreen to RestaurantProvider with shimmer and city filter"
```

---

### Task 4: Wire RestaurantDetailScreen — real data, reviews tab, save button, AI summary

**Files:**
- Modify: `lib/screens/restaurant/restaurant_detail_screen.dart`

- [ ] **Step 1: Move to `lib/screens/restaurant/` and accept `RestaurantModel` argument**

```dart
class RestaurantDetailScreen extends StatefulWidget {
  final RestaurantModel restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});
  ...
}
```

- [ ] **Step 2: Load reviews and AI summary on init**

```dart
@override
void initState() {
  super.initState();
  Future.microtask(() {
    context.read<ReviewProvider>().loadReviews(widget.restaurant.id);
    context.read<AiProvider>().loadSummary(widget.restaurant.id);
  });
}
```

- [ ] **Step 3: Wire the Reviews tab to real ReviewProvider data**

```dart
final reviewProvider = context.watch<ReviewProvider>();
final reviews = reviewProvider.reviewsFor(widget.restaurant.id);

if (reviewProvider.isLoading)
  const Center(child: CircularProgressIndicator())
else
  ListView.builder(
    itemCount: reviews.length,
    itemBuilder: (_, i) => _ReviewCard(
      review: reviews[i],
      onUpvote: () => reviewProvider.upvote(
        restaurantId: widget.restaurant.id, reviewId: reviews[i].id,
      ),
      onTranslate: () => reviewProvider.translate(
        restaurantId: widget.restaurant.id,
        reviewId: reviews[i].id,
        text: reviews[i].text,
        targetLang: Localizations.localeOf(context).languageCode,
      ),
      translation: reviewProvider.translationFor(reviews[i].id, Localizations.localeOf(context).languageCode),
    ),
  )
```

- [ ] **Step 4: Wire the Save button to SavedPlacesProvider**

```dart
final savedProvider = context.watch<SavedPlacesProvider>();
final authProvider = context.read<AuthProvider>();

IconButton(
  icon: Icon(
    savedProvider.isSaved(widget.restaurant.id) ? Icons.bookmark : Icons.bookmark_border,
    color: savedProvider.isSaved(widget.restaurant.id)
        ? const Color(0xFFC17B4E) : null,
  ),
  onPressed: () async {
    try {
      await savedProvider.toggleSave(
        uid: authProvider.user!.uid,
        restaurant: widget.restaurant,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  },
)
```

- [ ] **Step 5: Add AI Summary card at top of reviews tab**

```dart
class _AiSummaryCard extends StatelessWidget {
  final String restaurantId;
  const _AiSummaryCard({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AiProvider>();
    final summary = aiProvider.summaryFor(restaurantId);

    if (aiProvider.isGenerating) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFFE0D9D0),
        highlightColor: const Color(0xFFF5EFE6),
        child: Container(height: 120, margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
      );
    }
    if (summary == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A7C6F).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A7C6F).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF4A7C6F)),
          const SizedBox(width: 6),
          const Text('AI Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF4A7C6F))),
        ]),
        const SizedBox(height: 8),
        Text(summary.vibeOneLiner, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: summary.topAspects.map((a) =>
          Chip(label: Text(a, style: const TextStyle(fontSize: 11)), padding: EdgeInsets.zero)
        ).toList()),
        if (summary.caveats.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Watch out: ${summary.caveats.join(', ')}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B6560))),
        ],
        Text('Best time: ${summary.bestTime}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6560))),
      ]),
    );
  }
}
```

- [ ] **Step 6: Wire "Write Review" button**

```dart
ElevatedButton(
  onPressed: () => Navigator.pushNamed(
    context, RouteNames.kWriteReview, arguments: widget.restaurant,
  ),
  child: const Text('Write a Review'),
)
```

- [ ] **Step 7: Wire "Message" button to open chat**

```dart
TextButton.icon(
  onPressed: () => Navigator.pushNamed(
    context, RouteNames.kChatThread,
    arguments: {
      'otherUid': widget.restaurant.contributorId,
      'placeId': widget.restaurant.id,
      'otherName': 'Local',
    },
  ),
  icon: const Icon(Icons.chat_bubble_outline),
  label: const Text('Ask a local'),
)
```

- [ ] **Step 8: Commit**

```bash
git add lib/screens/restaurant/restaurant_detail_screen.dart
git commit -m "feat: wire RestaurantDetailScreen — reviews, save, AI summary, chat, write review"
```

---

### Task 5: Wire WriteReviewScreen submission

**Files:**
- Modify: `lib/screens/restaurant/write_review_screen.dart`

- [ ] **Step 1: Accept `RestaurantModel` and wire `_onPost()` to `ReviewProvider`**

```dart
class WriteReviewScreen extends StatefulWidget {
  final RestaurantModel restaurant;
  const WriteReviewScreen({super.key, required this.restaurant});
  ...
}
```

- [ ] **Step 2: Implement `_onPost()`**

```dart
Future<void> _onPost() async {
  if (!_formKey.currentState!.validate()) return;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not submit: ${e.toString()}')),
    );
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}
```

- [ ] **Step 3: Implement `_onAddPhoto()` with image picker**

```dart
import 'package:image_picker/image_picker.dart';

Future<void> _onAddPhoto() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
  if (picked == null) return;
  setState(() => _photos.add(File(picked.path)));
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/screens/restaurant/write_review_screen.dart
git commit -m "feat: wire WriteReviewScreen to ReviewProvider and image picker"
```

---

### Task 6: New screen — AddPlaceScreen (multi-step form)

**Files:**
- Create: `lib/screens/restaurant/add_place_screen.dart`

- [ ] **Step 1: Create `lib/screens/restaurant/add_place_screen.dart`**

```dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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

  // Step 1 fields
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _tipController = TextEditingController();
  final _dishController = TextEditingController();
  String _category = 'Restaurant';
  String _priceRange = '\$\$';

  // Step 2 — location (simplified: lat/lng text input for now)
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _neighborhoodController = TextEditingController();

  // Step 3 — photos
  final List<File> _photos = [];

  bool _isSubmitting = false;

  final _categories = ['Restaurant', 'Cafe', 'Street Food', 'Bar', 'Market', 'Nature', 'Art'];
  final _priceTiers = ['\$', '\$\$', '\$\$\$'];

  void _next() {
    if (_step < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
        tileColor: const Color(0xFF4A7C6F),
        tagline: _descController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await context.read<RestaurantProvider>().addRestaurant(restaurant);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place submitted! It will be reviewed shortly.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add a Place (${_step + 1}/3)'),
        backgroundColor: const Color(0xFFF5EFE6),
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

  Widget _step1Info() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Place name *')),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _category,
        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => _category = v!),
        decoration: const InputDecoration(labelText: 'Category'),
      ),
      const SizedBox(height: 16),
      TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description *')),
      const SizedBox(height: 16),
      TextField(controller: _tipController, decoration: const InputDecoration(labelText: "Local tip (insider advice)")),
      const SizedBox(height: 16),
      TextField(controller: _dishController, decoration: const InputDecoration(labelText: "Recommended dish")),
      const SizedBox(height: 16),
      Row(children: _priceTiers.map((p) {
        final sel = _priceRange == p;
        return GestureDetector(
          onTap: () => setState(() => _priceRange = p),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFFC17B4E) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sel ? const Color(0xFFC17B4E) : const Color(0xFFE0D9D0)),
            ),
            child: Text(p, style: TextStyle(color: sel ? Colors.white : null, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList()),
      const SizedBox(height: 32),
      _NextButton(onTap: _nameController.text.isNotEmpty ? _next : null),
    ]),
  );

  Widget _step2Location() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(children: [
      TextField(controller: _neighborhoodController, decoration: const InputDecoration(labelText: 'Neighborhood *')),
      const SizedBox(height: 16),
      TextField(controller: _latController, decoration: const InputDecoration(labelText: 'Latitude'), keyboardType: TextInputType.number),
      const SizedBox(height: 16),
      TextField(controller: _lngController, decoration: const InputDecoration(labelText: 'Longitude'), keyboardType: TextInputType.number),
      const Spacer(),
      _NextButton(onTap: _next),
    ]),
  );

  Widget _step3Photos() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(children: [
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
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) setState(() => _photos.add(File(picked.path)));
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0D9D0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_photo_alternate_outlined, size: 32, color: Color(0xFF6B6560)),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _isSubmitting
          ? const CircularProgressIndicator()
          : _NextButton(label: 'Submit Place', onTap: _next),
    ]),
  );
}

class _NextButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  const _NextButton({this.onTap, this.label = 'Continue'});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFC17B4E),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
    ),
  );
}
```

- [ ] **Step 2: Add `addRestaurant` method to `RestaurantProvider`**

In `lib/providers/restaurant_provider.dart`, add:
```dart
Future<void> addRestaurant(RestaurantModel restaurant) async {
  await _service.addRestaurant(restaurant);
}
```

- [ ] **Step 3: Add "Add Place" FAB to `AtlasScreen`**

```dart
floatingActionButton: FloatingActionButton(
  backgroundColor: const Color(0xFFC17B4E),
  onPressed: () => Navigator.pushNamed(context, RouteNames.kAddPlace),
  child: const Icon(Icons.add, color: Colors.white),
),
```

- [ ] **Step 4: Commit**

```bash
git add lib/screens/restaurant/add_place_screen.dart lib/providers/restaurant_provider.dart lib/screens/home/atlas_screen.dart
git commit -m "feat: add AddPlaceScreen multi-step form with FAB"
```

---

### Task 7: Real map with Google Maps Flutter

**Files:**
- Modify: `lib/screens/map/map_search_screen.dart`

- [ ] **Step 1: Replace custom-painted map with GoogleMap widget**

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/location_provider.dart'; // Joe creates this

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});
  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadNearby());
  }

  Future<void> _loadNearby() async {
    final locationProvider = context.read<LocationProvider>();
    final pos = await locationProvider.getCurrentPosition();
    if (pos == null || !mounted) return;
    await context.read<RestaurantProvider>().loadNearby(pos);
    _buildMarkers();
  }

  void _buildMarkers() {
    final restaurants = context.read<RestaurantProvider>().feed;
    setState(() {
      _markers = restaurants.map((r) => Marker(
        markerId: MarkerId(r.id),
        position: LatLng(r.geopoint.latitude, r.geopoint.longitude),
        infoWindow: InfoWindow(title: r.name, snippet: r.priceRange),
        onTap: () => Navigator.pushNamed(context, RouteNames.kRestaurantDetail, arguments: r),
      )).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(35.6762, 139.6503),
            zoom: 14,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          onMapCreated: (c) => _mapController = c,
        ),
        // Cuisine filter chips overlay at bottom
        Positioned(
          bottom: 80,
          left: 0, right: 0,
          child: _CuisineFilterBar(),
        ),
      ]),
    );
  }
}

class _CuisineFilterBar extends StatelessWidget {
  final _filters = ['All', 'Japanese', 'Cafe', 'Street Food', 'Bar'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: _filters.map((f) => GestureDetector(
        onTap: () {
          if (f == 'All') {
            context.read<RestaurantProvider>().loadFeed(cityId: context.read<RestaurantProvider>().currentCityId);
          } else {
            context.read<RestaurantProvider>().fetchByCategory(f);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Text(f, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      )).toList()),
    );
  }
}
```

- [ ] **Step 2: Add `fetchByCategory` to `RestaurantProvider`**

```dart
Future<void> fetchByCategory(String category) async {
  _isLoading = true;
  notifyListeners();
  try {
    _feed = await _service.fetchByCategory(category: category, cityId: _currentCityId);
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/map/map_search_screen.dart lib/providers/restaurant_provider.dart
git commit -m "feat: replace custom map with Google Maps Flutter and real nearby data"
```

---

### Task 8: New screen — ChatThreadScreen

**Files:**
- Create: `lib/screens/chat/chat_thread_screen.dart`

- [ ] **Step 1: Create `lib/screens/chat/chat_thread_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_model.dart';

class ChatThreadScreen extends StatefulWidget {
  final String otherUid;
  final String placeId;
  final String otherName;
  const ChatThreadScreen({super.key, required this.otherUid, required this.placeId, required this.otherName});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = context.read<AuthProvider>();
      context.read<ChatProvider>().openChat(
        currentUid: auth.user!.uid,
        otherUid: widget.otherUid,
        placeId: widget.placeId,
      );
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthProvider>();
    context.read<ChatProvider>().sendMessage(senderId: auth.user!.uid, text: text);
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final auth = context.read<AuthProvider>();
    final myUid = auth.user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.otherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Text('Local contributor', style: TextStyle(fontSize: 12, color: Color(0xFF6B6560))),
        ]),
        backgroundColor: const Color(0xFFF5EFE6),
        elevation: 0,
      ),
      body: Column(children: [
        Expanded(
          child: chatProvider.messagesStream == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<List<MessageModel>>(
                stream: chatProvider.messagesStream,
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final messages = snap.data!;
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _MessageBubble(
                      message: messages[i],
                      isMe: messages[i].senderId == myUid,
                      translation: chatProvider.translationFor(messages[i].id, 'en'),
                      onTranslate: () => chatProvider.translateMessage(
                        messageId: messages[i].id,
                        text: messages[i].text,
                        targetLang: 'en',
                      ),
                    ),
                  );
                },
              ),
        ),
        _ChatInputBar(controller: _controller, onSend: _send),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? translation;
  final VoidCallback onTranslate;
  const _MessageBubble({required this.message, required this.isMe, this.translation, required this.onTranslate});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFC17B4E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message.text, style: TextStyle(color: isMe ? Colors.white : const Color(0xFF2C2825))),
          if (translation != null) ...[
            const Divider(height: 8),
            Text(translation!, style: TextStyle(
              color: isMe ? Colors.white70 : const Color(0xFF6B6560), fontSize: 12, fontStyle: FontStyle.italic,
            )),
          ],
          if (!isMe && translation == null)
            GestureDetector(
              onTap: onTranslate,
              child: const Text('Translate', style: TextStyle(fontSize: 11, color: Color(0xFF4A7C6F), decoration: TextDecoration.underline)),
            ),
        ]),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _ChatInputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(children: [
        Expanded(child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Ask the local...',
            filled: true, fillColor: const Color(0xFFF5EFE6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onSubmitted: (_) => onSend(),
        )),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onSend,
          icon: const Icon(Icons.send_rounded),
          style: IconButton.styleFrom(backgroundColor: const Color(0xFFC17B4E), foregroundColor: Colors.white),
        ),
      ]),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/chat/chat_thread_screen.dart
git commit -m "feat: add ChatThreadScreen with real-time messages and inline translation"
```

---

### Task 9: New screen — SettingsScreen

**Files:**
- Create: `lib/screens/profile/settings_screen.dart`

- [ ] **Step 1: Create `lib/screens/profile/settings_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../core/constants/route_names.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFF5EFE6),
        elevation: 0,
      ),
      body: ListView(children: [
        // Chat privacy section
        const _SectionHeader(title: 'Chat Privacy'),
        RadioListTile<String>(
          title: const Text('Public — Anyone can message me'),
          value: 'public',
          groupValue: user?.chatPrivacy.mode ?? 'public',
          onChanged: (v) => _updateChatMode(context, v!, user),
        ),
        RadioListTile<String>(
          title: const Text('Private — No messages'),
          value: 'private',
          groupValue: user?.chatPrivacy.mode ?? 'public',
          onChanged: (v) => _updateChatMode(context, v!, user),
        ),
        RadioListTile<String>(
          title: const Text('Scheduled — Set availability hours'),
          value: 'scheduled',
          groupValue: user?.chatPrivacy.mode ?? 'public',
          onChanged: (v) => _updateChatMode(context, v!, user),
        ),

        const Divider(),
        const _SectionHeader(title: 'Subscription'),
        ListTile(
          title: const Text('Upgrade to Premium'),
          subtitle: const Text('Unlimited saves, AI features, no ads'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, RouteNames.kPremiumUpgrade),
        ),

        const Divider(),
        const _SectionHeader(title: 'Account'),
        ListTile(
          title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          onTap: () async {
            await context.read<AuthProvider>().signOut();
            if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, RouteNames.kLogin, (_) => false);
          },
        ),
      ]),
    );
  }

  void _updateChatMode(BuildContext context, String mode, UserModel? user) {
    if (user == null) return;
    context.read<UserProvider>().updateChatPrivacy(ChatPrivacy(mode: mode));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(title, style: const TextStyle(
      fontSize: 12, fontWeight: FontWeight.w700,
      color: Color(0xFF6B6560), letterSpacing: 0.8,
    )),
  );
}
```

- [ ] **Step 2: Wire settings link in Profile screen's drawer or top bar**

```dart
IconButton(
  icon: const Icon(Icons.settings_outlined),
  onPressed: () => Navigator.pushNamed(context, RouteNames.kSettings),
)
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/profile/settings_screen.dart lib/screens/profile/profile_screen.dart
git commit -m "feat: add SettingsScreen with chat privacy and sign out"
```

---

### Task 10: New screen — PremiumUpgradeScreen

**Files:**
- Create: `lib/screens/premium/premium_upgrade_screen.dart`

- [ ] **Step 1: Create `lib/screens/premium/premium_upgrade_screen.dart`**

```dart
import 'package:flutter/material.dart';

class PremiumUpgradeScreen extends StatelessWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2825),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Text('DiningAtlas Premium',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Experience cities like a true local.',
                style: TextStyle(color: Color(0xFFCCC5B9), fontSize: 16)),
            const SizedBox(height: 40),
            ...[
              ('Unlimited saves', Icons.bookmark),
              ('Full AI recommendations', Icons.auto_awesome),
              ('Unlimited translations', Icons.translate),
              ('Unlimited chat messages', Icons.chat),
              ('No ads', Icons.block),
              ('Offline city cache', Icons.wifi_off),
            ].map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(children: [
                Icon(f.$2, color: const Color(0xFFC17B4E), size: 20),
                const SizedBox(width: 16),
                Text(f.$1, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ]),
            )),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFC17B4E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                const Text('Monthly', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const Text('EGP 49 / month', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment integration coming soon!')),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Upgrade Now', style: TextStyle(color: Color(0xFFC17B4E), fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/premium/premium_upgrade_screen.dart
git commit -m "feat: add PremiumUpgradeScreen"
```

---

### Task 11: Wire ProfileScreen to real UserProvider data

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart`

- [ ] **Step 1: Load user and saved places on init**

```dart
@override
void initState() {
  super.initState();
  Future.microtask(() {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      context.read<UserProvider>().loadUser(auth.user!.uid);
      context.read<SavedPlacesProvider>().loadSaved(auth.user!.uid);
    }
  });
}
```

- [ ] **Step 2: Replace hardcoded stats with real provider data**

```dart
final user = context.watch<UserProvider>().user;
final savedCount = context.watch<SavedPlacesProvider>().savedIds.length;

// Replace hardcoded stats:
Text(user?.score.toString() ?? '0')  // score
Text(user?.tier ?? 'Explorer')       // tier badge
Text(savedCount.toString())          // saved count
```

- [ ] **Step 3: Show tier badge correctly**

```dart
String _tierLabel(String tier) => switch (tier) {
  'local' => 'Local',
  'super_local' => 'Super Local',
  'city_legend' => 'City Legend',
  _ => 'Explorer',
};

Color _tierColor(String tier) => switch (tier) {
  'local' => const Color(0xFF4A7C6F),
  'super_local' => const Color(0xFFC17B4E),
  'city_legend' => const Color(0xFF8B6914),
  _ => const Color(0xFF6B6560),
};
```

- [ ] **Step 4: Commit**

```bash
git add lib/screens/profile/profile_screen.dart
git commit -m "feat: wire ProfileScreen to UserProvider and SavedPlacesProvider"
```

---

### Task 12: Wire TripsScreen to TripProvider

**Files:**
- Modify: `lib/screens/trips/trips_screen.dart`

- [ ] **Step 1: Load trips on init**

```dart
@override
void initState() {
  super.initState();
  Future.microtask(() {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) context.read<TripProvider>().loadTrips(auth.user!.uid);
  });
}
```

- [ ] **Step 2: Replace hardcoded trip data with provider data**

```dart
final tripProvider = context.watch<TripProvider>();
final trips = tripProvider.trips;

if (tripProvider.isLoading)
  const Center(child: CircularProgressIndicator())
else if (trips.isEmpty)
  const Center(child: Text('No trips yet. Plan your first!'))
else
  // Render first trip's days
  _TripView(trip: trips.first)
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/trips/trips_screen.dart
git commit -m "feat: wire TripsScreen to TripProvider"
```

---

## Phase 3 — Polish

### Task 13: Connectivity banner + offline handling

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/widgets/offline_banner.dart`

- [ ] **Step 1: Create `lib/widgets/offline_banner.dart`**

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline != _isOffline) setState(() => _isOffline = offline);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (_isOffline)
        Material(
          color: const Color(0xFF2C2825),
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: const Text(
                'Offline — showing cached content',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      Expanded(child: widget.child),
    ]);
  }
}
```

- [ ] **Step 2: Wrap the app body with `OfflineBanner` in `main.dart`**

```dart
home: OfflineBanner(child: const AuthGate()),
```

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/offline_banner.dart lib/main.dart
git commit -m "feat: add offline connectivity banner"
```

---

### Task 14: Replace stripe-tile placeholders with cached_network_image

**Files:**
- Modify: `lib/screens/home/atlas_screen.dart`
- Modify: `lib/screens/restaurant/restaurant_detail_screen.dart`
- Modify: `lib/screens/explore/for_you_screen.dart`

- [ ] **Step 1: Update every place image to use `CachedNetworkImage`**

For every widget that currently uses the diagonal-stripe `DecorationImage`, replace with:
```dart
import 'package:cached_network_image/cached_network_image.dart';

// In the image area:
restaurant.mediaUrls.isNotEmpty
  ? CachedNetworkImage(
      imageUrl: restaurant.mediaUrls.first,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: restaurant.tileColor),
      errorWidget: (_, __, ___) => Container(color: restaurant.tileColor),
    )
  : Container(color: restaurant.tileColor) // fallback stripe tile
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/
git commit -m "feat: replace stripe-tile placeholders with CachedNetworkImage"
```

---

### Task 15: Notification permission request on first launch

**Files:**
- Modify: `lib/screens/auth/auth_gate.dart`

- [ ] **Step 1: Request notification permission after login**

```dart
Future<void> _requestNotificationPermission() async {
  await context.read<NotificationProvider>().initialize();
  final token = await context.read<NotificationProvider>().getToken();
  // Store token on user doc via UserProvider if needed
}
```

Call `_requestNotificationPermission()` inside `AuthGate` after the user is confirmed authenticated.

- [ ] **Step 2: Commit**

```bash
git add lib/screens/auth/auth_gate.dart
git commit -m "feat: request notification permission and register FCM token on login"
```

---

## Self-Review Checklist

- [x] Task 1: Named routing complete — all 12 routes defined, auth gate checks onboardingComplete
- [x] Task 2: All 5 onboarding screens built, wired to OnboardingProvider
- [x] Task 3: AtlasScreen uses RestaurantProvider, shimmer, city filter, tap navigation
- [x] Task 4: RestaurantDetailScreen — reviews, save, AI summary, chat CTA, write review
- [x] Task 5: WriteReviewScreen submits real ReviewModel to provider
- [x] Task 6: AddPlaceScreen 3-step form, FAB wired in AtlasScreen
- [x] Task 7: MapSearchScreen uses Google Maps, real markers, category filter
- [x] Task 8: ChatThreadScreen real-time stream, send, translate chip
- [x] Task 9: SettingsScreen — chat privacy toggle, sign out, premium link
- [x] Task 10: PremiumUpgradeScreen feature list and CTA
- [x] Task 11: ProfileScreen — real user data, tier badge, saved count
- [x] Task 12: TripsScreen wired to TripProvider
- [x] Task 13: Offline banner via connectivity_plus
- [x] Task 14: CachedNetworkImage replaces all stripe tiles
- [x] Task 15: FCM permission request on login
- [x] No direct Firebase calls from any screen — all through providers
- [x] All `Navigator.pushNamed` calls use `RouteNames.*` constants
- [x] `RestaurantModel` passed as argument matches `fromFirestore` shape from Joe's plan
- [x] `ReviewModel` fields used in WriteReviewScreen match model in Joe's Task 1
- [x] `ChatPrivacy` used in SettingsScreen matches model definition in Joe's Task 1
