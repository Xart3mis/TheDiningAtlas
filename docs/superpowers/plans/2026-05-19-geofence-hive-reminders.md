# Geofence, Hive Cache & Location Reminders Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement offline Hive caching for the restaurant feed and saved-place IDs, a per-place reminder toggle stored in Firestore, and a foreground proximity notification system via a new `GeofenceProvider`.

**Architecture:** `GeofenceProvider` subscribes to `ILocationService.positionStream()` and fires local notifications when the user is within 500 m of a saved place with `reminderEnabled = true` and the 1-hour cooldown has elapsed. `RestaurantProvider` serves Hive-cached data immediately (stale-while-revalidate) then overwrites on Firestore success. `SavedPlacesProvider` loads reminder flags from Firestore, allows per-place toggling, and keeps `GeofenceProvider` in sync after every mutation.

**Tech Stack:** Flutter/Dart, Provider, Hive ^2.2.3 + hive_flutter ^1.1.0 (new), Geolocator (already installed), cloud_firestore (already installed), flutter_local_notifications (already installed).

---

## File Map

| File | Status | Change |
|---|---|---|
| `pubspec.yaml` | Modify | Add hive + hive_flutter |
| `lib/main.dart` | Modify | Init Hive boxes before Firebase |
| `lib/models/restaurant_model.dart` | Modify | Add `toJson` / `fromJson` |
| `lib/providers/restaurant_provider.dart` | Modify | Stale-while-revalidate with Hive |
| `lib/services/interfaces/i_user_service.dart` | Modify | Add `fetchSavedPlaceFlags` + `updateReminderEnabled` |
| `lib/services/mock/mock_user_service.dart` | Modify | Add stub implementations |
| `lib/services/firebase/firestore_user_service.dart` | Modify | Implement `fetchSavedPlaceFlags` + `updateReminderEnabled` |
| `lib/providers/geofence_provider.dart` | **Create** | New `GeofenceProvider` |
| `lib/providers/saved_places_provider.dart` | Modify | Reminders map, `toggleReminder`, Hive ID cache, GeofenceProvider calls, remove obsolete notif stubs |
| `lib/core/service_provider.dart` | Modify | Register `GeofenceProvider`, update `SavedPlacesProvider` construction |
| `lib/screens/auth/auth_gate.dart` | Modify | `start()` / `stop()` GeofenceProvider on auth state change |
| `lib/screens/profile/saved_places_screen.dart` | Modify | Bell icon in `_SavedPlaceCard` |

---

## Task 1: Add Hive dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add hive packages under `dependencies`**

  In `pubspec.yaml`, after `connectivity_plus: ^6.1.1` add:

  ```yaml
    hive: ^2.2.3
    hive_flutter: ^1.1.0
  ```

- [ ] **Step 2: Fetch packages**

  ```bash
  flutter pub get
  ```

  Expected: `Resolving dependencies...` completes with no errors; `hive` and `hive_flutter` appear in `pubspec.lock`.

- [ ] **Step 3: Commit**

  ```bash
  git add pubspec.yaml pubspec.lock
  git commit -m "chore: add hive and hive_flutter dependencies"
  ```

---

## Task 2: Add toJson / fromJson to RestaurantModel

**Files:**
- Modify: `lib/models/restaurant_model.dart`

The existing `fromFirestore` uses the Firestore field name `coordinates` for the `GeoPoint` and `tileColorValue` for the colour integer. `toJson` / `fromJson` store them as plain doubles (`lat` / `lng`) and an int, so Hive (which cannot store Firestore types) can round-trip them.

