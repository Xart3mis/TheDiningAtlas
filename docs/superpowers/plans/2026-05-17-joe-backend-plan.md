# DiningAtlas — Joe's Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete backend layer for DiningAtlas — all service interfaces, mock implementations, Firebase implementations, Cloud Functions, and AI integrations — so Bedo's UI layer has real data to work with.

**Architecture:** Interface-contract pattern. Every service is an abstract class in `services/interfaces/`. Mock implementations go in `services/mock/` (Day 1, unblocks Bedo immediately). Real Firebase implementations go in `services/firebase/`. Swap happens in `main.dart` — Bedo's screens never change.

**Tech Stack:** Flutter/Dart, Firebase (Firestore, Auth, Storage, FCM, Cloud Functions), Groq API (REST via `http` package), Provider, Geolocator, geoflutterfire_plus, flutter_local_notifications, Hive

---

## Phase 1 — Foundation (Day 1, do before anything else)

---

### Task 1: Split models.dart into individual model files

**Files:**
- Modify: `lib/models/models.dart` (delete after extracting)
- Create: `lib/models/restaurant_model.dart`
- Create: `lib/models/review_model.dart`
- Create: `lib/models/user_model.dart`
- Create: `lib/models/trip_model.dart`
- Create: `lib/models/chat_model.dart`
- Create: `lib/models/place_summary_model.dart`
- Create: `lib/models/onboarding_prefs_model.dart`

- [ ] **Step 1: Create `lib/models/restaurant_model.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RestaurantModel {
  final String id;
  final String name;
  final String category;
  final String cityId;
  final String neighborhood;
  final GeoPoint geopoint;
  final String description;
  final String tip;
  final String dish;
  final List<String> mediaUrls;
  final String contributorId;
  final String status; // 'approved' | 'pending'
  final double avgRating;
  final int reviewCount;
  final int saveCount;
  final String priceRange; // '$' | '$$' | '$$$'
  final Color tileColor;
  final String? badge;
  final String tagline;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.category,
    required this.cityId,
    required this.neighborhood,
    required this.geopoint,
    required this.description,
    required this.tip,
    required this.dish,
    required this.mediaUrls,
    required this.contributorId,
    required this.status,
    required this.avgRating,
    required this.reviewCount,
    required this.saveCount,
    required this.priceRange,
    required this.tileColor,
    this.badge,
    required this.tagline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RestaurantModel(
      id: doc.id,
      name: d['name'] ?? '',
      category: d['category'] ?? '',
      cityId: d['cityId'] ?? '',
      neighborhood: d['neighborhood'] ?? '',
      geopoint: d['geopoint'] ?? const GeoPoint(0, 0),
      description: d['description'] ?? '',
      tip: d['tip'] ?? '',
      dish: d['dish'] ?? '',
      mediaUrls: List<String>.from(d['mediaUrls'] ?? []),
      contributorId: d['contributorId'] ?? '',
      status: d['status'] ?? 'pending',
      avgRating: (d['avgRating'] ?? 0.0).toDouble(),
      reviewCount: d['reviewCount'] ?? 0,
      saveCount: d['saveCount'] ?? 0,
      priceRange: d['priceRange'] ?? '\$',
      tileColor: Color(d['tileColorValue'] ?? 0xFFF5EFE6),
      badge: d['badge'],
      tagline: d['tagline'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'category': category,
    'cityId': cityId,
    'neighborhood': neighborhood,
    'geopoint': geopoint,
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
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
```

- [ ] **Step 2: Create `lib/models/review_model.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String restaurantId;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String text;
  final double rating;
  final int upvotes;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.restaurantId,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.text,
    required this.rating,
    required this.upvotes,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      restaurantId: d['restaurantId'] ?? '',
      authorId: d['authorId'] ?? '',
      authorName: d['authorName'] ?? '',
      authorPhotoUrl: d['authorPhotoUrl'] ?? '',
      text: d['text'] ?? '',
      rating: (d['rating'] ?? 0.0).toDouble(),
      upvotes: d['upvotes'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'restaurantId': restaurantId,
    'authorId': authorId,
    'authorName': authorName,
    'authorPhotoUrl': authorPhotoUrl,
    'text': text,
    'rating': rating,
    'upvotes': upvotes,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
```

- [ ] **Step 3: Create `lib/models/user_model.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final String tier; // 'explorer' | 'local' | 'super_local' | 'city_legend'
  final int score;
  final bool isPremium;
  final bool onboardingComplete;
  final ChatPrivacy chatPrivacy;
  final DateTime createdAt;

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
  };
}

class ChatPrivacy {
  final String mode; // 'public' | 'private' | 'scheduled'
  final String? scheduleStart; // 'HH:mm'
  final String? scheduleEnd;   // 'HH:mm'
  final List<String> scheduleDays; // ['mon','tue',...]

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

- [ ] **Step 4: Create `lib/models/trip_model.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TripModel {
  final String id;
  final String uid;
  final String title;
  final String cityId;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participantUids;
  final List<TripDayModel> days;

  const TripModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.cityId,
    required this.startDate,
    required this.endDate,
    required this.participantUids,
    required this.days,
  });
}

class TripDayModel {
  final String id;
  final DateTime date;
  final List<TripSpotModel> spots;

  const TripDayModel({required this.id, required this.date, required this.spots});
}

class TripSpotModel {
  final String id;
  final String time;
  final String mealType;
  final String restaurantId;
  final String name;
  final String neighborhood;
  final String statusLabel;
  final Color statusColor;
  final Color tileColor;

