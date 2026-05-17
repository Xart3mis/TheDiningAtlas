# DiningAtlas — Claude Context

## What This App Is

DiningAtlas (formerly LikeALocal) is a Flutter + Firebase community travel discovery app. Users discover restaurants and hidden gems the way locals experience them. Built as a course final project — **all features must be implemented**.

Core differentiators: AI-powered onboarding taste profile, AI review translation, AI place summarizer.

## Team

| Developer | Branch | Owns |
|---|---|---|
| Joe | `joe` | All backend: `services/`, `providers/`, Firestore schema, Cloud Functions, AI API calls |
| Bedo | `bedo` | All UI: `screens/`, navigation, widgets, onboarding flow, form wiring |

Feature branches: `joe/<slug>` and `bedo/<slug>`. Merge into owner's main branch, then into `main`.

## Tech Stack

- **Frontend:** Flutter (Dart), Provider for state management
- **Backend:** Firebase (Auth, Firestore, Storage, Cloud Functions, FCM)
- **AI:** Groq API or Gemini API (NOT Anthropic/Claude API) — key in environment, never hardcoded
- **Maps:** Google Maps Flutter plugin + Geolocator
- **Offline:** Hive local cache

## Current Implementation Status

**Done (working):**
- Firebase Auth — email/password + Google Sign-In
- All 5 main screens UI (Atlas, For You, Stories, Trips, Profile) — mock data only
- All detail screens UI (Restaurant Detail, City Guide, Map Search, Write Review) — mock data only
- Design system: `theme/app_theme.dart` (AppColors, AppTextStyles)
- Provider auth wrapper

**Not done (everything backend):**
- Firestore reads/writes (dependency added, zero usage)
- Firebase Storage image uploads
- Real restaurant/review/user data
- Search, filter, save, review submission logic
- Push notifications, location, real Google Maps
- All AI features
- Chat, onboarding, super user, monetisation

## Architecture — Interface Contract Pattern

The core pattern for parallel development:

1. Joe writes `services/interfaces/i_*.dart` (abstract classes) + `services/mock/mock_*.dart` on Day 1
2. Bedo codes all screens against the mock services
3. Joe replaces mocks with real Firebase impls in `services/firebase/` — Bedo's code requires zero changes
4. Swap happens in `main.dart` via Provider registration

**Never call Firebase directly from a screen.** All Firebase access goes through a service class behind an interface.

## Folder Structure

```
lib/
├── core/constants/          # app_constants.dart, route_names.dart
├── core/errors/             # app_exception.dart
├── models/                  # one file per model: restaurant_model.dart, etc.
├── services/interfaces/     # i_*.dart abstract contracts (auth, restaurant, review, user, trip, chat, storage, location, notification, ai, subscription)
├── services/mock/           # mock_*.dart with hardcoded sample data
├── services/firebase/       # real Firebase implementations
├── services/ai/             # groq_ai_service.dart
├── providers/               # ChangeNotifiers, one per domain
├── screens/                 # organized by feature domain
├── widgets/                 # shared_widgets.dart
└── theme/                   # app_theme.dart
```

## Naming Conventions

| Type | Convention | Example |
|---|---|---|
| Files | `snake_case` | `write_review_screen.dart` |
| Screen files | `*_screen.dart` | `chat_thread_screen.dart` |
| Service interface | `i_<domain>_service.dart` | `i_review_service.dart` |
| Service interface class | `I<Domain>Service` | `IReviewService` |
| Firebase impl file | `firestore_<domain>_service.dart` | `firestore_review_service.dart` |
| Mock impl file | `mock_<domain>_service.dart` | `mock_review_service.dart` |
| Provider file | `<domain>_provider.dart` | `review_provider.dart` |
| Model file | `<domain>_model.dart` | `review_model.dart` |
| Constants | `kCamelCase` | `kMaxSavedFree = 10` |
| Firestore collection name constants | `SCREAMING_SNAKE` in `app_constants.dart` | `kColRestaurants = 'restaurants'` |
| Route name constants | `SCREAMING_SNAKE` in `route_names.dart` | `kRouteRestaurantDetail = '/restaurant'` |
| Private widgets inside a screen | `_PascalCase` | `_ReviewCard` |

## Firestore Schema (top-level collections)

```
restaurants/{restaurantId}     → reviews/{reviewId} → translations/{lang}
                               → summary/ (single doc)
users/{uid}                    → preferences/ (single doc)
                               → savedPlaces/{placeId}
chats/{chatId}                 → messages/{messageId} → translations/{lang}
trips/{uid}/days/{dayId}       → spots/{spotId}
```

## AI Features

All AI calls go through `IAiService` → `GroqAiService`.

| Feature | Where triggered | Cache location |
|---|---|---|
| Taste profile recommendations | Onboarding + feed refresh | `users/{uid}/preferences.aiWeights` |
| Review/chat translation | On-demand tap | `reviews/{id}/translations/{lang}` |
| Place summarizer | Cloud Function at 10 new reviews | `restaurants/{id}/summary` |

Free tier limits enforced in Cloud Functions, never client-side.

## Key Design Decisions

- **No named route package** — use `onGenerateRoute` in `main.dart` with constants from `route_names.dart`
- **No Riverpod/Bloc** — Provider only, keep it consistent with existing code
- **No client-side quota enforcement** — all free tier limits live in Cloud Functions
- **Translations are permanent cache** — never re-translate the same text+language combo
- **Summarizer is 7-day TTL** — Cloud Function checks TTL before calling AI
- **Score updates are server-side only** — never trust the client for reputation scoring

## Design System

Colors: `AppColors.cream`, `.terracotta`, `.sage`, `.teal`, `.charcoal`  
Typography: Fraunces (serif, display) + Inter (sans-serif, body) via `AppTextStyles`  
Image placeholders: diagonal-stripe tiles (`DecorationImage` with custom painter) — replace with `cached_network_image` when real images are available

## Definition of Done

A feature is shippable when:
- Real data flows end-to-end (no mock service in the production path)
- Loading state shown while data fetches
- Error state handled (no unhandled exceptions reaching the user)
- Free tier limits enforced
- Works offline with cached data or shows a graceful offline message

## Full Design Doc

[docs/superpowers/specs/2026-05-17-diningatlas-completion-design.md](docs/superpowers/specs/2026-05-17-diningatlas-completion-design.md)

## Packages in Use (or to be added)

```yaml
# existing
firebase_core, firebase_auth, cloud_firestore, firebase_storage
provider, google_sign_in, google_fonts

# to add
google_maps_flutter, geolocator, geoflutterfire_plus
firebase_messaging, flutter_local_notifications
http                          # Groq/Gemini REST calls
cached_network_image, image_picker
hive, hive_flutter
shimmer, connectivity_plus
```
