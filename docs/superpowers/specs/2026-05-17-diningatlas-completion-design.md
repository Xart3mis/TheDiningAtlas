# DiningAtlas — Full Completion Design
**Date:** 2026-05-17  
**Status:** Approved  
**Team:** Joe (backend, `joe` branch) · Bedo (UI, `bedo` branch)  
**Deadline:** Course final — all features required

---

## 1. Context

DiningAtlas (working name: LikeALocal) is a Flutter + Firebase community-driven travel and discovery app. As of May 2026, the project has:

- Complete Firebase Auth (email/password + Google Sign-In)
- 5 main screens + 5 detail screens — fully designed, all mock data
- Design system (colors, typography, theme) centralized
- Provider-based state management (auth only)
- Zero Firestore reads/writes beyond auth
- No AI features, no real map, no notifications, no chat

**Goal:** Ship every feature from the design doc for the course final.

---

## 2. Architecture

### Approach: Vertical Slices with Shared Interface Contracts

Both developers work in parallel from Day 1. The key mechanism is:

1. Joe writes abstract service interfaces (`services/interfaces/i_*.dart`) + mock implementations on Day 1
2. Bedo wires UI against mock services immediately
3. Joe replaces mock impls with real Firebase/AI impls behind the same interface — Bedo's screens require zero changes

### Folder Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart        # Firestore collection names, free tier limits, API key refs
│   │   └── route_names.dart          # Named route string constants
│   └── errors/
│       └── app_exception.dart        # Typed exceptions: NetworkError, AuthError, QuotaError, etc.
├── models/
│   ├── restaurant_model.dart
│   ├── review_model.dart
│   ├── user_model.dart
│   ├── trip_model.dart
│   ├── chat_model.dart
│   ├── place_summary_model.dart      # AI summary structured output
│   └── onboarding_prefs_model.dart   # Taste profile from onboarding
├── services/
│   ├── interfaces/                   # Abstract contracts — written Day 1 by Joe
│   │   ├── i_auth_service.dart
│   │   ├── i_restaurant_service.dart
│   │   ├── i_review_service.dart
│   │   ├── i_user_service.dart
│   │   ├── i_trip_service.dart
│   │   ├── i_chat_service.dart
│   │   ├── i_storage_service.dart
│   │   ├── i_location_service.dart
│   │   ├── i_notification_service.dart
│   │   ├── i_ai_service.dart
│   │   └── i_subscription_service.dart
│   ├── mock/                         # Mock impls — written Day 1, used by Bedo
│   │   ├── mock_restaurant_service.dart
│   │   ├── mock_review_service.dart
│   │   ├── mock_user_service.dart
│   │   ├── mock_trip_service.dart
│   │   ├── mock_chat_service.dart
│   │   ├── mock_storage_service.dart
│   │   ├── mock_location_service.dart
│   │   ├── mock_notification_service.dart
│   │   ├── mock_ai_service.dart
│   │   └── mock_subscription_service.dart
│   ├── firebase/                     # Real impls — Joe builds across the project
│   │   ├── firebase_auth_service.dart
│   │   ├── firestore_restaurant_service.dart
│   │   ├── firestore_review_service.dart
│   │   ├── firestore_user_service.dart
│   │   ├── firestore_trip_service.dart
│   │   ├── firestore_chat_service.dart
│   │   ├── firebase_storage_service.dart
│   │   └── fcm_notification_service.dart
│   └── ai/
│       └── groq_ai_service.dart      # Groq/Gemini API — recommendations, translation, summarizer
├── providers/
│   ├── auth_provider.dart            # existing, keep
│   ├── restaurant_provider.dart
│   ├── review_provider.dart
│   ├── user_provider.dart
│   ├── trip_provider.dart
│   ├── chat_provider.dart
│   ├── saved_places_provider.dart
│   ├── onboarding_provider.dart
│   ├── notification_provider.dart
│   └── ai_provider.dart
├── screens/
│   ├── auth/                         # existing
│   ├── onboarding/
│   │   ├── onboarding_shell.dart
│   │   ├── vibe_selector_screen.dart
│   │   ├── budget_screen.dart
│   │   ├── atmosphere_screen.dart
│   │   ├── city_screen.dart
│   │   └── profile_ready_screen.dart
│   ├── home/
│   │   └── atlas_screen.dart         # existing, wire providers
│   ├── explore/
│   │   ├── for_you_screen.dart       # existing, wire AI recs
│   │   └── search_screen.dart
│   ├── map/
│   │   └── map_search_screen.dart    # existing, replace with Google Maps
│   ├── restaurant/
│   │   ├── restaurant_detail_screen.dart
│   │   ├── write_review_screen.dart
│   │   └── add_place_screen.dart     # new, multi-step form
│   ├── trips/
│   │   └── trips_screen.dart
│   ├── chat/
│   │   └── chat_thread_screen.dart   # new
│   ├── stories/
│   │   └── stories_screen.dart
│   ├── profile/
│   │   ├── profile_screen.dart
│   │   └── settings_screen.dart      # new
│   └── premium/
│       └── premium_upgrade_screen.dart # new
├── widgets/
│   └── shared_widgets.dart           # existing, expand
└── theme/
    └── app_theme.dart                # existing
