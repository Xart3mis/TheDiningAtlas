# DiningAtlas — Enhancement & Bug Fix Design
**Date:** 2026-05-18  
**Status:** Approved  
**Team:** Joe (backend, `joe` branch) · Bedo (UI, `bedo` branch)

---

## Priority Tiers

| Priority | Features |
|---|---|
| P1 (highest) | 6 — Review edit/delete · 7 — Push notifications · 9 — AI Gemini summarizer |
| P2 | 1 — Profile picture change · 5 — Nickname change · 4 — Saved places view · 2 — Trip planning |
| P3 | 3 — Search fix · 8 — Map functional with filters |

---

## Feature 6 — Review Edit & Delete (P1)

### Problem
`IReviewService.editReview()` and `deleteReview()` are fully implemented in both the interface and `FirestoreReviewService`. `ReviewProvider.deleteReview()` exists. But no UI exposes either action.

### Design

**UI (Bedo — `screens/restaurant/restaurant_detail_screen.dart`)**

In `_buildReviewsList()`, each review card that belongs to the current user (`review.authorId == authProvider.user?.uid`) gets a `PopupMenuButton` in the trailing position of the author row with two items:

- **Edit** → navigate to a new `EditReviewScreen` pre-filled with existing text and rating
- **Delete** → show `showDialog` confirmation with "Delete" (red) and "Cancel" actions → call `ReviewProvider.deleteReview()`

**New screen (Bedo — `screens/restaurant/edit_review_screen.dart`)**

Same layout as `WriteReviewScreen`. Accepts `ReviewModel` as constructor argument. Pre-fills star rating and text. Submit button calls `ReviewProvider.editReview()`. On success, pops back.

**Provider update (Joe — `providers/review_provider.dart`)**

Add `editReview()` method:
```dart
Future<void> editReview({
  required String restaurantId,
  required String reviewId,
  required String text,
  required double rating,
}) async {
  await _reviewService.editReview(
    restaurantId: restaurantId, reviewId: reviewId,
    text: text, rating: rating,
  );
  final list = _reviews[restaurantId];
  if (list != null) {
    final idx = list.indexWhere((r) => r.id == reviewId);
    if (idx != -1) {
      _reviews[restaurantId]![idx] = ReviewModel(
        id: reviewId,
        restaurantId: restaurantId,
        authorId: list[idx].authorId,
        authorName: list[idx].authorName,
        authorPhotoUrl: list[idx].authorPhotoUrl,
        text: text, rating: rating,
        upvotes: list[idx].upvotes,
        createdAt: list[idx].createdAt,
      );
    }
  }
  notifyListeners();
}
```

**Route (Bedo — `core/constants/route_names.dart` + `main.dart`)**

Add `kEditReview = '/edit-review'`. Route argument: `ReviewModel`.

### Constraints
- Only the review's own author sees edit/delete options (client-side guard, `authorId` check)
- Server-side: `FirestoreReviewService.editReview()` already recomputes `avgRating` after edit; `deleteReview()` already recomputes after delete — no changes needed there

---

## Feature 7 — Push Notifications (P1)

### Problem
`FcmNotificationService` is fully implemented. `NotificationProvider.initialize()` is never called. The FCM token is never saved to Firestore. No in-app notification badge is shown.

### Design

**Initialization (Bedo — `screens/auth/auth_gate.dart`)**

In `AuthGate.initState()`, after the user is confirmed logged in, call:
```dart
context.read<NotificationProvider>().initialize();
```

**Token persistence (Joe — `services/firebase/firestore_user_service.dart` + `models/user_model.dart`)**

1. Add `fcmToken` field to `UserModel` (nullable String)
2. Add `updateFcmToken(String uid, String token)` to `IUserService` interface and `FirestoreUserService` impl — does a single-field `update({'fcmToken': token})`
3. After `NotificationProvider.initialize()` completes, call `_service.getFcmToken()` then `updateFcmToken(uid, token)` — wire this in `NotificationProvider.initialize()` itself or in `AuthGate`

**Notification badge (Bedo — `widgets/shared_widgets.dart` or `main.dart` bottom nav)**

The `AtlasBottomNav` bell/profile icon (or whichever nav item represents notifications) should show a red dot badge when `NotificationProvider.badgeCount > 0`. Wrap the icon with a `Stack` + `Positioned` `Container` badge.

**NotificationsScreen (Bedo — `screens/notifications/notifications_screen.dart`)**

Route `kNotifications = '/notifications'` is already declared. Build a `ListView` backed by a `users/{uid}/notifications` subcollection stream (Joe adds `fetchNotifications(uid)` to `INotificationService`). Each tile: icon, title, body, timestamp. Tapping the screen clears the badge (`NotificationProvider.clearBadge()`).