- [ ] **Step 1: Add `toJson` after the `toFirestore` method**

  Locate the end of the `toFirestore()` method in `lib/models/restaurant_model.dart` and insert the two new methods immediately after it:

  ```dart
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'cityId': cityId,
    'neighborhood': neighborhood,
    'lat': geopoint.latitude,
    'lng': geopoint.longitude,
    'description': description,
    'tip': tip,
    'dish': dish,
    'mediaUrls': mediaUrls,
    'contributorId': contributorId,
    'status': status,
    'avgRating': avgRating,
    'reviewCount': reviewCount,
    'saveCount': saveCount,
    'priceRange': priceRange,
    'tileColorValue': tileColor.value,
    'badge': badge,
    'tagline': tagline,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'address': address,
    'hours': hours,
    'phone': phone,
    'reserve': reserve,
    'walkInfo': walkInfo,
  };

  factory RestaurantModel.fromJson(Map<String, dynamic> d) => RestaurantModel(
    id: d['id'] as String,
    name: d['name'] as String,
    category: d['category'] as String,
    cityId: d['cityId'] as String,
    neighborhood: d['neighborhood'] as String,
    geopoint: GeoPoint(
      (d['lat'] as num).toDouble(),
      (d['lng'] as num).toDouble(),
    ),
    description: d['description'] as String,
    tip: d['tip'] as String,
    dish: d['dish'] as String,
    mediaUrls: List<String>.from(d['mediaUrls'] as List),
    contributorId: d['contributorId'] as String,
    status: d['status'] as String,
    avgRating: (d['avgRating'] as num).toDouble(),
    reviewCount: (d['reviewCount'] as num).toInt(),
    saveCount: (d['saveCount'] as num).toInt(),
    priceRange: d['priceRange'] as String,
    tileColor: Color(d['tileColorValue'] as int),
    badge: d['badge'] as String?,
    tagline: d['tagline'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(d['createdAt'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(d['updatedAt'] as int),
    address: d['address'] as String?,
    hours: d['hours'] as String?,
    phone: d['phone'] as String?,
    reserve: d['reserve'] as String?,
    walkInfo: d['walkInfo'] as String?,
  );
  ```

- [ ] **Step 2: Verify no analysis errors**

  ```bash
  flutter analyze lib/models/restaurant_model.dart
  ```

  Expected: `No issues found!`

- [ ] **Step 3: Commit**

  ```bash
  git add lib/models/restaurant_model.dart
  git commit -m "feat(model): add toJson/fromJson to RestaurantModel for Hive cache"
  ```

---

## Task 3: Initialise Hive in main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add hive_flutter import**

  At the top of `lib/main.dart`, after `import 'package:firebase_core/firebase_core.dart';`, add:

  ```dart
  import 'package:hive_flutter/hive_flutter.dart';
  ```

- [ ] **Step 2: Init Hive before Firebase**

  In `main()`, replace:

  ```dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
  ```

  with:

  ```dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    await Hive.openBox<String>('restaurant_feed'); // key: cityId → JSON array
    await Hive.openBox<String>('saved_ids');       // key: uid → JSON array of IDs
    await Firebase.initializeApp(
  ```

- [ ] **Step 3: Verify no analysis errors**

  ```bash
  flutter analyze lib/main.dart
  ```

  Expected: `No issues found!`

- [ ] **Step 4: Commit**

  ```bash
  git add lib/main.dart
  git commit -m "feat(cache): init Hive boxes before Firebase in main"
  ```

---

## Task 4: Stale-while-revalidate in RestaurantProvider

**Files:**
- Modify: `lib/providers/restaurant_provider.dart`

The current `loadFeed` blocks UI until Firestore responds. The new version:
1. Reads the Hive cache and emits to UI immediately (no loading indicator).
2. Then fetches fresh data from Firestore, overwrites the cache, and emits again.

- [ ] **Step 1: Add imports to restaurant_provider.dart**

  Add at the top, after existing imports:

  ```dart
  import 'dart:convert';
  import 'package:hive_flutter/hive_flutter.dart';
  ```

- [ ] **Step 2: Replace the `loadFeed` method body**

  Find the full `loadFeed` method and replace it with:

  ```dart
  Future<void> loadFeed({String? cityId}) async {
    _currentCityId = cityId ?? _currentCityId;
    if (_currentCityId.isEmpty) return;

    // Serve cached data immediately so the UI is never blank
    final cacheBox = Hive.box<String>('restaurant_feed');
    final cached = cacheBox.get(_currentCityId);
    if (cached != null) {
      try {
        _feed = (jsonDecode(cached) as List)
            .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      } catch (_) {}
    }

    // Fetch fresh data from Firestore in the background
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final fresh = await _service
          .fetchFeed(cityId: _currentCityId)
          .timeout(_timeout, onTimeout: () => []);
      if (fresh.isNotEmpty) {
        _feed = fresh;
        cacheBox.put(
          _currentCityId,
          jsonEncode(fresh.map((r) => r.toJson()).toList()),
        );
      }
    } catch (e) {
      // Keep stale cache data visible; only surface error if nothing to show
      if (_feed.isEmpty) _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  ```