```

---

## 3. Naming Conventions

### Files
| Type | Convention | Example |
|---|---|---|
| Screens | `snake_case_screen.dart` | `write_review_screen.dart` |
| Service interface | `i_<domain>_service.dart` | `i_review_service.dart` |
| Firebase service impl | `firestore_<domain>_service.dart` | `firestore_review_service.dart` |
| Mock service impl | `mock_<domain>_service.dart` | `mock_review_service.dart` |
| Providers | `<domain>_provider.dart` | `review_provider.dart` |
| Models | `<domain>_model.dart` | `review_model.dart` |

### Classes & Identifiers
| Type | Convention | Example |
|---|---|---|
| Classes | `PascalCase` | `ReviewModel`, `FirestoreReviewService` |
| Service interfaces | `IPascalCaseService` | `IReviewService` |
| Private screen widgets | `_PascalCase` | `_ReviewCard` |
| Methods | `camelCase` verbs | `submitReview()`, `fetchNearby()` |
| Constants | `kCamelCase` | `kMaxSavedFree = 10` |
| Firestore collection refs | `SCREAMING_SNAKE` in `app_constants.dart` | `kColRestaurants = 'restaurants'` |
| Route names | `SCREAMING_SNAKE` in `route_names.dart` | `kRouteRestaurantDetail = '/restaurant'` |

### Git Branches
```
joe          # backend dev main branch (already exists)
bedo         # UI dev main branch

joe/<slug>   # Joe's feature branches   e.g. joe/firestore-restaurants
bedo/<slug>  # Bedo's feature branches  e.g. bedo/onboarding-screens
```
Merge flow: `joe/<slug>` → `joe` → `main` when stable. Same for `bedo`.

---

## 4. Firestore Schema

```
restaurants/{restaurantId}
  name, category, geopoint, description, tip, dish,
  mediaUrls[], contributorId, status, avgRating,
  reviewCount, saveCount, cityId, priceRange,
  createdAt, updatedAt

  reviews/{reviewId}
    authorId, text, rating, createdAt, upvotes
    translations/{lang}
      translatedText, cachedAt

  summary/                       ← single document
    vibeOneLiner, topAspects[],
    mainDish, caveats[], bestTime,
    generatedAt, reviewCountAtGeneration

users/{uid}
  displayName, email, photoUrl,
  tier, score, isPremium,
  chatPrivacy: { mode, schedule },
  onboardingComplete, createdAt

  preferences/                   ← single document
    vibes[], budget, atmosphere[],
    cityId, aiWeights[]

  savedPlaces/{placeId}
    reminderEnabled, savedAt

trips/{uid}/days/{dayId}
  date
  spots/{spotId}
    time, mealType, restaurantId, name,
    neighborhood, statusLabel, statusColor

chats/{chatId}
  participants[], relatedPlaceId,
  lastMessage, lastUpdated

  messages/{messageId}
    senderId, text, status, createdAt
    translations/{lang}
      translatedText, cachedAt
