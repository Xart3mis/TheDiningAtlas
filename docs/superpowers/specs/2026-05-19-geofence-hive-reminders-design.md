# Design: Geofence Notifications, Hive Cache & Location Reminders

**Date:** 2026-05-19  
**Scope:** Three missing features identified in the adherence audit:
1. Hive offline cache (restaurant feed + saved place IDs)
2. Location reminders data layer (per-place reminder toggle)
3. Proximity-triggered push notifications via GeofenceProvider

Chat schedule enforcement (originally item 5) is out of scope for this implementation.

---

## 1. Hive Offline Cache

### Dependencies
Add to `pubspec.yaml`:
```yaml
hive: ^2.2.3
hive_flutter: ^1.1.0
```
No code generation or TypeAdapters. All data is stored as JSON strings in `Box<String>`.

### Initialisation
In `main()`, before `Firebase.initializeApp()`:
```dart
await Hive.initFlutter();
await Hive.openBox<String>('restaurant_feed'); // key: cityId → JSON array
await Hive.openBox<String>('saved_ids');       // key: uid → JSON array of IDs
```

### RestaurantModel serialisation
Add `toJson()` and `fromJson()` to `RestaurantModel`. These mirror `toFirestore()` / `fromFirestore()` but replace `GeoPoint` with plain `lat` and `lng` doubles, since Hive cannot store Firestore types.

### RestaurantProvider — stale-while-revalidate
`loadFeed(cityId)` flow:
1. Read `restaurant_feed.get(cityId)` — if present, decode and emit to UI immediately.
2. Fetch from Firestore in parallel (regardless of cache hit).
3. On Firestore success: update provider state and overwrite Hive entry.
4. On Firestore failure + no cache: surface the existing error path unchanged.

### SavedPlacesProvider — ID cache
After a successful `fetchSavedPlaceIds()` call, serialise the list to JSON and write to `saved_ids.put(uid, json)`. On cold start with no connectivity, read from Hive and skip the per-restaurant detail fetches (show IDs only, no crash).

---

## 2. Location Reminders Data Layer

### Existing infrastructure
- `savePlace(uid, placeId, reminderEnabled: true)` already writes `reminderEnabled` to `users/{uid}/savedPlaces/{placeId}`.
- `unsavePlace()` already deletes that doc.

### What is missing
- The reminder flag is never loaded back when fetching saved places.
- There is no way for the user to toggle a reminder after saving.

### SavedPlacesProvider changes
- Add `Map<String, bool> _reminders` — maps placeId → reminderEnabled.
- `loadSavedRestaurants()` fetches both the restaurant model and the saved-place doc's `reminderEnabled` field for each ID. Populate `_reminders` from these docs.
- Expose `bool reminderEnabled(String placeId)` getter.
- Add `Future<void> toggleReminder(String uid, String placeId)` — flips the flag in `_reminders`, calls `IUserService.updateReminderEnabled()`, then calls `GeofenceProvider.setWatchList()` so the monitor reflects the change immediately.

### IUserService / FirestoreUserService
Add `Future<void> updateReminderEnabled(String uid, String placeId, bool enabled)` — a single-field update on `users/{uid}/savedPlaces/{placeId}`.

### SavedPlacesScreen UI
Add a bell `IconButton` next to each saved place card:
- Filled bell (`notifications_active`) = reminder on.
- Outlined bell (`notifications_none`) = reminder off.
- Tapping calls `savedPlacesProvider.toggleReminder(uid, placeId)`.

---

## 3. GeofenceProvider

### File
`lib/providers/geofence_provider.dart`

### Constructor
```dart
GeofenceProvider(INotificationService notificationService, ILocationService locationService)
```

### Public API
| Method | Description |
|---|---|
| `void start()` | Subscribes to `ILocationService.positionStream()`. No-op if already started. |
| `void stop()` | Cancels the stream subscription. |
| `void setWatchList(List<RestaurantModel> places, Map<String, bool> reminders)` | Replaces the internal watch list. Safe to call at any time. |

### Proximity logic
On every position tick from the stream:
1. Iterate all watched places where `reminders[place.id] == true`.
2. Compute `Geolocator.distanceBetween(userLat, userLng, place.geopoint.latitude, place.geopoint.longitude)`.
3. If distance < `AppConstants.kGeofenceRadiusMeters` (500 m):
   - Check `_lastNotified[place.id]` — skip if notified within the last **1 hour**.
   - Otherwise: call `notificationService.showLocalNotification(title: 'You\'re near ${place.name}', body: place.tip)`, record `_lastNotified[place.id] = DateTime.now()`.

### Cooldown
`Map<String, DateTime> _lastNotified` — in-memory, cleared on `stop()`. One hour prevents notification spam when the user lingers near a place.

### FcmNotificationService — fill the stub
`scheduleGeofenceNotification()` and `cancelGeofenceNotification()` stubs in `FcmNotificationService` are no longer called from `SavedPlacesProvider` (the live watch replaces them). Remove the call-sites and leave the stubs as no-ops, or remove them from the interface if clean-up is preferred.

### Lifecycle
- `AuthGate`: on authenticated state → `geofenceProvider.start()`. On signed-out state → `geofenceProvider.stop()`.
- `SavedPlacesProvider.loadSavedRestaurants()`: after populating state, call `geofenceProvider.setWatchList(_savedRestaurants, _reminders)`.
- `SavedPlacesProvider.toggleSave()`: after updating state, call `geofenceProvider.setWatchList(...)`.
- `SavedPlacesProvider.toggleReminder()`: after updating state, call `geofenceProvider.setWatchList(...)`.

### Registration
In `ServiceProvider.getProviders()`:
```dart
ChangeNotifierProxyProvider2<INotificationService, ILocationService, GeofenceProvider>(
  create: (ctx) => GeofenceProvider(
    ctx.read<INotificationService>(),
    ctx.read<ILocationService>(),
  ),
  update: (_, __, ___, prev) => prev!,
)
```
`SavedPlacesProvider` is updated to also receive `GeofenceProvider` in its constructor.

---

## Data flow summary

```
User saves a place
  → SavedPlacesProvider.toggleSave()
      → IUserService.savePlace(reminderEnabled: true)
      → GeofenceProvider.setWatchList(updatedList, reminders)

User toggles bell icon
  → SavedPlacesProvider.toggleReminder()
      → IUserService.updateReminderEnabled(uid, placeId, newValue)
      → GeofenceProvider.setWatchList(updatedList, updatedReminders)

App in foreground, user walks near saved place
  → GeolocatorLocationService.positionStream() emits position
      → GeofenceProvider checks distance < 500m & cooldown
          → INotificationService.showLocalNotification()
```

---

## Files changed

| File | Change |
|---|---|
| `pubspec.yaml` | Add hive + hive_flutter |
| `lib/main.dart` | Hive init + box opens |
| `lib/models/restaurant_model.dart` | Add toJson / fromJson |
| `lib/providers/restaurant_provider.dart` | Stale-while-revalidate with Hive |
| `lib/providers/saved_places_provider.dart` | Load reminders, toggleReminder, setWatchList calls, Hive ID cache |
| `lib/providers/geofence_provider.dart` | **New file** |
| `lib/services/interfaces/i_user_service.dart` | Add updateReminderEnabled |
| `lib/services/firebase/firestore_user_service.dart` | Implement updateReminderEnabled |
| `lib/screens/profile/saved_places_screen.dart` | Bell toggle UI |
| `lib/screens/auth/auth_gate.dart` | start/stop GeofenceProvider on auth change |
| `lib/core/service_provider.dart` | Register GeofenceProvider |