- [ ] **Step 3: Verify no analysis errors**

  ```bash
  flutter analyze lib/providers/restaurant_provider.dart
  ```

  Expected: `No issues found!`

- [ ] **Step 4: Commit**

  ```bash
  git add lib/providers/restaurant_provider.dart
  git commit -m "feat(cache): stale-while-revalidate restaurant feed with Hive"
  ```

---

## Task 5: Add fetchSavedPlaceFlags + updateReminderEnabled to the user service layer

**Files:**
- Modify: `lib/services/interfaces/i_user_service.dart`
- Modify: `lib/services/mock/mock_user_service.dart`
- Modify: `lib/services/firebase/firestore_user_service.dart`

`fetchSavedPlaceFlags` returns the whole `placeId → reminderEnabled` map in one Firestore query.  
`updateReminderEnabled` does a single-field update on `users/{uid}/savedPlaces/{placeId}`.

- [ ] **Step 1: Add method signatures to IUserService**

  In `lib/services/interfaces/i_user_service.dart`, add two lines after `Future<void> unsavePlace(...)`:

  ```dart
  Future<Map<String, bool>> fetchSavedPlaceFlags(String uid);
  Future<void> updateReminderEnabled(String uid, String placeId, bool enabled);
  ```

- [ ] **Step 2: Add stubs to MockUserService**

  Open `lib/services/mock/mock_user_service.dart`. Add the two stub overrides (place them after the existing `unsavePlace` override):

  ```dart
  @override
  Future<Map<String, bool>> fetchSavedPlaceFlags(String uid) async => {};

  @override
  Future<void> updateReminderEnabled(
      String uid, String placeId, bool enabled) async {}
  ```

- [ ] **Step 3: Implement in FirestoreUserService**

  Open `lib/services/firebase/firestore_user_service.dart`. Add the two implementations after the existing `unsavePlace` method:

  ```dart
  @override
  Future<Map<String, bool>> fetchSavedPlaceFlags(String uid) async {
    final snap = await _userDoc(uid)
        .collection(AppConstants.kColSavedPlaces)
        .get();
    return {
      for (final doc in snap.docs)
        doc.id: (doc.data()['reminderEnabled'] as bool?) ?? false,
    };
  }

  @override
  Future<void> updateReminderEnabled(
      String uid, String placeId, bool enabled) async {
    await _userDoc(uid)
        .collection(AppConstants.kColSavedPlaces)
        .doc(placeId)
        .update({'reminderEnabled': enabled});
  }
  ```

- [ ] **Step 4: Verify no analysis errors**

  ```bash
  flutter analyze lib/services/
  ```

  Expected: `No issues found!`

- [ ] **Step 5: Commit**

  ```bash
  git add lib/services/interfaces/i_user_service.dart \
          lib/services/mock/mock_user_service.dart \
          lib/services/firebase/firestore_user_service.dart
  git commit -m "feat(reminders): add fetchSavedPlaceFlags + updateReminderEnabled to user service"
  ```

---

## Task 6: Create GeofenceProvider

**Files:**
- Create: `lib/providers/geofence_provider.dart`

`GeofenceProvider` is the single owner of proximity logic. It does not extend `ChangeNotifier` state that the UI needs to react to — it's a coordination object — but it extends `ChangeNotifier` so it fits the Provider tree and `dispose()` is called automatically.

Key behaviours:
- `start()` subscribes to `ILocationService.positionStream()`. No-op if already started.
- `stop()` cancels the subscription and clears the cooldown map.
- `setWatchList` is thread-safe to call at any time; next stream tick uses the new list.
- Per-place 1-hour cooldown stored in `_lastNotified` (in-memory, cleared on `stop()`).