```

---

## 5. Feature Assignments

### Phase 1 — Foundation (Day 1, both developers together, ~3 hours)

| Task | Owner |
|---|---|
| Split `models.dart` into individual model files | Joe |
| Write all service interfaces in `services/interfaces/` | Joe |
| Write all mock service implementations in `services/mock/` | Joe |
| Set up `core/constants/app_constants.dart` | Joe |
| Wire all providers into `main.dart` using mock services | Bedo |
| Set up `core/constants/route_names.dart` + named routing | Bedo |

---

### Phase 2 — Parallel Feature Work

#### Feature A: Onboarding + AI Taste Profile
**Joe:** `IOnboardingService` + mock → `FirestoreUserService.savePreferences()` → Groq API call (prefs JSON → ranked categories) → store AI weights → auth gate routing  
**Bedo:** `onboarding_shell.dart` PageView → 5 onboarding screens → wire `OnboardingProvider`

#### Feature B: Restaurants — Real Data
**Joe:** `IRestaurantService` + mock → `FirestoreRestaurantService` (fetchFeed, fetchNearby, fetchByCategory, fetchByCity) → seed Firestore with sample data  
**Bedo:** Wire `RestaurantProvider` into `AtlasScreen` and `ForYouScreen` → loading shimmer states → category/city filter wired → `AddPlaceScreen` multi-step form

#### Feature C: Reviews
**Joe:** `IReviewService` + mock → `FirestoreReviewService` (submit, fetch, edit, delete, upvote) → translation caching  
**Bedo:** Wire `ReviewProvider` into `RestaurantDetailScreen` reviews tab → `WriteReviewScreen._onPost()` → edit/delete UI → "Translate" chip + show original toggle

#### Feature D: Save / Pin Places
**Joe:** `ISavedPlacesService` + mock → `FirestoreUserService` save/unsave → free tier cap (10 saves) → geofence scheduling on save  
**Bedo:** Save button toggle on `RestaurantDetailScreen` → `ProfileScreen` saved list wired → reminder toggle

#### Feature E: Map & Location
**Joe:** `ILocationService` + mock → Geolocator current position → Firestore geopoint queries → geofence setup  
**Bedo:** Replace custom-painted map with Google Maps Flutter widget → clustered pins → 500m radius overlay → wire filter pills

#### Feature F: Push Notifications
**Joe:** FCM setup → `INotificationService` + mock → `FcmNotificationService` token registration → Cloud Function triggers → `flutter_local_notifications` geofence  
**Bedo:** Permission request UI on first launch → in-app notification badge → notifications history screen

#### Feature G: User-to-User Chat
**Joe:** `IChatService` + mock → `FirestoreChatService` create/fetch chats + real-time listener → privacy mode logic → translation caching  
**Bedo:** `ChatThreadScreen` full UI → "Message" button wired on `RestaurantDetailScreen` → online indicator → availability badge → inline translate chip

#### Feature H: Super User / Reputation
**Joe:** Cloud Functions for score updates + decay → server-side anti-gaming validation  
**Bedo:** Tier badge on profile + review cards → stats card wired to real data

#### Feature I: AI Place Summarizer
**Joe:** Cloud Function trigger (10 new reviews) → batch 50 reviews → Groq/Gemini API → `PlaceSummaryModel` → 7-day TTL cache in Firestore  
**Bedo:** AI Summary Card widget at top of reviews tab → skeleton loader → display all 5 summary fields

#### Feature J: AI Translation
**Joe:** `IAiService.translate()` → Groq/Gemini API with tone-preserving prompt → Firestore cache → free tier 5/day quota  
**Bedo:** "Translate" chip on review cards + chat bubbles → loading indicator → "Show original" toggle

#### Feature K: Monetisation (Freemium)
**Joe:** `ISubscriptionService` + mock → `users/{uid}.isPremium` → Cloud Function limit enforcement  
**Bedo:** `PremiumUpgradeScreen` → premium gate blur/lock UI → upgrade nudge banners → promoted listing badge

---

### Phase 3 — Polish (Both, final stretch)

- Replace all striped-tile placeholders with `cached_network_image`
- Firebase Storage image upload in `AddPlaceScreen` and `WriteReviewScreen`
- Offline caching with Hive (last 20 feed items)
- Loading shimmer on every list
- Network error banners + retry logic
- Form validation on all input screens
- Accessibility: semantic labels on interactive elements
- App icon + splash screen

---

## 6. AI Integration

**Provider:** Groq API or Gemini API (key stored in environment, never hardcoded)  
**All calls go through:** `IAiService` → `GroqAiService`

| Feature | Prompt Strategy | Cache |
|---|---|---|
| Recommendations | User prefs JSON → ranked `{category, tags[], reason}[]` | Firestore `users/{uid}/preferences.aiWeights`, refresh max once/24h |
| Translation | Text + target language → tone-preserving translation | Firestore `reviews/{id}/translations/{lang}`, permanent |
| Summarizer | Last 50 reviews batched → structured JSON summary | Firestore `places/{id}/summary`, 7-day TTL |

**Cost controls:**
- Free users: 5 translations/day, basic recommendations only (top 5)
- Summaries: generated at most once per 7 days per place via Cloud Function TTL check
- Recommendation re-queries: rate-limited to once per 24 hours unless user explicitly refreshes
- All quota enforcement in Cloud Functions (never client-side)

---

## 7. Error Handling

| Scenario | User Response | Mechanism |
|---|---|---|
| No internet on launch | Hive cache served + "Offline mode" banner | `connectivity_plus` listener |
| Firestore write fails | Optimistic update rolled back + snackbar | `try/catch` + Provider rollback |
| Image upload timeout | Retry 3× exponential backoff, notify on final failure | Firebase Storage task retry |
| Auth token expired | Background refresh; navigate to login on failure | Firebase Auth stream |
| Form validation errors | Inline red error text per field, submit disabled | Flutter `Form` + validators |
| AI API timeout (>8s) | Fallback to static tag-based results from Firestore | `Future.timeout` fallback |
| Geofence not supported | Feature hidden silently | Platform capability check |
| Free tier quota hit | Upgrade nudge modal | `QuotaError` from service layer |

---

## 8. Packages to Add

```yaml
# Location & Maps
google_maps_flutter: ^2.5.0
geolocator: ^11.0.0
geoflutterfire_plus: ^0.0.30   # Geohash queries on Firestore