**Firestore notifications subcollection (Joe — Cloud Function or `FcmNotificationService`)**

When FCM delivers a message, write it to `users/{uid}/notifications/{id}` with fields: `title`, `body`, `type`, `relatedId`, `createdAt`, `read: false`. This lets the app display history.

**Geofence notifications**

Already wired: `SavedPlacesProvider.toggleSave()` calls `scheduleGeofenceNotification()`. This works once `initialize()` is called. No additional work.

### Notification types to support
| Type | Trigger | Body |
|---|---|---|
| `new_review` | Someone reviews a place you saved | "New review for [place]" |
| `nearby_saved` | Geofence entry for a saved place | "You're near [place]! 500m away" |
| `tip_reply` | Reply in a chat thread | "[User] replied to your message" |

---

## Feature 9 — AI Gemini Review Summarizer (P1)

### Problem
The summarizer uses Groq. Requirement is Gemini. Additionally, `AiProvider.loadSummary()` generates summaries on every cold load but never reads from or writes to the `restaurants/{id}/summary` Firestore doc, bypassing the 7-day TTL cache.

### Design

**New service (Joe — `services/ai/gemini_ai_service.dart`)**

Implement `IAiService` using Gemini `generateContent` REST endpoint:
- Base URL: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent`
- Auth: `?key=$geminiApiKey` query param
- Same 3 methods: `generateTasteWeights`, `translate`, `summarizeReviews`
- Same prompts as `GroqAiService` — only the HTTP wrapper changes

**Environment (Joe — `core/constants/env.dart`)**

Add `static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');`

**Service swap (Joe — `core/service_provider.dart`)**

Replace `GroqAiService()` → `GeminiAiService()`.

**Summary Firestore cache (Joe — `providers/ai_provider.dart`)**

Update `loadSummary()`:
1. First check `restaurants/{id}/summary` doc in Firestore — if it exists and `generatedAt` is within 7 days, use `PlaceSummaryModel.fromFirestore(doc)`; store in `_summaries` map and return
2. If stale or missing: fetch reviews, call `_aiService.summarizeReviews()`, then write result to `restaurants/{id}/summary` via a new `IAiService.cacheSummary(restaurantId, summary)` method implemented in `GeminiAiService`

**`PlaceSummaryModel` Firestore read (Joe — `models/place_summary_model.dart`)**

Already has `fromFirestore` and `toFirestore` — no changes needed.

**AI summary display**

`_AiSummaryCard` in `restaurant_detail_screen.dart` and `AiProvider` require zero UI changes — already correctly wired.

### Gemini prompt strategy
Same structured JSON approach as current Groq prompts. Gemini Flash is fast and cheap enough for on-demand use. The 7-day TTL Firestore cache means most users see cached results with no API call.

---

## Feature 1 & 5 — Profile Picture + Nickname/Username Change (P2)

### Problem
`SettingsScreen` only has Chat Privacy and Sign Out. No way to edit `displayName`, `username`, or `photoUrl` after onboarding.

### Design

**Settings screen additions (Bedo — `screens/profile/settings_screen.dart`)**

Add a new "Profile" `_SectionHeader` at the top of the `ListView`, above "Chat Privacy":

```
[Avatar with camera-icon overlay]   Change Photo
Display Name     [current value]    >
Username         @[current value]   >
```

- **Change Photo** tap → `image_picker` → on image selected: upload via `IStorageService.uploadImage(path: 'avatars/{uid}')` → call `UserProvider.updateProfile(photoUrl: url)`
- **Display Name** tap → `showDialog` with a single `TextField` pre-filled → confirm → `UserProvider.updateProfile(displayName: value)`
- **Username** tap → same dialog pattern → `UserProvider.updateProfile(username: value)` — validate no spaces, lowercase, 3–20 chars

**Provider (Joe — `providers/user_provider.dart`)**

Add `updateProfile({String? displayName, String? photoUrl, String? username})` method:
```dart
Future<void> updateProfile({String? displayName, String? photoUrl, String? username}) async {
  if (_user == null) return;
  final updated = _user!.copyWith(
    displayName: displayName ?? _user!.displayName,
    photoUrl: photoUrl ?? _user!.photoUrl,
    username: username ?? _user!.username,
  );
  await _service.updateUser(updated);
  _user = updated;
  notifyListeners();
}
```

Add `copyWith` to `UserModel` (currently missing).

**Storage path:** `avatars/{uid}.jpg` — overwrite on each update (no versioning needed).

---

## Feature 4 — Saved Places View (P2)

### Problem
`SavedPlacesProvider` loads only a `Set<String>` of IDs, not full `RestaurantModel` objects. `ProfileScreen` shows a "SAVED" count but tapping it does nothing.