- [ ] **Step 1: Create the file**

  Create `lib/providers/geofence_provider.dart` with this exact content:

  ```dart
  import 'dart:async';

  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/foundation.dart';
  import 'package:geolocator/geolocator.dart';

  import '../core/constants/app_constants.dart';
  import '../models/restaurant_model.dart';
  import '../services/interfaces/i_location_service.dart';
  import '../services/interfaces/i_notification_service.dart';

  class GeofenceProvider extends ChangeNotifier {
    final INotificationService _notificationService;
    final ILocationService _locationService;

    GeofenceProvider(this._notificationService, this._locationService);

    StreamSubscription<GeoPoint>? _subscription;
    List<RestaurantModel> _watchList = const [];
    Map<String, bool> _reminders = const {};
    final Map<String, DateTime> _lastNotified = {};

    /// Subscribes to the position stream. No-op if already started.
    void start() {
      if (_subscription != null) return;
      _subscription = _locationService.positionStream().listen(_onPosition);
    }

    /// Cancels the stream subscription and resets the cooldown map.
    void stop() {
      _subscription?.cancel();
      _subscription = null;
      _lastNotified.clear();
    }

    /// Replaces the watch list. Safe to call while the stream is running.
    void setWatchList(
        List<RestaurantModel> places, Map<String, bool> reminders) {
      _watchList = List.of(places);
      _reminders = Map.of(reminders);
    }

    void _onPosition(GeoPoint userPos) {
      for (final place in _watchList) {
        if (!(_reminders[place.id] ?? false)) continue;

        final distance = Geolocator.distanceBetween(
          userPos.latitude,
          userPos.longitude,
          place.geopoint.latitude,
          place.geopoint.longitude,
        );

        if (distance >= AppConstants.kGeofenceRadiusMeters) continue;

        final last = _lastNotified[place.id];
        if (last != null &&
            DateTime.now().difference(last) < const Duration(hours: 1)) {
          continue;
        }

        _lastNotified[place.id] = DateTime.now();
        _notificationService.showLocalNotification(
          title: "You're near ${place.name}",
          body: place.tip.isNotEmpty ? place.tip : place.description,
        );
      }
    }

    @override
    void dispose() {
      stop();
      super.dispose();
    }
  }
  ```

- [ ] **Step 2: Verify no analysis errors**

  ```bash
  flutter analyze lib/providers/geofence_provider.dart
  ```

  Expected: `No issues found!`

- [ ] **Step 3: Commit**

  ```bash
  git add lib/providers/geofence_provider.dart
  git commit -m "feat(geofence): create GeofenceProvider with proximity-triggered local notifications"
  ```

---

## Task 7: Rewrite SavedPlacesProvider

**Files:**
- Modify: `lib/providers/saved_places_provider.dart`

Changes in this task:
- Replace `_notificationService` with `_geofenceProvider` (the only uses of `_notificationService` were the geofence stubs, which are now handled by `GeofenceProvider`).
- Add `Map<String, bool> _reminders` field.
- Add `bool reminderEnabled(String placeId)` getter.
- Add `Future<void> toggleReminder(String uid, String placeId)` method.
- Update `loadSavedRestaurants`: fetch reminder flags, populate `_reminders`, call `setWatchList`, write IDs to Hive; fall back to Hive on network failure.
- Update `toggleSave`: remove `scheduleGeofenceNotification` / `cancelGeofenceNotification` call-sites, add `setWatchList` calls, maintain `_reminders` optimistically.