# Notifications
firebase_messaging: ^15.0.0
flutter_local_notifications: ^17.0.0

# AI
http: ^1.2.0                   # Groq/Gemini REST calls

# Images
cached_network_image: ^3.3.0
image_picker: ^1.0.7

# Offline
hive: ^2.2.3
hive_flutter: ^1.1.0

# Subscriptions (or use manual Firestore flag for course)
# purchases_flutter: ^6.0.0   # RevenueCat — add only if time permits

# UI helpers
shimmer: ^3.0.0
connectivity_plus: ^6.0.0
```

---

## 9. Suggested Extra Features Worth Adding

These were not in the original design doc but are low-effort, high-impact for the course demo:

1. **Dark mode** — Theme already uses `AppColors`, just add a dark variant. Toggle in `SettingsScreen`. One afternoon's work.
2. **Share a place** — Native share sheet via `share_plus`. Single line of code per card. Makes the app feel real.
3. **Restaurant photo gallery** — Full-screen swipeable gallery on `RestaurantDetailScreen` photos tab. `PageView` + `cached_network_image`. Already scaffolded.
4. **Contribution streak / activity heatmap on profile** — GitHub-style grid showing days the user posted. Pure UI, no backend needed. Strong visual for the demo.
5. **"Serendipity mode" toggle** — Button on map screen that immediately navigates to a random highly-rated nearby place. 10 lines of logic, memorable demo moment.

---

## 10. Definition of Done

A feature is complete when:
- [ ] Real data flows end-to-end (no mock service in production path)
- [ ] Loading state shown while data fetches
- [ ] Error state handled (no unhandled exceptions)
- [ ] Free tier limits enforced
- [ ] Works offline (cached) or shows graceful offline message
- [ ] No hardcoded strings that should be constants