### Design

**Provider update (Joe — `providers/saved_places_provider.dart`)**

Inject `IRestaurantService` into `SavedPlacesProvider` constructor (alongside existing `IUserService` and `INotificationService`). Update `ServiceProvider` to pass `restaurantService` when constructing it.

Add:
```dart
List<RestaurantModel> _savedRestaurants = [];
List<RestaurantModel> get savedRestaurants => _savedRestaurants;

Future<void> loadSavedRestaurants(String uid) async {
  final ids = await _userService.fetchSavedPlaceIds(uid);
  _savedIds = ids.toSet();
  _savedRestaurants = (await Future.wait(
    ids.map((id) => _restaurantService.fetchById(id)),
  )).whereType<RestaurantModel>().toList();
  notifyListeners();
}
```

**New screen (Bedo — `screens/profile/saved_places_screen.dart`)**

A standard list screen (same card design as `AtlasScreen` editor picks, full-width). Each card navigates to `RestaurantDetailScreen`. Empty state: "No saved places yet. Explore and save places you love." Unsave button on each card calls `SavedPlacesProvider.toggleSave()`.

**Route (Bedo — `route_names.dart` + `main.dart`)**

Add `kSavedPlaces = '/saved-places'`. No required arguments.

**Entry point (Bedo — `screens/profile/profile_screen.dart`)**

The "SAVED" stat column in `_buildStats()` becomes a `GestureDetector` that pushes `kSavedPlaces`.

---

## Feature 2 — Trip Planning (P2)

### Problem
The "Plan Trip" button routes to `kPlanTrip` which returns a hardcoded "Coming soon" scaffold. `ITripService.createTrip()` is fully implemented but `TripProvider` has no `createTrip()` method.

### Design

**Provider (Joe — `providers/trip_provider.dart`)**

Add `createTrip(String uid, TripModel trip)`:
```dart
Future<void> createTrip(String uid, TripModel trip) async {
  final id = await _service.createTrip(trip);
  await loadTrips(uid);
}
```

**New screen (Bedo — `screens/trips/plan_trip_screen.dart`)**

A single scrollable screen with three logical sections:

1. **Destination** — `DropdownButtonFormField` populated from `SeedDataProvider.cities`; selects `cityId`
2. **Dates** — A "Pick Dates" button → `showDateRangePicker` → displays selected range as "May 20 – May 23 (4 days)"
3. **Trip Title** — Optional `TextField` (auto-generates "Paris Trip" from city if left empty)

"Create Trip" button:
- Validates city selected + dates selected
- Generates `TripDayModel` list: one entry per day between start and end dates, each with empty `spots` list
- Calls `TripProvider.createTrip(uid, TripModel(...))`
- On success: `Navigator.pushReplacementNamed(kMain)` (tab 3, Trips)

**Route (Bedo — `main.dart`)**

Replace the inline "Coming soon" scaffold with `PlanTripScreen()`.

**Adding spots to a trip**

From `TripsScreen`, for each day card, an `+` icon button opens a search bottom sheet (`showModalBottomSheet`) — `RestaurantProvider.search()` fills results — tapping a result calls `TripProvider.addSpot()`. This extends the existing `addSpot` flow already wired.

---

## Feature 3 — Search Fix (P3)

### Problem
Tapping the search bar/button on `AtlasScreen` opens `MapSearchScreen` instead of a text search UI.

### Design

**New screen (Bedo — `screens/search/search_screen.dart`)**

- `TextField` auto-focused on push, placeholder "Search restaurants, cuisines…"
- Calls `RestaurantProvider.search(query)` debounced 300ms via a `Timer`
- Results shown as `ListView` of restaurant cards (same design as `_EditorPickCard` but full-width)
- Empty state while query is empty: show recent searches (stored in provider) or suggested categories from `SeedDataProvider`
- Each result taps to `RestaurantDetailScreen`

**Route (Bedo)**

Add `kSearch = '/search'` to `RouteNames` and route in `main.dart`.

**Atlas screen fix (Bedo — `screens/home/atlas_screen.dart`)**

Change `_buildSearchBanner()` `onTap`:
```dart
// Before:
onTap: () => Navigator.pushNamed(context, RouteNames.kMapSearch),
// After:
onTap: () => Navigator.pushNamed(context, RouteNames.kSearch),
```

The "See all" link and map FAB still go to `kMapSearch`. Only the search bar changes target.

---

## Feature 8 — Map Functional with Filters (P3)

### Problem
1. `_CuisineFilterBar` has no selected-state highlight — tapping a filter applies it but nothing shows which filter is active
2. The original UI concept included a map cutout/preview on the Atlas home screen
3. No search bar on the map screen itself