- [ ] **Step 1: Replace the entire file content**

  ```dart
  import 'dart:convert';

  import 'package:flutter/material.dart';
  import 'package:hive_flutter/hive_flutter.dart';

  import '../core/errors/app_exception.dart';
  import '../models/restaurant_model.dart';
  import '../services/interfaces/i_restaurant_service.dart';
  import '../services/interfaces/i_user_service.dart';
  import 'geofence_provider.dart';

  class SavedPlacesProvider extends ChangeNotifier {
    final IUserService _userService;
    final IRestaurantService _restaurantService;
    final GeofenceProvider _geofenceProvider;

    SavedPlacesProvider(
      this._userService,
      this._restaurantService,
      this._geofenceProvider,
    );

    Set<String> _savedIds = {};
    List<RestaurantModel> _savedRestaurants = [];
    Map<String, bool> _reminders = {};
    bool _isLoading = false;
    bool _loaded = false;
    String? _error;

    bool get isLoading => _isLoading;
    String? get error => _error;
    Set<String> get savedIds => _savedIds;
    List<RestaurantModel> get savedRestaurants => _savedRestaurants;
    bool isSaved(String placeId) => _savedIds.contains(placeId);
    bool reminderEnabled(String placeId) => _reminders[placeId] ?? false;
    int get uniqueCityCount =>
        _savedRestaurants.map((r) => r.cityId).toSet().length;

    // Legacy load used by feed screens — unchanged behaviour.
    Future<void> loadSaved(String uid) async {
      if (_loaded) return;
      _isLoading = true;
      notifyListeners();
      try {
        final ids = await _userService.fetchSavedPlaceIds(uid);
        _savedIds = ids.toSet();
        _savedRestaurants = await Future.wait(
          ids.map((id) => _restaurantService.fetchById(id)),
        ).then((list) => list.whereType<RestaurantModel>().toList());
        _loaded = true;
      } catch (_) {
        _savedRestaurants = [];
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }

    Future<void> loadSavedRestaurants(String uid) async {
      _error = null;
      _isLoading = true;
      notifyListeners();

      // Fetch IDs — fall back to Hive on network failure
      List<String> ids;
      try {
        ids = await _userService.fetchSavedPlaceIds(uid);
        Hive.box<String>('saved_ids').put(uid, jsonEncode(ids));
      } catch (e) {
        final cached = Hive.box<String>('saved_ids').get(uid);
        if (cached != null) {
          _savedIds = Set<String>.from(jsonDecode(cached) as List);
          _isLoading = false;
          notifyListeners();
          return; // IDs visible; no detail fetches while offline
        }
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Kick off reminder flags fetch in parallel with detail fetches
      final flagsFuture = _userService.fetchSavedPlaceFlags(uid);
      _savedIds = ids.toSet();

      final results = <RestaurantModel>[];
      for (final id in ids) {
        try {
          results.add(await _restaurantService.fetchById(id));
        } catch (_) {
          // Skip restaurants that can no longer be found
        }
      }

      try {
        _reminders = await flagsFuture;
      } catch (_) {
        _reminders = {};
      }

      _savedRestaurants = results;
      _loaded = true;
      _geofenceProvider.setWatchList(_savedRestaurants, _reminders);

      _isLoading = false;
      notifyListeners();
    }

    Future<void> toggleSave(
        {required String uid, required RestaurantModel restaurant}) async {
      _error = null;
      final wasSaved = _savedIds.contains(restaurant.id);

      // Optimistic update
      if (wasSaved) {
        _savedIds.remove(restaurant.id);
        _savedRestaurants.removeWhere((r) => r.id == restaurant.id);
        _reminders.remove(restaurant.id);
      } else {
        _savedIds.add(restaurant.id);
        _savedRestaurants.add(restaurant);
        _reminders[restaurant.id] = true; // default reminder on when saving
      }
      _geofenceProvider.setWatchList(_savedRestaurants, _reminders);
      notifyListeners();

      try {
        if (wasSaved) {
          await _userService.unsavePlace(uid: uid, placeId: restaurant.id);
        } else {
          await _userService.savePlace(
              uid: uid, placeId: restaurant.id, reminderEnabled: true);
        }
      } on QuotaException catch (e) {
        // Roll back optimistic update
        if (wasSaved) {
          _savedIds.add(restaurant.id);
          _savedRestaurants.add(restaurant);
          _reminders[restaurant.id] = true;
        } else {
          _savedIds.remove(restaurant.id);
          _savedRestaurants.removeWhere((r) => r.id == restaurant.id);
          _reminders.remove(restaurant.id);
        }
        _error = e.message;
        _geofenceProvider.setWatchList(_savedRestaurants, _reminders);
        notifyListeners();
      }
    }

    Future<void> toggleReminder(String uid, String placeId) async {
      final current = _reminders[placeId] ?? false;
      _reminders[placeId] = !current; // optimistic
      _geofenceProvider.setWatchList(_savedRestaurants, _reminders);
      notifyListeners();
      try {
        await _userService.updateReminderEnabled(uid, placeId, !current);
      } catch (e) {
        _reminders[placeId] = current; // roll back
        _geofenceProvider.setWatchList(_savedRestaurants, _reminders);
        _error = e.toString();
        notifyListeners();
      }
    }
  }
  ```

- [ ] **Step 2: Verify no analysis errors**

  ```bash
  flutter analyze lib/providers/saved_places_provider.dart
  ```

  Expected: `No issues found!`

