# DiningAtlas UI Enhancements — Design Spec

**Date:** 2026-05-18  
**Author:** Bedo  
**Scope:** UI-only changes across Auth, Onboarding, Atlas, Trips, and Profile screens  
**Developer:** Bedo (solo — no backend coordination needed with Joe)

---

## Overview

30+ targeted UI fixes and enhancements split across 3 phases following the user journey:

- **Phase 1 — Auth & Sign-Up**: register screen additions and flow fix
- **Phase 2 — Onboarding Flow**: all 5 onboarding pages updated
- **Phase 3 — Main App**: FAB visibility, Atlas redesign, Trips, Profile fixes

All changes are Bedo's domain (screens, widgets, constants, navigation). Backend service interfaces are not changed. Where new data fields are needed, they are added to models and wired through existing providers.

---

## Phase 1 — Auth & Sign-Up

### 1.1 Register Screen (`screens/auth/register_screen.dart`)

**New fields added (in order):**

1. **PFP Upload** — circular avatar at top of form. Taps `image_picker` to pick from gallery. Uploads to Firebase Storage on register success. Displays picked image in circle; fallback is a dashed terracotta border with camera icon.
2. **USERNAME** — `TextFormField` below Full Name. Validates: non-empty, alphanumeric + underscore only, min 3 chars. Uniqueness check deferred (Joe's backend concern).
3. **COUNTRY OF BIRTH** — tappable field (not a real text input) that opens a `showModalBottomSheet` with a scrollable `ListView` of all world countries. Stores the ISO-2 code (e.g. `EG`, `JP`, `US`). Displays country name in the field, ISO code shown in subtitle.

**Field order:** PFP → Full Name → Username → Country of Birth → Email → Password → Confirm Password

**Subtitle line change:** After register, the profile subtitle `@local · DiningAtlas` → `@<username> · <countryCode>` (e.g. `@maya · EG`).

**Post-register navigation:** On success, navigate to `RouteNames.kOnboarding` (not to `/`). The auth sign-up method already sets `onboardingComplete = false` via `UserModel` defaults, so `AuthGate` will redirect correctly on next launch — but after fresh register we push directly to onboarding without waiting for `AuthGate`.

**Model changes:**
- `UserModel`: add `username` (String) and `countryCode` (String, ISO-2) fields
- `UserModel.fromFirestore`: read with empty-string fallback
- `UserModel.toFirestore`: include both new fields
- `AuthProvider.signUp`: pass `username` and `countryCode` to user creation

### 1.2 Country Bottom Sheet (new private widget `_CountryPickerSheet`)

- Lives inside `register_screen.dart` as a private widget
- Full country list (hardcoded `List<Map>` with `name` and `code` fields)
- `ListView.builder` with `ListTile` rows showing name + ISO code badge
- On tap: pops with selected country map, controller and state update

---

## Phase 2 — Onboarding Flow

### 2.1 Vibe Selector (`screens/onboarding/vibe_selector_screen.dart`)

**New vibes added** (total 12, up from 8):

| id | label | emoji |
|---|---|---|
| hidden_cafe | Hidden Café | ☕ |
| street_food | Street Food | 🌮 |
| rooftop_bar | Rooftop Bar | 🍸 |
| local_market | Local Market | 🛒 |
| art_gallery | Art Gallery | 🎨 |
| night_life | Nightlife | 🎵 |
| fine_dining | Fine Dining | 🍽️ |
| nature_spot | Nature Spot | 🌿 |
| beach_vibes | Beach Vibes | 🏖️ |
| craft_beer | Craft Beer | 🍺 |
| wellness | Wellness | 🧘 |
| cultural | Cultural | 🎭 |

**Grid change:** `crossAxisCount` 2 → 3, `childAspectRatio` adjusted to ~1.1 to fit 3-col.

**Back button:** Add `onBack` callback parameter. In `OnboardingShell`, page 1 (VibeSelectorScreen) gets `onBack` that calls `Navigator.pop` to return to `RegisterScreen` (since onboarding is pushed from register, not replaced).

### 2.2 Budget Screen (`screens/onboarding/budget_screen.dart`)

**New options (4 tiers, USD):**

| key | label |
|---|---|
| `$` | Under $15 · Budget |
| `$$` | $15 – $50 · Mid-range |
| `$$$` | $50 – $100 · Upscale |
| `$$$$` | $100+ · Fine Dining |

Replace the hardcoded EGP list with the USD list above.

### 2.3 Destination Screen (rename + replace `screens/onboarding/city_screen.dart`)

**Rename file:** `city_screen.dart` → `destination_screen.dart`, class `CityScreen` → `DestinationScreen`.

**Screen copy:** "Where are you headed?" (keep), subtitle "Pick your destination." 

**Replace city list with 15 supported countries:**

| id | name | code |
|---|---|---|
| france | France | FR |
| spain | Spain | ES |
| united_states | United States | US |
| china | China | CN |
| italy | Italy | IT |
| turkey | Turkey | TR |
| mexico | Mexico | MX |
| thailand | Thailand | TH |
| germany | Germany | DE |
| united_kingdom | United Kingdom | GB |
| japan | Japan | JP |
| greece | Greece | GR |
| austria | Austria | AT |
| egypt | Egypt | EG |
| malaysia | Malaysia | MY |

**Row UI:** Country code badge (ISO-2, styled like a small tag) + country name. No emojis.

**Provider change:** `OnboardingProvider` — rename `cityId`/`setCity` → `countryId`/`setCountry`. Add `countryCode` getter that resolves ISO from selected `countryId`.

### 2.4 Onboarding Shell (`screens/onboarding/onboarding_shell.dart`)

- Update import: `CityScreen` → `DestinationScreen`
- Pass `onBack` to `VibeSelectorScreen` that calls `Navigator.pop(context)` (returns to register)
- No other shell changes needed (back button already wired on pages 2–4)

### 2.5 Profile Ready Screen (`screens/onboarding/profile_ready_screen.dart`)

Full redesign — replace the raw `Wrap` of chips with a polished card:

**Layout (top → bottom):**
1. Large celebration emoji (🎉)
2. Title: "You're all set!" (Fraunces, 28px, bold)
3. Subtitle: "Your taste profile is ready." (Fraunces, italic, terracotta)
4. **Profile summary card** (white, rounded, bordered):
   - "YOUR PROFILE" label (uppercase, warmGrey)
   - Vibe chips: terracotta-tinted pill per selected vibe (label with emoji, not raw id)
   - One-liner: `📍 <countryName>  ·  💰 <budgetLabel>`
5. CTA button: "Start Exploring" (full-width, terracotta)

Chip labels must be human-readable (map `hidden_cafe` → `Hidden Café` etc.) — add a `_vibeLabel` helper map inside the file.

---

## Phase 3 — Main App

### 3.1 FAB Visibility (`main.dart` — `MainShell`)

Change the `floatingActionButton` property:

```dart
floatingActionButton: _currentIndex <= 1
    ? FloatingActionButton(...)
    : null,
```

FAB shows only on Atlas (0) and ForYou (1). Hidden on Stories (2), Trips (3), Profile (4).

Also remove the duplicate FAB declared inside `AtlasScreen` itself (currently `atlas_screen.dart` has its own FAB that conflicts with `MainShell`'s).

### 3.2 Atlas Screen (`screens/home/atlas_screen.dart`)

**Header — PFP tap target:**
- Replace `GestureDetector` that pushes `RouteNames.kSettings` → the profile screen is a tab (index 4) not a named route. Solution: `AtlasScreen` cannot directly switch the bottom nav tab (it doesn't own it). Instead, wrap `MainShell` to expose a `switchTab(int)` callback via `InheritedWidget` or simply use a `GlobalKey<_MainShellState>` stored in `main.dart`. Simplest approach: expose a static tab-switch method on `MainShell` via a `GlobalKey`. On PFP tap, call `MainShell.switchTo(4)`.
- Avatar: show real photo from `UserProvider.user?.photoUrl` using `CachedNetworkImage`; fallback to `StripeTile`

**Search bar — dark banner (Option B):**
- Remove `_buildSearchBar()` and `_buildQuickFilters()` methods entirely
- Replace with `_buildSearchBanner()`:
  - Dark (`AppColors.ink`) rounded container, full width, 56px height
  - Left: search icon (white, 18px) + hint text "Search \<countryName\>…" (white54)
  - Right: small terracotta "SEARCH" badge (rounded rect)
  - `onTap`: pushes `RouteNames.kMapSearch`
  - Voice icon removed (TTS is a separate future feature)

**Explore widget — Country info card:**
- New `_buildExploreWidget()` method, inserted between header and city chips
- White card, rounded, bordered
- Left: ISO code badge (large, 44×44, rounded, parchment bg)
- Center: country name (Fraunces, 15px bold) + subtitle "N cities · restaurants & hidden gems"
- Right: small "Exploring" badge (terracotta tint)
- Reads `countryId` from `OnboardingProvider` (or `RestaurantProvider.currentCountryId`)

**City chips — country-aware:**
- Remove hardcoded `_cities` list
- Add `kCountryCities` constant in `core/constants/app_constants.dart`:
  ```dart
  const kCountryCities = {
    'france':         ['Paris', 'Lyon', 'Marseille', 'Nice', 'Bordeaux', 'Toulouse', 'Strasbourg', 'Nantes'],
    'spain':          ['Madrid', 'Barcelona', 'Seville', 'Valencia', 'Bilbao', 'Granada', 'Malaga', 'Zaragoza'],
    'united_states':  ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Miami', 'San Francisco', 'Las Vegas', 'New Orleans'],
    'china':          ['Beijing', 'Shanghai', 'Guangzhou', 'Chengdu', 'Xi\'an', 'Hangzhou', 'Shenzhen', 'Chongqing'],
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
  ```
- `_buildCityChips()` reads from `kCountryCities[currentCountryId] ?? []`
- Default country on first load: read from `OnboardingProvider.countryId`; fallback `'japan'`

**Editor's Picks — curated:**
- Rename `_buildEditorPicksHeader()` — keep as-is visually
- Add `kEditorPicks` in `app_constants.dart`: `Map<String, List<String>>` (city slug → list of restaurant name strings). Used as display labels until real Firestore data is available. This is a UI stub — the feed still loads from `RestaurantProvider`.
- No functional change to the horizontal card list; data still comes from `restaurantProvider.feed`

### 3.3 Trips Screen (`screens/trips/trips_screen.dart`)

**Add "Plan Trip" button:**
- In `_buildHeader()`, add a row with the existing title on the left and a terracotta outlined button "+ Plan Trip" on the right
- Taps push `RouteNames.kPlanTrip` (new stub route)
- Add `kPlanTrip = '/plan-trip'` to `RouteNames`
- Add stub route in `main.dart` `_generateRoute` returning a simple `Scaffold` with "Coming soon" text

**Remove FAB:** handled by §3.1 (MainShell conditional).

### 3.4 Profile Screen (`screens/profile/profile_screen.dart`)

**Name visibility fix:**
- `user?.displayName ?? 'Explorer'` already correct — real bug is that `UserProvider` loads async and renders before data arrives
- Fix: show shimmer placeholder (from `shimmer` package, already in deps) while `user == null`

**Username + country code in subtitle:**
- Change `@local · DiningAtlas` → `@${user?.username ?? 'local'} · ${user?.countryCode ?? ''}`
- Country code rendered as small tag (same style as destination screen rows)

**Dining Passport — real data:**
- Remove hardcoded `cities` list
- Passport shows the country the user chose during onboarding (`user?.onboardingCountryId`)
- Render as ISO code badge + country name (matches destination screen style)
- If no country set yet, show empty state: "Complete onboarding to unlock your passport"

**Remove FAB:** handled by §3.1.

---

## Data Model Changes Summary

| Model | Change |
|---|---|
| `UserModel` | Add `username: String`, `countryCode: String` (ISO-2), `onboardingCountryId: String` |
| `OnboardingPrefsModel` | Rename `cityId` → `countryId`; no other changes |
| `OnboardingProvider` | Rename `cityId`/`setCity` → `countryId`/`setCountry`; add `countryCode` getter |

---

## Constants Changes (`core/constants/app_constants.dart`)

- Add `kCountryCities`: `Map<String, List<String>>` — 15 countries × up to 8 cities
- Add `kSupportedCountries`: ordered list of `{id, name, code}` maps (used by destination screen and country picker)
- Add `kEditorPicks`: `Map<String, List<String>>` — stub city → restaurant name list

---

## Routes Changes (`core/constants/route_names.dart`)

- Add `kPlanTrip = '/plan-trip'`
- Add stub route in `main.dart`

---

## Files Changed (complete list)

**Phase 1:**
- `lib/screens/auth/register_screen.dart` — new fields, PFP upload, country picker, post-register nav
- `lib/models/user_model.dart` — new fields
- `lib/providers/auth_provider.dart` — pass new fields on signUp

**Phase 2:**
- `lib/screens/onboarding/vibe_selector_screen.dart` — 12 vibes, 3-col grid, back button
- `lib/screens/onboarding/budget_screen.dart` — USD tiers
- `lib/screens/onboarding/city_screen.dart` → renamed `destination_screen.dart`
- `lib/screens/onboarding/onboarding_shell.dart` — updated import, back on page 1
- `lib/screens/onboarding/profile_ready_screen.dart` — full redesign
- `lib/providers/onboarding_provider.dart` — rename cityId → countryId
- `lib/models/onboarding_prefs_model.dart` — rename cityId → countryId

**Phase 3:**
- `lib/main.dart` — FAB conditional, kPlanTrip stub route
- `lib/core/constants/app_constants.dart` — kCountryCities, kSupportedCountries, kEditorPicks
- `lib/core/constants/route_names.dart` — kPlanTrip
- `lib/screens/home/atlas_screen.dart` — PFP tap, search banner, explore widget, city chips, remove own FAB
- `lib/screens/trips/trips_screen.dart` — Plan Trip button
- `lib/screens/profile/profile_screen.dart` — shimmer, username/countryCode, real passport

---

## Package Dependencies

`image_picker` must be added to `pubspec.yaml` (not currently present). All other packages (`shimmer`, `cached_network_image`, `provider`) are already declared.

```yaml
image_picker: ^1.0.7
```

Also add required permissions in `AndroidManifest.xml` (READ_MEDIA_IMAGES) and `Info.plist` (NSPhotoLibraryUsageDescription).

---

## Out of Scope

- TTS / voice search (Atlas screen) — deferred
- Username uniqueness server check — Joe's backend
- Plan Trip screen implementation — stub only
- Real Editor's Picks Firestore integration — stub constants only
- Google Sign-In flow changes — not touched