### Design

**Active filter state (Bedo — `screens/map/map_search_screen.dart`)**

Add `String _selectedFilter = 'All'` to `_MapSearchScreenState`. Pass it to `_CuisineFilterBar` and update on tap. In `_CuisineFilterBar`, add `selected` boolean per chip — selected chip uses `AppColors.terracotta` background with white text (same pattern as `AtlasPill`).

**Map search bar overlay (Bedo — `screens/map/map_search_screen.dart`)**

Add a `Positioned` search `TextField` at the top of the `Stack` (below the back button, same row):
- Calls `RestaurantProvider.search(query)` on submit/change
- On results, rebuilds markers from `searchResults` instead of `feed`
- Clears back to `feed` when query is empty

**Map preview tile on Atlas screen (Bedo — `screens/home/atlas_screen.dart`)**

Add `_buildMapPreviewTile()` between `_buildExploreWidget` and `_buildCityChips`:

A `GestureDetector` wrapping a fixed-height (120px) container with:
- Background: `FlutterMap` widget in non-interactive mode (`MapOptions(interactionOptions: InteractionOptions(flags: InteractiveFlag.none))`) centered on the current city's geopoint
- Foreground gradient overlay from transparent to `AppColors.ink.withOpacity(0.4)`
- Centered text: "Explore on Map" in white Fraunces + map pin icon
- Tap → `Navigator.pushNamed(kMapSearch)`

This is purely UI — the same `flutter_map` + OSM tiles already used in `MapSearchScreen`.

---

## New Files Summary

| File | Owner | Purpose |
|---|---|---|
| `screens/restaurant/edit_review_screen.dart` | Bedo | Edit existing review |
| `screens/notifications/notifications_screen.dart` | Bedo | Notification history list |
| `screens/profile/saved_places_screen.dart` | Bedo | View saved restaurants |
| `screens/trips/plan_trip_screen.dart` | Bedo | Create a new trip |
| `screens/search/search_screen.dart` | Bedo | Text search UI |
| `services/ai/gemini_ai_service.dart` | Joe | Gemini API implementation of IAiService |

## Modified Files Summary

| File | Owner | Change |
|---|---|---|
| `screens/restaurant/restaurant_detail_screen.dart` | Bedo | Add edit/delete PopupMenu on own reviews |
| `screens/profile/settings_screen.dart` | Bedo | Add Profile section (avatar, name, username) |
| `screens/profile/profile_screen.dart` | Bedo | SAVED stat tappable → kSavedPlaces |
| `screens/home/atlas_screen.dart` | Bedo | Search bar → kSearch; add map preview tile |
| `screens/map/map_search_screen.dart` | Bedo | Active filter state; search bar overlay |
| `screens/auth/auth_gate.dart` | Bedo | Call NotificationProvider.initialize() |
| `screens/trips/trips_screen.dart` | Bedo | Day spot add button → search bottom sheet |
| `main.dart` | Bedo | kPlanTrip → PlanTripScreen; new routes |
| `core/constants/route_names.dart` | Bedo | Add kEditReview, kSavedPlaces, kSearch |
| `providers/review_provider.dart` | Joe | Add editReview() |
| `providers/user_provider.dart` | Joe | Add updateProfile() |
| `providers/saved_places_provider.dart` | Joe | Add loadSavedRestaurants() |
| `providers/trip_provider.dart` | Joe | Add createTrip() |
| `providers/ai_provider.dart` | Joe | Firestore cache check + write in loadSummary() |
| `models/user_model.dart` | Joe | Add fcmToken field; add copyWith() |
| `services/interfaces/i_user_service.dart` | Joe | Add updateFcmToken() |
| `services/interfaces/i_notification_service.dart` | Joe | Add fetchNotifications() |
| `services/interfaces/i_ai_service.dart` | Joe | Add cacheSummary() |
| `services/firebase/firestore_user_service.dart` | Joe | Implement updateFcmToken() |
| `services/ai/groq_ai_service.dart` | Joe | Replaced by GeminiAiService (keep for reference) |
| `core/constants/env.dart` | Joe | Add geminiApiKey |
| `core/service_provider.dart` | Joe | Swap GroqAiService → GeminiAiService |

---

## Definition of Done

A feature is complete when:
- [ ] Real data flows end-to-end (no placeholder/stub in production path)
- [ ] Loading state shown while data fetches
- [ ] Error state handled — snackbar or inline message, no unhandled exceptions
- [ ] Own-user guard in place for edit/delete
- [ ] New routes registered in `main.dart` and `route_names.dart`
- [ ] Works offline (cached) or shows graceful offline message