- [ ] **Step 3: Commit**

  ```bash
  git add lib/providers/saved_places_provider.dart
  git commit -m "feat(reminders): add reminder toggle, Hive ID cache, GeofenceProvider sync to SavedPlacesProvider"
  ```

---

## Task 8: Register GeofenceProvider and update ServiceProvider wiring

**Files:**
- Modify: `lib/core/service_provider.dart`

`SavedPlacesProvider` no longer takes `notificationService`; it takes `geofenceProvider` instead. `geofenceProvider` is created as a local variable so the same instance can be passed to both the provider tree (for `AuthGate` access) and directly to `SavedPlacesProvider`.

- [ ] **Step 1: Add import for GeofenceProvider**

  At the top of `lib/core/service_provider.dart`, add after the existing provider imports:

  ```dart
  import '../providers/geofence_provider.dart';
  ```

- [ ] **Step 2: Instantiate GeofenceProvider before the providers list**

  In `getProviders()`, after the line that creates `notificationService` and before the `return [` line, add:

  ```dart
  final geofenceProvider = GeofenceProvider(notificationService, locationService);
  ```

- [ ] **Step 3: Add GeofenceProvider to the providers list**

  In the State Providers section of the return list, add a line for `GeofenceProvider` **before** `SavedPlacesProvider`:

  ```dart
  ChangeNotifierProvider(create: (_) => geofenceProvider),
  ```

- [ ] **Step 4: Update SavedPlacesProvider construction**

  Replace:

  ```dart
  ChangeNotifierProvider(
      create: (_) => SavedPlacesProvider(userService, notificationService, restaurantService)),
  ```

  with:

  ```dart
  ChangeNotifierProvider(
      create: (_) => SavedPlacesProvider(userService, restaurantService, geofenceProvider)),
  ```

- [ ] **Step 5: Verify no analysis errors**

  ```bash
  flutter analyze lib/core/service_provider.dart
  ```

  Expected: `No issues found!`

- [ ] **Step 6: Verify full project analysis**

  ```bash
  flutter analyze lib/
  ```

  Expected: `No issues found!`

- [ ] **Step 7: Commit**

  ```bash
  git add lib/core/service_provider.dart
  git commit -m "feat(geofence): register GeofenceProvider and rewire SavedPlacesProvider in ServiceProvider"
  ```

---

## Task 9: Start / stop GeofenceProvider from AuthGate

**Files:**
- Modify: `lib/screens/auth/auth_gate.dart`

`GeofenceProvider.start()` must be called once the user is authenticated and notifications have been initialised. `stop()` must be called when the authenticated widget is removed (user signs out).

The `_AuthenticatedGateState` class is the right home for both calls:
- `start()` goes at the end of `_init()` — after the user is loaded and notifications are initialised.
- `stop()` goes in `dispose()`, using a stored reference (not `context.read<>()` which is unsafe in dispose).

- [ ] **Step 1: Add GeofenceProvider import**

  At the top of `lib/screens/auth/auth_gate.dart`, add after existing provider imports:

  ```dart
  import '../../providers/geofence_provider.dart';
  ```

- [ ] **Step 2: Add `_geofenceProvider` field to `_AuthenticatedGateState`**

  In `_AuthenticatedGateState`, add a field after `_GateState _state = _GateState.loading;`:

  ```dart
  late final GeofenceProvider _geofenceProvider;
  ```

- [ ] **Step 3: Capture reference in initState and call start after init**

  Replace the existing `initState` override:

  ```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }
  ```

  with:

  ```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _geofenceProvider = context.read<GeofenceProvider>();
      await _init();
      _geofenceProvider.start();
    });
  }
  ```

- [ ] **Step 4: Add dispose override**

  Add a `dispose` override directly after the `initState` override:

  ```dart
  @override
  void dispose() {
    _geofenceProvider.stop();
    super.dispose();
  }
  ```

- [ ] **Step 5: Verify no analysis errors**

  ```bash
  flutter analyze lib/screens/auth/auth_gate.dart
  ```

  Expected: `No issues found!`

- [ ] **Step 6: Commit**

  ```bash
  git add lib/screens/auth/auth_gate.dart
  git commit -m "feat(geofence): start/stop GeofenceProvider on auth state change in AuthGate"
  ```

---

## Task 10: Add bell icon to SavedPlacesScreen

**Files:**
- Modify: `lib/screens/profile/saved_places_screen.dart`