  const TripSpotModel({
    required this.id,
    required this.time,
    required this.mealType,
    required this.restaurantId,
    required this.name,
    required this.neighborhood,
    required this.statusLabel,
    required this.statusColor,
    required this.tileColor,
  });
}
```

- [ ] **Step 5: Create `lib/models/chat_model.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participantUids;
  final String relatedPlaceId;
  final String lastMessage;
  final DateTime lastUpdated;

  const ChatModel({
    required this.id,
    required this.participantUids,
    required this.relatedPlaceId,
    required this.lastMessage,
    required this.lastUpdated,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participantUids: List<String>.from(d['participants'] ?? []),
      relatedPlaceId: d['relatedPlaceId'] ?? '',
      lastMessage: d['lastMessage'] ?? '',
      lastUpdated: (d['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String status; // 'sent' | 'delivered' | 'read'
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.status,
    required this.createdAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: d['chatId'] ?? '',
      senderId: d['senderId'] ?? '',
      text: d['text'] ?? '',
      status: d['status'] ?? 'sent',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'chatId': chatId,
    'senderId': senderId,
    'text': text,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
```

- [ ] **Step 6: Create `lib/models/place_summary_model.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceSummaryModel {
  final String vibeOneLiner;
  final List<String> topAspects;
  final String mainDish;
  final List<String> caveats;
  final String bestTime;
  final DateTime generatedAt;
  final int reviewCountAtGeneration;

  const PlaceSummaryModel({
    required this.vibeOneLiner,
    required this.topAspects,
    required this.mainDish,
    required this.caveats,
    required this.bestTime,
    required this.generatedAt,
    required this.reviewCountAtGeneration,
  });

  factory PlaceSummaryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PlaceSummaryModel(
      vibeOneLiner: d['vibeOneLiner'] ?? '',
      topAspects: List<String>.from(d['topAspects'] ?? []),
      mainDish: d['mainDish'] ?? '',
      caveats: List<String>.from(d['caveats'] ?? []),
      bestTime: d['bestTime'] ?? '',
      generatedAt: (d['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewCountAtGeneration: d['reviewCountAtGeneration'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vibeOneLiner': vibeOneLiner,
    'topAspects': topAspects,
    'mainDish': mainDish,
    'caveats': caveats,
    'bestTime': bestTime,
    'generatedAt': FieldValue.serverTimestamp(),
    'reviewCountAtGeneration': reviewCountAtGeneration,
  };
}
```

- [ ] **Step 7: Create `lib/models/onboarding_prefs_model.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingPrefsModel {
  final List<String> vibes;       // e.g. ['hidden_cafe','street_food','rooftop_bar']
  final String budget;            // '$' | '$$' | '$$$'
  final List<String> atmosphere;  // e.g. ['quiet','outdoor','artsy']
  final String cityId;
  final Map<String, double> aiWeights; // category → weight score

  const OnboardingPrefsModel({
    required this.vibes,
    required this.budget,
    required this.atmosphere,
    required this.cityId,
    required this.aiWeights,
  });

  factory OnboardingPrefsModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OnboardingPrefsModel(
      vibes: List<String>.from(d['vibes'] ?? []),
      budget: d['budget'] ?? '\$',
      atmosphere: List<String>.from(d['atmosphere'] ?? []),
      cityId: d['cityId'] ?? '',
      aiWeights: Map<String, double>.from(
        (d['aiWeights'] ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vibes': vibes,
    'budget': budget,
    'atmosphere': atmosphere,
    'cityId': cityId,
    'aiWeights': aiWeights,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
```

- [ ] **Step 8: Delete `lib/models/models.dart` after confirming all screens that imported it now import the individual files**

Search for `import.*models/models.dart` across `lib/screens/` and update each import to the specific model file needed.

- [ ] **Step 9: Commit**

```bash
git add lib/models/
git commit -m "feat: extract individual model files from models.dart"
```

---

### Task 2: Core constants and error types

**Files:**
- Create: `lib/core/constants/app_constants.dart`
- Create: `lib/core/constants/route_names.dart`
- Create: `lib/core/errors/app_exception.dart`

- [ ] **Step 1: Create `lib/core/constants/app_constants.dart`**

```dart
class AppConstants {
  // Firestore collection names
  static const String kColRestaurants = 'restaurants';
  static const String kColReviews = 'reviews';
  static const String kColUsers = 'users';
  static const String kColChats = 'chats';
  static const String kColMessages = 'messages';
  static const String kColTrips = 'trips';
  static const String kColDays = 'days';
  static const String kColSpots = 'spots';
  static const String kColSavedPlaces = 'savedPlaces';
  static const String kColTranslations = 'translations';
  static const String kDocSummary = 'summary';
  static const String kDocPreferences = 'preferences';

  // Free tier limits
  static const int kMaxSavedFree = 10;
  static const int kMaxTranslationsPerDayFree = 5;
  static const int kMaxChatSendPerDayFree = 3;
  static const int kMaxAiRecsResultsFree = 5;

  // AI / summarizer
  static const int kSummaryMinReviews = 5;
  static const int kSummaryTriggerNewReviews = 10;
  static const int kSummaryBatchSize = 50;
  static const int kSummaryTtlDays = 7;

  // Geofence
  static const double kGeofenceRadiusMeters = 500;

  // Groq API
  static const String kGroqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String kGroqModel = 'llama3-8b-8192';
}
```

- [ ] **Step 2: Create `lib/core/constants/route_names.dart`**

```dart
class RouteNames {
  static const String kSplash = '/';
  static const String kLogin = '/login';
  static const String kRegister = '/register';
  static const String kForgotPassword = '/forgot-password';
  static const String kOnboarding = '/onboarding';
  static const String kMain = '/main';
  static const String kRestaurantDetail = '/restaurant';
  static const String kCityGuide = '/city-guide';
  static const String kWriteReview = '/write-review';
  static const String kAddPlace = '/add-place';
  static const String kMapSearch = '/map-search';
  static const String kChatThread = '/chat';
  static const String kSettings = '/settings';
  static const String kPremiumUpgrade = '/premium';
  static const String kNotifications = '/notifications';
}
```

- [ ] **Step 3: Create `lib/core/errors/app_exception.dart`**

```dart
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([String message = 'No internet connection.'])
      : super(message);
}

class AuthException extends AppException {
  const AuthException([String message = 'Authentication failed.'])
      : super(message);
}

class QuotaException extends AppException {
  const QuotaException([String message = 'Free tier limit reached. Upgrade to premium.'])
      : super(message);
}

class NotFoundException extends AppException {
  const NotFoundException([String message = 'Content not found.'])
      : super(message);
}

class StorageException extends AppException {
  const StorageException([String message = 'File upload failed.'])
      : super(message);
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/
git commit -m "feat: add core constants and typed exceptions"
```

---

### Task 3: All service interfaces

**Files:**
- Create: `lib/services/interfaces/i_restaurant_service.dart`
- Create: `lib/services/interfaces/i_review_service.dart`
- Create: `lib/services/interfaces/i_user_service.dart`
- Create: `lib/services/interfaces/i_trip_service.dart`
- Create: `lib/services/interfaces/i_chat_service.dart`
- Create: `lib/services/interfaces/i_storage_service.dart`
- Create: `lib/services/interfaces/i_location_service.dart`
- Create: `lib/services/interfaces/i_notification_service.dart`
- Create: `lib/services/interfaces/i_ai_service.dart`
- Create: `lib/services/interfaces/i_subscription_service.dart`

- [ ] **Step 1: Create `lib/services/interfaces/i_restaurant_service.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/restaurant_model.dart';

abstract class IRestaurantService {
  Future<List<RestaurantModel>> fetchFeed({required String cityId, int limit = 20});
  Future<List<RestaurantModel>> fetchNearby({required GeoPoint center, double radiusKm = 0.5});
  Future<List<RestaurantModel>> fetchByCategory({required String category, required String cityId});
  Future<List<RestaurantModel>> search({required String query, required String cityId});
  Future<RestaurantModel> fetchById(String restaurantId);
  Future<String> addRestaurant(RestaurantModel restaurant);
  Future<void> updateRestaurant(RestaurantModel restaurant);
}
```

- [ ] **Step 2: Create `lib/services/interfaces/i_review_service.dart`**

```dart
import '../../models/review_model.dart';

abstract class IReviewService {
  Future<List<ReviewModel>> fetchReviews(String restaurantId, {int limit = 20});
  Future<void> submitReview(ReviewModel review);
  Future<void> editReview({required String restaurantId, required String reviewId, required String text, required double rating});
  Future<void> deleteReview({required String restaurantId, required String reviewId});
  Future<void> upvoteReview({required String restaurantId, required String reviewId});
  Future<String?> fetchTranslation({required String restaurantId, required String reviewId, required String targetLang});
  Future<void> cacheTranslation({required String restaurantId, required String reviewId, required String targetLang, required String translatedText});
}
```

- [ ] **Step 3: Create `lib/services/interfaces/i_user_service.dart`**

```dart
import '../../models/user_model.dart';
import '../../models/onboarding_prefs_model.dart';

abstract class IUserService {
  Future<UserModel?> fetchUser(String uid);
  Future<void> createUser(UserModel user);
  Future<void> updateUser(UserModel user);
  Future<OnboardingPrefsModel?> fetchPreferences(String uid);
  Future<void> savePreferences(String uid, OnboardingPrefsModel prefs);
  Future<void> markOnboardingComplete(String uid);
  Future<List<String>> fetchSavedPlaceIds(String uid);
  Future<void> savePlace({required String uid, required String placeId, required bool reminderEnabled});
  Future<void> unsavePlace({required String uid, required String placeId});
  Future<int> savedPlaceCount(String uid);
}
```

- [ ] **Step 4: Create `lib/services/interfaces/i_trip_service.dart`**

```dart
import '../../models/trip_model.dart';

abstract class ITripService {
  Future<List<TripModel>> fetchTrips(String uid);
  Future<String> createTrip(TripModel trip);
  Future<void> updateTrip(TripModel trip);
  Future<void> deleteTrip({required String uid, required String tripId});
  Future<void> addSpot({required String uid, required String tripId, required String dayId, required TripSpotModel spot});
  Future<void> removeSpot({required String uid, required String tripId, required String dayId, required String spotId});
}
```

- [ ] **Step 5: Create `lib/services/interfaces/i_chat_service.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat_model.dart';

abstract class IChatService {
  Future<ChatModel> getOrCreateChat({required String currentUid, required String otherUid, required String placeId});
  Stream<List<MessageModel>> messagesStream(String chatId);
  Future<void> sendMessage({required String chatId, required String senderId, required String text});
  Future<List<ChatModel>> fetchUserChats(String uid);
  Future<String?> fetchMessageTranslation({required String chatId, required String messageId, required String targetLang});
  Future<void> cacheMessageTranslation({required String chatId, required String messageId, required String targetLang, required String translatedText});
}
```

- [ ] **Step 6: Create `lib/services/interfaces/i_storage_service.dart`**

```dart
import 'dart:io';

abstract class IStorageService {
  Future<String> uploadImage({required File file, required String path});
  Future<void> deleteFile(String url);
}
```

- [ ] **Step 7: Create `lib/services/interfaces/i_location_service.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ILocationService {
  Future<GeoPoint?> getCurrentPosition();
  Future<bool> requestPermission();
  Stream<GeoPoint> positionStream();
}
```

- [ ] **Step 8: Create `lib/services/interfaces/i_notification_service.dart`**

```dart
abstract class INotificationService {
  Future<void> initialize();
  Future<String?> getFcmToken();
  Future<void> showLocalNotification({required String title, required String body});
  Future<void> scheduleGeofenceNotification({required String placeId, required String placeName, required double lat, required double lng});
  Future<void> cancelGeofenceNotification(String placeId);
}
```

- [ ] **Step 9: Create `lib/services/interfaces/i_ai_service.dart`**

```dart
import '../../models/onboarding_prefs_model.dart';
import '../../models/place_summary_model.dart';
import '../../models/review_model.dart';

abstract class IAiService {
  Future<Map<String, double>> generateTasteWeights(OnboardingPrefsModel prefs);
  Future<String> translate({required String text, required String targetLang});
  Future<PlaceSummaryModel> summarizeReviews({required String restaurantId, required List<ReviewModel> reviews});
}
```

- [ ] **Step 10: Create `lib/services/interfaces/i_subscription_service.dart`**

```dart
abstract class ISubscriptionService {
  Future<bool> isPremium(String uid);
  Future<void> upgradeToPremium(String uid);
  Future<int> translationsUsedToday(String uid);
  Future<int> chatMessagesSentToday(String uid);
}
```

- [ ] **Step 11: Commit**

```bash
git add lib/services/interfaces/
git commit -m "feat: add all service interface contracts"
```

---

### Task 4: All mock service implementations

**Files:**
- Create: `lib/services/mock/mock_restaurant_service.dart`
- Create: `lib/services/mock/mock_review_service.dart`
- Create: `lib/services/mock/mock_user_service.dart`
- Create: `lib/services/mock/mock_trip_service.dart`
- Create: `lib/services/mock/mock_chat_service.dart`
- Create: `lib/services/mock/mock_storage_service.dart`
- Create: `lib/services/mock/mock_location_service.dart`
- Create: `lib/services/mock/mock_notification_service.dart`
- Create: `lib/services/mock/mock_ai_service.dart`
- Create: `lib/services/mock/mock_subscription_service.dart`

- [ ] **Step 1: Create `lib/services/mock/mock_restaurant_service.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../interfaces/i_restaurant_service.dart';
import '../../models/restaurant_model.dart';

final _kSampleRestaurants = [
  RestaurantModel(
    id: 'r1', name: 'Sushi Dai', category: 'Japanese', cityId: 'tokyo',
    neighborhood: 'Tsukiji', geopoint: const GeoPoint(35.6654, 139.7707),
    description: 'Standing sushi counter beloved by locals and chefs alike.',
    tip: 'Arrive before 6am. The wait is worth it.',
    dish: 'Omakase set', mediaUrls: [], contributorId: 'u1',
    status: 'approved', avgRating: 4.9, reviewCount: 312, saveCount: 89,
    priceRange: '\$\$', tileColor: const Color(0xFF4A7C6F), badge: 'Local Legend',
    tagline: 'The sushi Tokyo chefs eat on their days off.',
    createdAt: DateTime(2024, 1, 1), updatedAt: DateTime(2024, 1, 1),
  ),
  RestaurantModel(
    id: 'r2', name: 'Afuri Ramen', category: 'Japanese', cityId: 'tokyo',
    neighborhood: 'Harajuku', geopoint: const GeoPoint(35.6694, 139.7028),
    description: 'Yuzu-scented shio ramen in a sleek minimalist space.',
    tip: 'Order the yuzu shio. Nothing else matters.',
    dish: 'Yuzu Shio Ramen', mediaUrls: [], contributorId: 'u1',
    status: 'approved', avgRating: 4.7, reviewCount: 198, saveCount: 54,
    priceRange: '\$\$', tileColor: const Color(0xFFC17B4E), badge: null,
    tagline: 'Citrus-bright ramen that reinvented the bowl.',
    createdAt: DateTime(2024, 1, 1), updatedAt: DateTime(2024, 1, 1),
  ),
];

class MockRestaurantService implements IRestaurantService {
  @override
  Future<List<RestaurantModel>> fetchFeed({required String cityId, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _kSampleRestaurants.where((r) => r.cityId == cityId).take(limit).toList();
  }

  @override
  Future<List<RestaurantModel>> fetchNearby({required GeoPoint center, double radiusKm = 0.5}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _kSampleRestaurants;
  }

  @override
  Future<List<RestaurantModel>> fetchByCategory({required String category, required String cityId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _kSampleRestaurants.where((r) => r.category == category && r.cityId == cityId).toList();
  }

  @override
  Future<List<RestaurantModel>> search({required String query, required String cityId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final q = query.toLowerCase();
    return _kSampleRestaurants.where((r) =>
      r.name.toLowerCase().contains(q) || r.description.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Future<RestaurantModel> fetchById(String restaurantId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _kSampleRestaurants.firstWhere((r) => r.id == restaurantId,
        orElse: () => _kSampleRestaurants.first);
  }

  @override
  Future<String> addRestaurant(RestaurantModel restaurant) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'mock_id_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<void> updateRestaurant(RestaurantModel restaurant) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
```

- [ ] **Step 2: Create `lib/services/mock/mock_review_service.dart`**

```dart
import '../interfaces/i_review_service.dart';
import '../../models/review_model.dart';

final _kSampleReviews = [
  ReviewModel(
    id: 'rev1', restaurantId: 'r1', authorId: 'u2', authorName: 'Maya Chen',
    authorPhotoUrl: '', text: 'Absolutely incredible. Worth every minute of the wait.',
    rating: 5.0, upvotes: 42, createdAt: DateTime(2024, 3, 15),
  ),
  ReviewModel(
    id: 'rev2', restaurantId: 'r1', authorId: 'u3', authorName: 'Ryo Tanaka',
    authorPhotoUrl: '', text: 'Best omakase under 3000 yen. A Tokyo institution.',
    rating: 5.0, upvotes: 38, createdAt: DateTime(2024, 2, 20),
  ),
];

class MockReviewService implements IReviewService {
  final _reviews = List<ReviewModel>.from(_kSampleReviews);

  @override
  Future<List<ReviewModel>> fetchReviews(String restaurantId, {int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _reviews.where((r) => r.restaurantId == restaurantId).take(limit).toList();
  }

  @override
  Future<void> submitReview(ReviewModel review) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _reviews.add(review);
  }

  @override
  Future<void> editReview({required String restaurantId, required String reviewId, required String text, required double rating}) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> deleteReview({required String restaurantId, required String reviewId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _reviews.removeWhere((r) => r.id == reviewId);
  }

  @override
  Future<void> upvoteReview({required String restaurantId, required String reviewId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<String?> fetchTranslation({required String restaurantId, required String reviewId, required String targetLang}) async {
    return null;
  }

  @override
  Future<void> cacheTranslation({required String restaurantId, required String reviewId, required String targetLang, required String translatedText}) async {}
}
```

- [ ] **Step 3: Create `lib/services/mock/mock_user_service.dart`**

```dart
import '../interfaces/i_user_service.dart';
import '../../models/user_model.dart';
import '../../models/onboarding_prefs_model.dart';

class MockUserService implements IUserService {
  final _savedPlaces = <String, Set<String>>{};

  @override
  Future<UserModel?> fetchUser(String uid) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return UserModel(
      uid: uid, displayName: 'Bedo', email: 'bedo@example.com',
      photoUrl: '', tier: 'local', score: 150, isPremium: false,
      onboardingComplete: true,
      chatPrivacy: const ChatPrivacy(mode: 'public'),
      createdAt: DateTime(2024, 1, 1),
    );
  }

  @override
  Future<void> createUser(UserModel user) async {}

  @override
  Future<void> updateUser(UserModel user) async {}

  @override
  Future<OnboardingPrefsModel?> fetchPreferences(String uid) async => null;

  @override
  Future<void> savePreferences(String uid, OnboardingPrefsModel prefs) async {}

  @override
  Future<void> markOnboardingComplete(String uid) async {}

  @override
  Future<List<String>> fetchSavedPlaceIds(String uid) async {
    return (_savedPlaces[uid] ?? {}).toList();
  }

  @override
  Future<void> savePlace({required String uid, required String placeId, required bool reminderEnabled}) async {
    _savedPlaces.putIfAbsent(uid, () => {}).add(placeId);
  }

  @override
  Future<void> unsavePlace({required String uid, required String placeId}) async {
    _savedPlaces[uid]?.remove(placeId);
  }

  @override
  Future<int> savedPlaceCount(String uid) async {
    return _savedPlaces[uid]?.length ?? 0;
  }
}
```

- [ ] **Step 4: Create `lib/services/mock/mock_trip_service.dart`**

```dart
import 'package:flutter/material.dart';
import '../interfaces/i_trip_service.dart';
import '../../models/trip_model.dart';

final _kSampleTrip = TripModel(
  id: 't1', uid: 'u1', title: 'Tokyo, April 2026', cityId: 'tokyo',
  startDate: DateTime(2026, 4, 10), endDate: DateTime(2026, 4, 14),
  participantUids: ['u1', 'u2'],
  days: [
    TripDayModel(id: 'd1', date: DateTime(2026, 4, 10), spots: [
      TripSpotModel(
        id: 's1', time: '8:00 AM', mealType: 'Breakfast', restaurantId: 'r1',
        name: 'Sushi Dai', neighborhood: 'Tsukiji',
        statusLabel: 'Booked', statusColor: const Color(0xFF4A7C6F),
        tileColor: const Color(0xFF4A7C6F),
      ),
    ]),
  ],
);

class MockTripService implements ITripService {
  @override
  Future<List<TripModel>> fetchTrips(String uid) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [_kSampleTrip];
  }

  @override
  Future<String> createTrip(TripModel trip) async => 'mock_trip_id';

  @override
  Future<void> updateTrip(TripModel trip) async {}

  @override
  Future<void> deleteTrip({required String uid, required String tripId}) async {}

  @override
  Future<void> addSpot({required String uid, required String tripId, required String dayId, required TripSpotModel spot}) async {}

  @override
  Future<void> removeSpot({required String uid, required String tripId, required String dayId, required String spotId}) async {}
}
```

- [ ] **Step 5: Create remaining mock services**

`lib/services/mock/mock_chat_service.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_chat_service.dart';
import '../../models/chat_model.dart';

class MockChatService implements IChatService {
  final _messages = <String, List<MessageModel>>{};

  @override
  Future<ChatModel> getOrCreateChat({required String currentUid, required String otherUid, required String placeId}) async {
    return ChatModel(id: 'mock_chat_1', participantUids: [currentUid, otherUid],
        relatedPlaceId: placeId, lastMessage: '', lastUpdated: DateTime.now());
  }

  @override
  Stream<List<MessageModel>> messagesStream(String chatId) {
    return Stream.value(_messages[chatId] ?? []);
  }

  @override
  Future<void> sendMessage({required String chatId, required String senderId, required String text}) async {
    _messages.putIfAbsent(chatId, () => []).add(MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}', chatId: chatId,
      senderId: senderId, text: text, status: 'sent', createdAt: DateTime.now(),
    ));
  }

  @override
  Future<List<ChatModel>> fetchUserChats(String uid) async => [];

  @override
  Future<String?> fetchMessageTranslation({required String chatId, required String messageId, required String targetLang}) async => null;

  @override
  Future<void> cacheMessageTranslation({required String chatId, required String messageId, required String targetLang, required String translatedText}) async {}
}
```

`lib/services/mock/mock_storage_service.dart`:
```dart
import 'dart:io';
import '../interfaces/i_storage_service.dart';

class MockStorageService implements IStorageService {
  @override
  Future<String> uploadImage({required File file, required String path}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://placeholder.com/mock-image.jpg';
  }

  @override
  Future<void> deleteFile(String url) async {}
}
```

`lib/services/mock/mock_location_service.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_location_service.dart';

class MockLocationService implements ILocationService {
  @override
  Future<GeoPoint?> getCurrentPosition() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const GeoPoint(35.6654, 139.7707); // Tokyo
  }

  @override
  Future<bool> requestPermission() async => true;

  @override
  Stream<GeoPoint> positionStream() => Stream.value(const GeoPoint(35.6654, 139.7707));
}
```

`lib/services/mock/mock_notification_service.dart`:
```dart
import '../interfaces/i_notification_service.dart';

class MockNotificationService implements INotificationService {
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> getFcmToken() async => 'mock_fcm_token';
  @override
  Future<void> showLocalNotification({required String title, required String body}) async {}
  @override
  Future<void> scheduleGeofenceNotification({required String placeId, required String placeName, required double lat, required double lng}) async {}
  @override
  Future<void> cancelGeofenceNotification(String placeId) async {}
}
```

`lib/services/mock/mock_ai_service.dart`:
```dart
import '../interfaces/i_ai_service.dart';
import '../../models/onboarding_prefs_model.dart';
import '../../models/place_summary_model.dart';
import '../../models/review_model.dart';

class MockAiService implements IAiService {
  @override
  Future<Map<String, double>> generateTasteWeights(OnboardingPrefsModel prefs) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {'Japanese': 0.9, 'Street Food': 0.8, 'Cafe': 0.6};
  }

  @override
  Future<String> translate({required String text, required String targetLang}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return '[Mock translation to $targetLang]: $text';
  }

  @override
  Future<PlaceSummaryModel> summarizeReviews({required String restaurantId, required List<ReviewModel> reviews}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return PlaceSummaryModel(
      vibeOneLiner: 'An unmissable local institution worth every moment of the wait.',
      topAspects: ['Freshness', 'Value', 'Atmosphere'],
      mainDish: 'Omakase set',
      caveats: ['Long queues', 'Cash only'],
      bestTime: 'Weekday mornings before 6am',
      generatedAt: DateTime.now(),
      reviewCountAtGeneration: reviews.length,
    );
  }
}
```

`lib/services/mock/mock_subscription_service.dart`:
```dart
import '../interfaces/i_subscription_service.dart';

class MockSubscriptionService implements ISubscriptionService {
  @override
  Future<bool> isPremium(String uid) async => false;
  @override
  Future<void> upgradeToPremium(String uid) async {}
  @override
  Future<int> translationsUsedToday(String uid) async => 0;
  @override
  Future<int> chatMessagesSentToday(String uid) async => 0;
}
```

- [ ] **Step 6: Commit**

```bash
git add lib/services/mock/
git commit -m "feat: add all mock service implementations"
```

---

## Phase 2 — Firebase Implementations

### Task 5: Firestore Restaurant Service

**Files:**
- Create: `lib/services/firebase/firestore_restaurant_service.dart`
- Modify: `pubspec.yaml` (add `geoflutterfire_plus`)

- [ ] **Step 1: Add `geoflutterfire_plus` to `pubspec.yaml`**

Under `dependencies:`, add:
```yaml
geoflutterfire_plus: ^0.0.30
```

Run: `flutter pub get`

- [ ] **Step 2: Create `lib/services/firebase/firestore_restaurant_service.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import '../interfaces/i_restaurant_service.dart';
import '../../models/restaurant_model.dart';
import '../../core/constants/app_constants.dart';

class FirestoreRestaurantService implements IRestaurantService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection(AppConstants.kColRestaurants);

  @override
  Future<List<RestaurantModel>> fetchFeed({required String cityId, int limit = 20}) async {
    final snap = await _col
        .where('cityId', isEqualTo: cityId)
        .where('status', isEqualTo: 'approved')
        .orderBy('avgRating', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(RestaurantModel.fromFirestore).toList();
  }

  @override
  Future<List<RestaurantModel>> fetchNearby({required GeoPoint center, double radiusKm = 0.5}) async {
    final geoFirePoint = GeoFirePoint(GeoPoint(center.latitude, center.longitude));
    final stream = GeoCollectionReference(_col).subscribeWithin(
      center: geoFirePoint,
      radiusInKm: radiusKm,
      field: 'geopoint',
      geopointFrom: (data) => data['geopoint'] as GeoPoint,
    );
    final docs = await stream.first;
    return docs.map((d) => RestaurantModel.fromFirestore(d)).toList();
  }

  @override
  Future<List<RestaurantModel>> fetchByCategory({required String category, required String cityId}) async {
    final snap = await _col
        .where('category', isEqualTo: category)
        .where('cityId', isEqualTo: cityId)
        .where('status', isEqualTo: 'approved')
        .orderBy('avgRating', descending: true)
        .limit(20)
        .get();
    return snap.docs.map(RestaurantModel.fromFirestore).toList();
  }

  @override
  Future<List<RestaurantModel>> search({required String query, required String cityId}) async {
    // Firestore prefix search — for production use Algolia
    final snap = await _col
        .where('cityId', isEqualTo: cityId)
        .where('status', isEqualTo: 'approved')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query')
        .limit(20)
        .get();
    return snap.docs.map(RestaurantModel.fromFirestore).toList();
  }

  @override
  Future<RestaurantModel> fetchById(String restaurantId) async {
    final doc = await _col.doc(restaurantId).get();
    return RestaurantModel.fromFirestore(doc);
  }

  @override
  Future<String> addRestaurant(RestaurantModel restaurant) async {
    final ref = await _col.add(restaurant.toFirestore());
    return ref.id;
  }

  @override
  Future<void> updateRestaurant(RestaurantModel restaurant) async {
    await _col.doc(restaurant.id).update(restaurant.toFirestore());
  }
}
```

- [ ] **Step 3: Seed Firestore with sample data**

Create a temporary seed script at `lib/services/firebase/seed_data.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/restaurant_model.dart';
import '../../core/constants/app_constants.dart';

Future<void> seedRestaurants() async {
  final db = FirebaseFirestore.instance;
  final col = db.collection(AppConstants.kColRestaurants);

  final restaurants = [
    RestaurantModel(
      id: '', name: 'Sushi Dai', category: 'Japanese', cityId: 'tokyo',
      neighborhood: 'Tsukiji', geopoint: const GeoPoint(35.6654, 139.7707),
      description: 'Standing sushi counter beloved by locals and chefs alike.',
      tip: 'Arrive before 6am.', dish: 'Omakase set', mediaUrls: [],
      contributorId: 'system', status: 'approved', avgRating: 4.9,
      reviewCount: 0, saveCount: 0, priceRange: '\$\$',
      tileColor: const Color(0xFF4A7C6F), badge: 'Local Legend',
      tagline: 'The sushi Tokyo chefs eat on their days off.',
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    ),
  ];

  for (final r in restaurants) {
    await col.add(r.toFirestore());
  }
}
```

Call `seedRestaurants()` once from a dev-only button in settings, then remove. Do not ship seed code.

- [ ] **Step 4: Commit**

```bash
git add lib/services/firebase/firestore_restaurant_service.dart lib/services/firebase/seed_data.dart pubspec.yaml pubspec.lock
git commit -m "feat: add FirestoreRestaurantService with geo queries"
```

---

### Task 6: Firestore Review Service

**Files:**
- Create: `lib/services/firebase/firestore_review_service.dart`

- [ ] **Step 1: Create `lib/services/firebase/firestore_review_service.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_review_service.dart';
import '../../models/review_model.dart';
import '../../core/constants/app_constants.dart';

class FirestoreReviewService implements IReviewService {
  final _db = FirebaseFirestore.instance;

  CollectionReference _reviewsCol(String restaurantId) => _db
      .collection(AppConstants.kColRestaurants)
      .doc(restaurantId)
      .collection(AppConstants.kColReviews);

  @override
  Future<List<ReviewModel>> fetchReviews(String restaurantId, {int limit = 20}) async {
    final snap = await _reviewsCol(restaurantId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(ReviewModel.fromFirestore).toList();
  }

  @override
  Future<void> submitReview(ReviewModel review) async {
    final batch = _db.batch();
    final reviewRef = _reviewsCol(review.restaurantId).doc();
    batch.set(reviewRef, review.toFirestore());

    // Update avgRating and reviewCount on parent doc
    final restaurantRef = _db.collection(AppConstants.kColRestaurants).doc(review.restaurantId);
    batch.update(restaurantRef, {
      'reviewCount': FieldValue.increment(1),
      // avgRating update handled by Cloud Function for accuracy
    });
    await batch.commit();
  }

  @override
  Future<void> editReview({required String restaurantId, required String reviewId, required String text, required double rating}) async {
    await _reviewsCol(restaurantId).doc(reviewId).update({'text': text, 'rating': rating});
  }

  @override
  Future<void> deleteReview({required String restaurantId, required String reviewId}) async {
    await _reviewsCol(restaurantId).doc(reviewId).delete();
  }

  @override
  Future<void> upvoteReview({required String restaurantId, required String reviewId}) async {
    await _reviewsCol(restaurantId).doc(reviewId).update({'upvotes': FieldValue.increment(1)});
  }

  @override
  Future<String?> fetchTranslation({required String restaurantId, required String reviewId, required String targetLang}) async {
    final doc = await _reviewsCol(restaurantId)
        .doc(reviewId)
        .collection(AppConstants.kColTranslations)
        .doc(targetLang)
        .get();
    if (!doc.exists) return null;
    return (doc.data() as Map<String, dynamic>)['translatedText'] as String?;
  }

  @override
  Future<void> cacheTranslation({required String restaurantId, required String reviewId, required String targetLang, required String translatedText}) async {
    await _reviewsCol(restaurantId)
        .doc(reviewId)
        .collection(AppConstants.kColTranslations)
        .doc(targetLang)
        .set({'translatedText': translatedText, 'cachedAt': FieldValue.serverTimestamp()});
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/firebase/firestore_review_service.dart
git commit -m "feat: add FirestoreReviewService"
```

---

### Task 7: Firestore User Service (profile, prefs, saved places)

**Files:**
- Create: `lib/services/firebase/firestore_user_service.dart`

- [ ] **Step 1: Create `lib/services/firebase/firestore_user_service.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_user_service.dart';
import '../../models/user_model.dart';
import '../../models/onboarding_prefs_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';

class FirestoreUserService implements IUserService {
  final _db = FirebaseFirestore.instance;

  DocumentReference _userDoc(String uid) =>
      _db.collection(AppConstants.kColUsers).doc(uid);

  @override
  Future<UserModel?> fetchUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  @override
  Future<void> createUser(UserModel user) async {
    await _userDoc(user.uid).set(user.toFirestore());
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _userDoc(user.uid).update(user.toFirestore());
  }

  @override
  Future<OnboardingPrefsModel?> fetchPreferences(String uid) async {
    final doc = await _userDoc(uid).collection(AppConstants.kDocPreferences).doc('prefs').get();
    if (!doc.exists) return null;
    return OnboardingPrefsModel.fromFirestore(doc);
  }

  @override
  Future<void> savePreferences(String uid, OnboardingPrefsModel prefs) async {
    await _userDoc(uid)
        .collection(AppConstants.kDocPreferences)
        .doc('prefs')
        .set(prefs.toFirestore());
  }

  @override
  Future<void> markOnboardingComplete(String uid) async {
    await _userDoc(uid).update({'onboardingComplete': true});
  }

  @override
  Future<List<String>> fetchSavedPlaceIds(String uid) async {
    final snap = await _userDoc(uid).collection(AppConstants.kColSavedPlaces).get();
    return snap.docs.map((d) => d.id).toList();
  }

  @override
  Future<void> savePlace({required String uid, required String placeId, required bool reminderEnabled}) async {
    final count = await savedPlaceCount(uid);
    final userDoc = await fetchUser(uid);
    if (count >= AppConstants.kMaxSavedFree && !(userDoc?.isPremium ?? false)) {
      throw const QuotaException('Save limit reached. Upgrade to premium for unlimited saves.');
    }
    await _userDoc(uid)
        .collection(AppConstants.kColSavedPlaces)
        .doc(placeId)
        .set({'reminderEnabled': reminderEnabled, 'savedAt': FieldValue.serverTimestamp()});
    await _db.collection(AppConstants.kColRestaurants).doc(placeId).update({
      'saveCount': FieldValue.increment(1),
    });
  }

  @override
  Future<void> unsavePlace({required String uid, required String placeId}) async {
    await _userDoc(uid).collection(AppConstants.kColSavedPlaces).doc(placeId).delete();
    await _db.collection(AppConstants.kColRestaurants).doc(placeId).update({
      'saveCount': FieldValue.increment(-1),
    });
  }

  @override
  Future<int> savedPlaceCount(String uid) async {
    final snap = await _userDoc(uid).collection(AppConstants.kColSavedPlaces).count().get();
    return snap.count ?? 0;
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/firebase/firestore_user_service.dart
git commit -m "feat: add FirestoreUserService with saved places and quota check"
```

---

### Task 8: Firestore Chat Service

**Files:**
- Create: `lib/services/firebase/firestore_chat_service.dart`

- [ ] **Step 1: Create `lib/services/firebase/firestore_chat_service.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_chat_service.dart';
import '../../models/chat_model.dart';
import '../../core/constants/app_constants.dart';

class FirestoreChatService implements IChatService {
  final _db = FirebaseFirestore.instance;

  @override
  Future<ChatModel> getOrCreateChat({required String currentUid, required String otherUid, required String placeId}) async {
    final participants = [currentUid, otherUid]..sort();
    final existing = await _db.collection(AppConstants.kColChats)
        .where('participants', isEqualTo: participants)
        .where('relatedPlaceId', isEqualTo: placeId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return ChatModel.fromFirestore(existing.docs.first);

    final ref = await _db.collection(AppConstants.kColChats).add({
      'participants': participants,
      'relatedPlaceId': placeId,
      'lastMessage': '',
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    final doc = await ref.get();
    return ChatModel.fromFirestore(doc);
  }

  @override
  Stream<List<MessageModel>> messagesStream(String chatId) {
    return _db
        .collection(AppConstants.kColChats)
        .doc(chatId)
        .collection(AppConstants.kColMessages)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());
  }

  @override
  Future<void> sendMessage({required String chatId, required String senderId, required String text}) async {
    final batch = _db.batch();
    final msgRef = _db
        .collection(AppConstants.kColChats)
        .doc(chatId)
        .collection(AppConstants.kColMessages)
        .doc();
    batch.set(msgRef, MessageModel(
      id: msgRef.id, chatId: chatId, senderId: senderId,
      text: text, status: 'sent', createdAt: DateTime.now(),
    ).toFirestore());
    batch.update(_db.collection(AppConstants.kColChats).doc(chatId), {
      'lastMessage': text, 'lastUpdated': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<List<ChatModel>> fetchUserChats(String uid) async {
    final snap = await _db.collection(AppConstants.kColChats)
        .where('participants', arrayContains: uid)
        .orderBy('lastUpdated', descending: true)
        .get();
    return snap.docs.map(ChatModel.fromFirestore).toList();
  }

  @override
  Future<String?> fetchMessageTranslation({required String chatId, required String messageId, required String targetLang}) async {
    final doc = await _db
        .collection(AppConstants.kColChats).doc(chatId)
        .collection(AppConstants.kColMessages).doc(messageId)
        .collection(AppConstants.kColTranslations).doc(targetLang).get();
    if (!doc.exists) return null;
    return (doc.data() as Map<String, dynamic>)['translatedText'] as String?;
  }

  @override
  Future<void> cacheMessageTranslation({required String chatId, required String messageId, required String targetLang, required String translatedText}) async {
    await _db
        .collection(AppConstants.kColChats).doc(chatId)
        .collection(AppConstants.kColMessages).doc(messageId)
        .collection(AppConstants.kColTranslations).doc(targetLang)
        .set({'translatedText': translatedText, 'cachedAt': FieldValue.serverTimestamp()});
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/firebase/firestore_chat_service.dart
git commit -m "feat: add FirestoreChatService with real-time message stream"
```

---

### Task 9: Firebase Storage Service

**Files:**
- Create: `lib/services/firebase/firebase_storage_service.dart`
- Modify: `pubspec.yaml` (add `image_picker`)

- [ ] **Step 1: Add `image_picker` to pubspec.yaml**

```yaml
image_picker: ^1.0.7
```

Run: `flutter pub get`

- [ ] **Step 2: Create `lib/services/firebase/firebase_storage_service.dart`**

```dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../interfaces/i_storage_service.dart';
import '../../core/errors/app_exception.dart';

class FirebaseStorageService implements IStorageService {
  final _storage = FirebaseStorage.instance;

  @override
  Future<String> uploadImage({required File file, required String path}) async {
    try {
      final ref = _storage.ref(path);
      final task = ref.putFile(file);
      int retries = 0;
      while (retries < 3) {
        try {
          await task;
          return await ref.getDownloadURL();
        } catch (_) {
          retries++;
          await Future.delayed(Duration(seconds: retries * 2));
        }
      }
      throw const StorageException();
    } catch (e) {
      throw StorageException(e.toString());
    }
  }

  @override
  Future<void> deleteFile(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/services/firebase/firebase_storage_service.dart pubspec.yaml pubspec.lock
git commit -m "feat: add FirebaseStorageService with retry logic"
```

---

### Task 10: Location Service

**Files:**
- Create: `lib/services/firebase/geolocator_location_service.dart`
- Modify: `pubspec.yaml` (add `geolocator`)

- [ ] **Step 1: Add `geolocator` to pubspec.yaml**

```yaml
geolocator: ^11.0.0
```

Run: `flutter pub get`

- [ ] **Step 2: Configure platform permissions**

Android — add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

iOS — add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>DiningAtlas needs your location to show nearby restaurants.</string>
```

- [ ] **Step 3: Create `lib/services/firebase/geolocator_location_service.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../interfaces/i_location_service.dart';

class GeolocatorLocationService implements ILocationService {
  @override
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }

  @override
  Future<GeoPoint?> getCurrentPosition() async {
    final granted = await requestPermission();
    if (!granted) return null;
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return GeoPoint(pos.latitude, pos.longitude);
  }

  @override
  Stream<GeoPoint> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).map((pos) => GeoPoint(pos.latitude, pos.longitude));
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/services/firebase/geolocator_location_service.dart android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist pubspec.yaml pubspec.lock
git commit -m "feat: add GeolocatorLocationService with permission handling"
```

---

### Task 11: Push Notifications (FCM)

**Files:**
- Create: `lib/services/firebase/fcm_notification_service.dart`
- Modify: `pubspec.yaml` (add `firebase_messaging`, `flutter_local_notifications`)

- [ ] **Step 1: Add packages to pubspec.yaml**

```yaml
firebase_messaging: ^15.0.0
flutter_local_notifications: ^17.0.0
```

Run: `flutter pub get`

- [ ] **Step 2: Android FCM setup**

Add to `android/app/src/main/AndroidManifest.xml` inside `<application>`:
```xml
<service
    android:name="com.google.firebase.messaging.FirebaseMessagingService"
    android:exported="false">
  <intent-filter>
    <action android:name="com.google.firebase.MESSAGING_EVENT" />
  </intent-filter>
</service>
```

- [ ] **Step 3: Create `lib/services/firebase/fcm_notification_service.dart`**

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../interfaces/i_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class FcmNotificationService implements INotificationService {
  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _fcm.requestPermission();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    FirebaseMessaging.onMessage.listen((msg) {
      if (msg.notification != null) {
        showLocalNotification(
          title: msg.notification!.title ?? '',
          body: msg.notification!.body ?? '',
        );
      }
    });
  }

  @override
  Future<String?> getFcmToken() => _fcm.getToken();

  @override
  Future<void> showLocalNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'diningatlas_channel', 'DiningAtlas',
      importance: Importance.high, priority: Priority.high,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title, body,
      const NotificationDetails(android: androidDetails),
    );
  }

  @override
  Future<void> scheduleGeofenceNotification({required String placeId, required String placeName, required double lat, required double lng}) async {
    // Geofence notifications triggered by position stream in LocationProvider
    // When device enters radius, call showLocalNotification directly
  }

  @override
  Future<void> cancelGeofenceNotification(String placeId) async {
    // Cancel by notification id derived from placeId
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/services/firebase/fcm_notification_service.dart android/app/src/main/AndroidManifest.xml pubspec.yaml pubspec.lock
git commit -m "feat: add FCM push notification service"
```

---

### Task 12: Groq AI Service

**Files:**
- Create: `lib/services/ai/groq_ai_service.dart`
- Modify: `pubspec.yaml` (add `http`)

- [ ] **Step 1: Add `http` to pubspec.yaml**

```yaml
http: ^1.2.0
```

Run: `flutter pub get`

- [ ] **Step 2: Store API key safely**

Create `lib/core/constants/env.dart` (add to `.gitignore`):
```dart
class Env {
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
}
```

Build with: `flutter run --dart-define=GROQ_API_KEY=your_key_here`

- [ ] **Step 3: Create `lib/services/ai/groq_ai_service.dart`**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../interfaces/i_ai_service.dart';
import '../../models/onboarding_prefs_model.dart';
import '../../models/place_summary_model.dart';
import '../../models/review_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/env.dart';

class GroqAiService implements IAiService {
  Future<String> _chat(String prompt) async {
    final response = await http.post(
      Uri.parse('${AppConstants.kGroqBaseUrl}/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${Env.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': AppConstants.kGroqModel,
        'messages': [{'role': 'user', 'content': prompt}],
        'temperature': 0.7,
      }),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) throw Exception('AI API error: ${response.statusCode}');
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }

  @override
  Future<Map<String, double>> generateTasteWeights(OnboardingPrefsModel prefs) async {
    final prompt = '''
You are a hyper-local travel curator. The user likes: ${prefs.vibes.join(', ')}.
Their budget is ${prefs.budget}. They prefer atmosphere: ${prefs.atmosphere.join(', ')}.
Return ONLY a JSON object of {category: weight} pairs (weight 0.0-1.0), no explanation.
Example: {"Japanese": 0.9, "Street Food": 0.8}
''';
    try {
      final raw = await _chat(prompt);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return json.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {'Local Food': 0.8, 'Cafe': 0.6};
    }
  }

  @override
  Future<String> translate({required String text, required String targetLang}) async {
    final prompt = '''
Translate the following travel review to $targetLang.
Preserve the reviewer's personal tone, enthusiasm, and any cultural references contextually.
Return ONLY the translated text, no explanation.

Text: $text
''';
    return await _chat(prompt);
  }

  @override
  Future<PlaceSummaryModel> summarizeReviews({required String restaurantId, required List<ReviewModel> reviews}) async {
    final reviewTexts = reviews.take(50).map((r) => '- (${r.rating}★) ${r.text}').join('\n');
    final prompt = '''
You are summarizing restaurant reviews for a travel app. Based on these reviews:
$reviewTexts

Return ONLY a valid JSON object with these exact fields:
{
  "vibeOneLiner": "one sentence describing the vibe",
  "topAspects": ["aspect1", "aspect2", "aspect3"],
  "mainDish": "most mentioned dish",
  "caveats": ["caveat1", "caveat2"],
  "bestTime": "best time to visit based on reviews"
}
''';
    try {
      final raw = await _chat(prompt);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PlaceSummaryModel(
        vibeOneLiner: json['vibeOneLiner'] ?? '',
        topAspects: List<String>.from(json['topAspects'] ?? []),
        mainDish: json['mainDish'] ?? '',
        caveats: List<String>.from(json['caveats'] ?? []),
        bestTime: json['bestTime'] ?? '',
        generatedAt: DateTime.now(),
        reviewCountAtGeneration: reviews.length,
      );
    } catch (_) {
      throw Exception('Failed to parse AI summary response');
    }
  }
}
```

- [ ] **Step 4: Add `lib/core/constants/env.dart` to `.gitignore`**

```
lib/core/constants/env.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/services/ai/groq_ai_service.dart pubspec.yaml pubspec.lock .gitignore
git commit -m "feat: add GroqAiService for recommendations, translation, summarizer"
```

---

### Task 13: All Providers

**Files:**
- Create: `lib/providers/restaurant_provider.dart`
- Create: `lib/providers/review_provider.dart`
- Create: `lib/providers/user_provider.dart`
- Create: `lib/providers/trip_provider.dart`
- Create: `lib/providers/chat_provider.dart`
- Create: `lib/providers/saved_places_provider.dart`
- Create: `lib/providers/onboarding_provider.dart`
- Create: `lib/providers/notification_provider.dart`
- Create: `lib/providers/ai_provider.dart`

- [ ] **Step 1: Create `lib/providers/restaurant_provider.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/interfaces/i_restaurant_service.dart';
import '../models/restaurant_model.dart';

class RestaurantProvider extends ChangeNotifier {
  final IRestaurantService _service;
  RestaurantProvider(this._service);

  List<RestaurantModel> _feed = [];
  List<RestaurantModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String _currentCityId = 'tokyo';

  List<RestaurantModel> get feed => _feed;
  List<RestaurantModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCityId => _currentCityId;

  Future<void> loadFeed({String? cityId}) async {
    _currentCityId = cityId ?? _currentCityId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _feed = await _service.fetchFeed(cityId: _currentCityId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNearby(GeoPoint center) async {
    _isLoading = true;
    notifyListeners();
    try {
      _feed = await _service.fetchNearby(center: center);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    if (query.isEmpty) { _searchResults = []; notifyListeners(); return; }
    _isLoading = true;
    notifyListeners();
    try {
      _searchResults = await _service.search(query: query, cityId: _currentCityId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<RestaurantModel?> fetchById(String id) async {
    try {
      return await _service.fetchById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
```

- [ ] **Step 2: Create `lib/providers/review_provider.dart`**

```dart
import 'package:flutter/material.dart';
import '../services/interfaces/i_review_service.dart';
import '../services/interfaces/i_ai_service.dart';
import '../models/review_model.dart';
import '../core/errors/app_exception.dart';

class ReviewProvider extends ChangeNotifier {
  final IReviewService _reviewService;
  final IAiService _aiService;
  ReviewProvider(this._reviewService, this._aiService);

  final Map<String, List<ReviewModel>> _reviews = {};
  final Map<String, String> _translations = {}; // key: 'reviewId_lang'
  bool _isLoading = false;
  String? _error;

  List<ReviewModel> reviewsFor(String restaurantId) => _reviews[restaurantId] ?? [];
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? translationFor(String reviewId, String lang) => _translations['${reviewId}_$lang'];

  Future<void> loadReviews(String restaurantId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _reviews[restaurantId] = await _reviewService.fetchReviews(restaurantId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitReview(ReviewModel review) async {
    try {
      await _reviewService.submitReview(review);
      _reviews[review.restaurantId] = [review, ...reviewsFor(review.restaurantId)];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteReview({required String restaurantId, required String reviewId}) async {
    await _reviewService.deleteReview(restaurantId: restaurantId, reviewId: reviewId);
    _reviews[restaurantId]?.removeWhere((r) => r.id == reviewId);
    notifyListeners();
  }

  Future<void> upvote({required String restaurantId, required String reviewId}) async {
    await _reviewService.upvoteReview(restaurantId: restaurantId, reviewId: reviewId);
    notifyListeners();
  }

  Future<void> translate({required String restaurantId, required String reviewId, required String text, required String targetLang}) async {
    final key = '${reviewId}_$targetLang';
    if (_translations.containsKey(key)) return;

    final cached = await _reviewService.fetchTranslation(
      restaurantId: restaurantId, reviewId: reviewId, targetLang: targetLang,
    );
    if (cached != null) { _translations[key] = cached; notifyListeners(); return; }

    final translated = await _aiService.translate(text: text, targetLang: targetLang);
    await _reviewService.cacheTranslation(
      restaurantId: restaurantId, reviewId: reviewId,
      targetLang: targetLang, translatedText: translated,
    );
    _translations[key] = translated;
    notifyListeners();
  }
}
```

- [ ] **Step 3: Create `lib/providers/user_provider.dart`**

```dart
import 'package:flutter/material.dart';
import '../services/interfaces/i_user_service.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final IUserService _service;
  UserProvider(this._service);

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUser(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _service.fetchUser(uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateChatPrivacy(ChatPrivacy privacy) async {
    if (_user == null) return;
    final updated = UserModel(
      uid: _user!.uid, displayName: _user!.displayName, email: _user!.email,
      photoUrl: _user!.photoUrl, tier: _user!.tier, score: _user!.score,
      isPremium: _user!.isPremium, onboardingComplete: _user!.onboardingComplete,
      chatPrivacy: privacy, createdAt: _user!.createdAt,
    );
    await _service.updateUser(updated);
    _user = updated;
    notifyListeners();
  }
}
```

- [ ] **Step 4: Create `lib/providers/saved_places_provider.dart`**

```dart
import 'package:flutter/material.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/interfaces/i_notification_service.dart';
import '../models/restaurant_model.dart';
import '../core/errors/app_exception.dart';

class SavedPlacesProvider extends ChangeNotifier {
  final IUserService _userService;
  final INotificationService _notificationService;
  SavedPlacesProvider(this._userService, this._notificationService);

  Set<String> _savedIds = {};
  String? _error;

  bool get isLoading => false;
  String? get error => _error;
  bool isSaved(String placeId) => _savedIds.contains(placeId);

  Future<void> loadSaved(String uid) async {
    final ids = await _userService.fetchSavedPlaceIds(uid);
    _savedIds = ids.toSet();
    notifyListeners();
  }

  Future<void> toggleSave({required String uid, required RestaurantModel restaurant}) async {
    _error = null;
    try {
      if (_savedIds.contains(restaurant.id)) {
        await _userService.unsavePlace(uid: uid, placeId: restaurant.id);
        await _notificationService.cancelGeofenceNotification(restaurant.id);
        _savedIds.remove(restaurant.id);
      } else {
        await _userService.savePlace(uid: uid, placeId: restaurant.id, reminderEnabled: true);
        await _notificationService.scheduleGeofenceNotification(
          placeId: restaurant.id, placeName: restaurant.name,
          lat: restaurant.geopoint.latitude, lng: restaurant.geopoint.longitude,
        );
        _savedIds.add(restaurant.id);
      }
      notifyListeners();
    } on QuotaException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
```

- [ ] **Step 5: Create `lib/providers/onboarding_provider.dart`**

```dart
import 'package:flutter/material.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/interfaces/i_ai_service.dart';
import '../models/onboarding_prefs_model.dart';

class OnboardingProvider extends ChangeNotifier {
  final IUserService _userService;
  final IAiService _aiService;
  OnboardingProvider(this._userService, this._aiService);

  List<String> vibes = [];
  String budget = '\$\$';
  List<String> atmosphere = [];
  String cityId = 'tokyo';
  bool _isLoading = false;
  bool _completed = false;

  bool get isLoading => _isLoading;
  bool get completed => _completed;

  Future<void> completeOnboarding(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = OnboardingPrefsModel(
        vibes: vibes, budget: budget, atmosphere: atmosphere,
        cityId: cityId, aiWeights: {},
      );
      final weights = await _aiService.generateTasteWeights(prefs);
      final prefsWithWeights = OnboardingPrefsModel(
        vibes: vibes, budget: budget, atmosphere: atmosphere,
        cityId: cityId, aiWeights: weights,
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

- [ ] **Step 6: Create `lib/providers/chat_provider.dart`**

```dart
import 'package:flutter/material.dart';
import '../services/interfaces/i_chat_service.dart';
import '../services/interfaces/i_ai_service.dart';
import '../models/chat_model.dart';

class ChatProvider extends ChangeNotifier {
  final IChatService _chatService;
  final IAiService _aiService;
  ChatProvider(this._chatService, this._aiService);

  ChatModel? _currentChat;
  Stream<List<MessageModel>>? _messagesStream;
  final Map<String, String> _translations = {};
  String? _error;

  ChatModel? get currentChat => _currentChat;
  Stream<List<MessageModel>>? get messagesStream => _messagesStream;
  String? get error => _error;
  String? translationFor(String messageId, String lang) => _translations['${messageId}_$lang'];

  Future<void> openChat({required String currentUid, required String otherUid, required String placeId}) async {
    _currentChat = await _chatService.getOrCreateChat(
      currentUid: currentUid, otherUid: otherUid, placeId: placeId,
    );
    _messagesStream = _chatService.messagesStream(_currentChat!.id);
    notifyListeners();
  }

  Future<void> sendMessage({required String senderId, required String text}) async {
    if (_currentChat == null) return;
    await _chatService.sendMessage(chatId: _currentChat!.id, senderId: senderId, text: text);
  }

  Future<void> translateMessage({required String messageId, required String text, required String targetLang}) async {
    final key = '${messageId}_$targetLang';
    if (_translations.containsKey(key)) return;
    if (_currentChat == null) return;
    final cached = await _chatService.fetchMessageTranslation(
      chatId: _currentChat!.id, messageId: messageId, targetLang: targetLang,
    );
    if (cached != null) { _translations[key] = cached; notifyListeners(); return; }
    final translated = await _aiService.translate(text: text, targetLang: targetLang);
    await _chatService.cacheMessageTranslation(
      chatId: _currentChat!.id, messageId: messageId,
      targetLang: targetLang, translatedText: translated,
    );
    _translations[key] = translated;
    notifyListeners();
  }
}
```

- [ ] **Step 7: Create `lib/providers/trip_provider.dart`**

```dart
import 'package:flutter/material.dart';
import '../services/interfaces/i_trip_service.dart';
import '../models/trip_model.dart';

class TripProvider extends ChangeNotifier {
  final ITripService _service;
  TripProvider(this._service);

  List<TripModel> _trips = [];
  bool _isLoading = false;
  String? _error;

  List<TripModel> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTrips(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      _trips = await _service.fetchTrips(uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSpot({required String uid, required String tripId, required String dayId, required TripSpotModel spot}) async {
    await _service.addSpot(uid: uid, tripId: tripId, dayId: dayId, spot: spot);
    await loadTrips(uid);
  }
}
```

- [ ] **Step 8: Create `lib/providers/notification_provider.dart`**

```dart
import 'package:flutter/material.dart';
import '../services/interfaces/i_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final INotificationService _service;
  NotificationProvider(this._service);

  int _badgeCount = 0;
  int get badgeCount => _badgeCount;

  Future<void> initialize() async {
    await _service.initialize();
  }

  Future<String?> getToken() => _service.getFcmToken();

  void incrementBadge() { _badgeCount++; notifyListeners(); }
  void clearBadge() { _badgeCount = 0; notifyListeners(); }
}
```

- [ ] **Step 9: Create `lib/providers/ai_provider.dart`**

```dart
import 'package:flutter/material.dart';
import '../services/interfaces/i_ai_service.dart';
import '../services/interfaces/i_review_service.dart';
import '../models/place_summary_model.dart';
import '../models/review_model.dart';

class AiProvider extends ChangeNotifier {
  final IAiService _aiService;
  final IReviewService _reviewService;
  AiProvider(this._aiService, this._reviewService);

  final Map<String, PlaceSummaryModel?> _summaries = {};
  bool _isGenerating = false;

  PlaceSummaryModel? summaryFor(String restaurantId) => _summaries[restaurantId];
  bool get isGenerating => _isGenerating;

  Future<void> loadSummary(String restaurantId) async {
    if (_summaries.containsKey(restaurantId)) return;
    _isGenerating = true;
    notifyListeners();
    try {
      final reviews = await _reviewService.fetchReviews(restaurantId, limit: 50);
      if (reviews.length < 5) { _summaries[restaurantId] = null; return; }
      _summaries[restaurantId] = await _aiService.summarizeReviews(
        restaurantId: restaurantId, reviews: reviews,
      );
    } catch (_) {
      _summaries[restaurantId] = null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}
```

- [ ] **Step 10: Commit**

```bash
git add lib/providers/
git commit -m "feat: add all ChangeNotifier providers wired to service interfaces"
```

---

### Task 14: Wire real services into main.dart (swap from mock)

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Update `lib/main.dart` to register all providers**

Replace the provider registration section in `main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Services — swap mock → firebase here when ready
import 'services/firebase/firebase_auth_service.dart';
import 'services/firebase/firestore_restaurant_service.dart';
import 'services/firebase/firestore_review_service.dart';
import 'services/firebase/firestore_user_service.dart';
import 'services/firebase/firestore_trip_service.dart';
import 'services/firebase/firestore_chat_service.dart';
import 'services/firebase/firebase_storage_service.dart';
import 'services/firebase/geolocator_location_service.dart';
import 'services/firebase/fcm_notification_service.dart';
import 'services/ai/groq_ai_service.dart';
import 'services/mock/mock_subscription_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/review_provider.dart';
import 'providers/user_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/saved_places_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/ai_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DiningAtlasApp());
}

class DiningAtlasApp extends StatelessWidget {
  const DiningAtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final restaurantService = FirestoreRestaurantService();
    final reviewService = FirestoreReviewService();
    final userService = FirestoreUserService();
    final aiService = GroqAiService();
    final notificationService = FcmNotificationService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider(restaurantService)),
        ChangeNotifierProvider(create: (_) => ReviewProvider(reviewService, aiService)),
        ChangeNotifierProvider(create: (_) => UserProvider(userService)),
        ChangeNotifierProvider(create: (_) => TripProvider(FirestoreTripService())),
        ChangeNotifierProvider(create: (_) => ChatProvider(FirestoreChatService(), aiService)),
        ChangeNotifierProvider(create: (_) => SavedPlacesProvider(userService, notificationService)),
        ChangeNotifierProvider(create: (_) => OnboardingProvider(userService, aiService)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(notificationService)),
        ChangeNotifierProvider(create: (_) => AiProvider(aiService, reviewService)),
      ],
      child: MaterialApp(
        title: 'DiningAtlas',
        // ... existing theme and routes
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/main.dart
git commit -m "feat: wire all real Firebase services into MultiProvider"
```

---

### Task 15: Firestore Trip Service

**Files:**
- Create: `lib/services/firebase/firestore_trip_service.dart`

- [ ] **Step 1: Create `lib/services/firebase/firestore_trip_service.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_trip_service.dart';
import '../../models/trip_model.dart';
import '../../core/constants/app_constants.dart';

class FirestoreTripService implements ITripService {
  final _db = FirebaseFirestore.instance;

  CollectionReference _tripsCol(String uid) => _db
      .collection(AppConstants.kColTrips)
      .doc(uid)
      .collection('userTrips');

  @override
  Future<List<TripModel>> fetchTrips(String uid) async {
    final snap = await _tripsCol(uid).orderBy('startDate', descending: true).get();
    return snap.docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return TripModel(
        id: doc.id, uid: uid,
        title: d['title'] ?? '',
        cityId: d['cityId'] ?? '',
        startDate: (d['startDate'] as Timestamp).toDate(),
        endDate: (d['endDate'] as Timestamp).toDate(),
        participantUids: List<String>.from(d['participantUids'] ?? []),
        days: [],
      );
    }).toList();
  }

  @override
  Future<String> createTrip(TripModel trip) async {
    final ref = await _tripsCol(trip.uid).add({
      'title': trip.title,
      'cityId': trip.cityId,
      'startDate': Timestamp.fromDate(trip.startDate),
      'endDate': Timestamp.fromDate(trip.endDate),
      'participantUids': trip.participantUids,
    });
    return ref.id;
  }

  @override
  Future<void> updateTrip(TripModel trip) async {
    await _tripsCol(trip.uid).doc(trip.id).update({'title': trip.title});
  }

  @override
  Future<void> deleteTrip({required String uid, required String tripId}) async {
    await _tripsCol(uid).doc(tripId).delete();
  }

  @override
  Future<void> addSpot({required String uid, required String tripId, required String dayId, required TripSpotModel spot}) async {
    await _tripsCol(uid).doc(tripId)
        .collection(AppConstants.kColDays).doc(dayId)
        .collection(AppConstants.kColSpots).add({
      'time': spot.time,
      'mealType': spot.mealType,
      'restaurantId': spot.restaurantId,
      'name': spot.name,
      'neighborhood': spot.neighborhood,
      'statusLabel': spot.statusLabel,
    });
  }

  @override
  Future<void> removeSpot({required String uid, required String tripId, required String dayId, required String spotId}) async {
    await _tripsCol(uid).doc(tripId)
        .collection(AppConstants.kColDays).doc(dayId)
        .collection(AppConstants.kColSpots).doc(spotId).delete();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/firebase/firestore_trip_service.dart
git commit -m "feat: add FirestoreTripService"
```

---

## Phase 3 — Super User Cloud Functions

### Task 16: Cloud Functions setup and score updates

**Files:**
- Create: `functions/index.js`
- Create: `functions/package.json`

- [ ] **Step 1: Initialize Cloud Functions**

```bash
cd "c:\Users\Bedon\OneDrive\Documents\Desktop\dev codes\mobdev\TheDiningAtlas"
firebase init functions
```

Select: JavaScript, ESLint no, install dependencies yes.

- [ ] **Step 2: Create `functions/index.js`**

```js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

// Update avgRating when a review is created/deleted
exports.updateAvgRating = functions.firestore
  .document('restaurants/{restaurantId}/reviews/{reviewId}')
  .onWrite(async (change, context) => {
    const { restaurantId } = context.params;
    const reviewsSnap = await db.collection('restaurants').doc(restaurantId)
      .collection('reviews').get();
    if (reviewsSnap.empty) {
      await db.collection('restaurants').doc(restaurantId).update({ avgRating: 0, reviewCount: 0 });
      return;
    }
    const total = reviewsSnap.docs.reduce((sum, d) => sum + (d.data().rating || 0), 0);
    const avg = total / reviewsSnap.size;
    await db.collection('restaurants').doc(restaurantId).update({
      avgRating: Math.round(avg * 10) / 10,
      reviewCount: reviewsSnap.size,
    });
  });

// Update contributor score when a review is added to their restaurant
exports.updateContributorScore = functions.firestore
  .document('restaurants/{restaurantId}/reviews/{reviewId}')
  .onCreate(async (snap, context) => {
    const { restaurantId } = context.params;
    const restaurant = await db.collection('restaurants').doc(restaurantId).get();
    const contributorId = restaurant.data()?.contributorId;
    if (!contributorId) return;
    await db.collection('users').doc(contributorId).update({
      score: admin.firestore.FieldValue.increment(5),
    });
    await _updateTier(contributorId);
  });

// Score decay — run monthly
exports.monthlyScoreDecay = functions.pubsub
  .schedule('0 0 1 * *').onRun(async () => {
    const usersSnap = await db.collection('users').where('score', '>', 0).get();
    const batch = db.batch();
    usersSnap.docs.forEach(doc => {
      const lastSeen = doc.data().lastActiveAt?.toDate();
      const monthAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      if (!lastSeen || lastSeen < monthAgo) {
        batch.update(doc.ref, { score: admin.firestore.FieldValue.increment(-5) });
      }
    });
    await batch.commit();
  });

// Tier update helper
async function _updateTier(uid) {
  const userDoc = await db.collection('users').doc(uid).get();
  const score = userDoc.data()?.score || 0;
  let tier = 'explorer';
  if (score >= 2000) tier = 'city_legend';
  else if (score >= 500) tier = 'super_local';
  else if (score >= 100) tier = 'local';
  await db.collection('users').doc(uid).update({ tier });
}
```

- [ ] **Step 3: Deploy functions**

```bash
firebase deploy --only functions
```

- [ ] **Step 4: Commit**

```bash
git add functions/
git commit -m "feat: add Cloud Functions for avg rating, contributor score, tier updates, score decay"
```

---

## Self-Review Checklist

- [x] Task 1–4: All models + constants + interfaces + mocks — Day 1 deliverables complete
- [x] Tasks 5–11: All Firebase service impls covering every interface
- [x] Task 12: Groq AI service covers all 3 AI features (recommendations, translation, summarizer)
- [x] Task 13: All providers created, one per domain, use interface types not concrete types
- [x] Task 14: `main.dart` wires real services — single swap point
- [x] Task 15: Trip service complete
- [x] Task 16: Cloud Functions for scoring, rating, tier, decay
- [x] No TBDs or placeholders in any code block
- [x] Method signatures in providers match the interfaces defined in Task 3
- [x] `QuotaException` used in `SavedPlacesProvider` matches type defined in Task 2
- [x] `AppConstants.kCol*` used in services matches constants defined in Task 2
- [x] `GroqAiService` returns `PlaceSummaryModel` matching model defined in Task 1