The `_SavedPlaceCard` currently shows a bookmark button on the right. We add a bell `IconButton` to its left:
- `Icons.notifications_active` + `AppColors.terracotta` when `reminderEnabled = true`
- `Icons.notifications_none` + `AppColors.warmGrey` when `reminderEnabled = false`

`reminderEnabled` is passed as a constructor parameter (the parent already has `savedProvider` via `context.watch`, so it can pass it down without an extra provider read inside the card).

- [ ] **Step 1: Update `_SavedPlaceCard` constructor to accept `reminderEnabled`**

  Find the `_SavedPlaceCard` class declaration:

  ```dart
  class _SavedPlaceCard extends StatelessWidget {
    final RestaurantModel restaurant;
    const _SavedPlaceCard({required this.restaurant});
  ```

  Replace with:

  ```dart
  class _SavedPlaceCard extends StatelessWidget {
    final RestaurantModel restaurant;
    final bool reminderEnabled;
    const _SavedPlaceCard({
      required this.restaurant,
      required this.reminderEnabled,
    });
  ```

- [ ] **Step 2: Add bell IconButton in the `build` method**

  In `_SavedPlaceCard.build`, find the existing `IconButton` (the bookmark button):

  ```dart
            IconButton(
              icon: const Icon(Icons.bookmark,
                  color: AppColors.terracotta, size: 20),
              onPressed: () async {
                final uid =
                    context.read<AuthProvider>().user?.uid ?? '';
                await context
                    .read<SavedPlacesProvider>()
                    .toggleSave(uid: uid, restaurant: restaurant);
              },
            ),
  ```

  Replace it with two buttons:

  ```dart
            IconButton(
              icon: Icon(
                reminderEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: reminderEnabled
                    ? AppColors.terracotta
                    : AppColors.warmGrey,
                size: 20,
              ),
              onPressed: () async {
                final uid =
                    context.read<AuthProvider>().user?.uid ?? '';
                await context
                    .read<SavedPlacesProvider>()
                    .toggleReminder(uid, restaurant.id);
              },
            ),
            IconButton(
              icon: const Icon(Icons.bookmark,
                  color: AppColors.terracotta, size: 20),
              onPressed: () async {
                final uid =
                    context.read<AuthProvider>().user?.uid ?? '';
                await context
                    .read<SavedPlacesProvider>()
                    .toggleSave(uid: uid, restaurant: restaurant);
              },
            ),
  ```

- [ ] **Step 3: Pass `reminderEnabled` from the ListView**

  In `_SavedPlacesScreenState.build`, find the `ListView.builder`:

  ```dart
  itemBuilder: (_, i) =>
      _SavedPlaceCard(restaurant: restaurants[i]),
  ```

  Replace with:

  ```dart
  itemBuilder: (_, i) => _SavedPlaceCard(
    restaurant: restaurants[i],
    reminderEnabled: savedProvider.reminderEnabled(restaurants[i].id),
  ),
  ```

- [ ] **Step 4: Verify no analysis errors**

  ```bash
  flutter analyze lib/screens/profile/saved_places_screen.dart
  ```

  Expected: `No issues found!`

- [ ] **Step 5: Full project analysis**

  ```bash
  flutter analyze lib/
  ```

  Expected: `No issues found!`

- [ ] **Step 6: Commit**

  ```bash
  git add lib/screens/profile/saved_places_screen.dart
  git commit -m "feat(ui): add reminder bell toggle to SavedPlacesScreen cards"
  ```

---

## Verification Checklist

After all tasks are complete, manually verify:

- [ ] Cold-start with Wi-Fi off: restaurant feed shows cached data (not blank or error)
- [ ] Cold-start with Wi-Fi off and saved places exist: Saved Places screen shows cards
- [ ] Hot-restart with Wi-Fi on: restaurant feed refreshes from Firestore and cache is written
- [ ] Saved Places screen: each card shows two right-side icons (bell + bookmark)
- [ ] Tapping bell toggles icon between `notifications_active` (terracotta) and `notifications_none` (grey)
- [ ] Toggle survives hot-restart (flag is persisted in Firestore)
- [ ] Sign out then sign back in: `GeofenceProvider.start()` is called once; no duplicate subscriptions
- [ ] `flutter analyze lib/` returns `No issues found!`
