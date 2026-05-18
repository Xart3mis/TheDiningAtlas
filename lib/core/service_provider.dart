import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../services/interfaces/i_ai_service.dart';
import '../services/interfaces/i_chat_service.dart';
import '../services/interfaces/i_location_service.dart';
import '../services/interfaces/i_notification_service.dart';
import '../services/interfaces/i_restaurant_service.dart';
import '../services/interfaces/i_review_service.dart';
import '../services/interfaces/i_storage_service.dart';
import '../services/interfaces/i_subscription_service.dart';
import '../services/interfaces/i_trip_service.dart';
import '../services/interfaces/i_user_service.dart';

import '../services/mock/mock_ai_service.dart';
import '../services/mock/mock_chat_service.dart';
import '../services/mock/mock_location_service.dart';
import '../services/mock/mock_notification_service.dart';
import '../services/mock/mock_restaurant_service.dart';
import '../services/mock/mock_review_service.dart';
import '../services/mock/mock_storage_service.dart';
import '../services/mock/mock_subscription_service.dart';
import '../services/mock/mock_trip_service.dart';
import '../services/mock/mock_user_service.dart';

import '../services/firebase/firestore_restaurant_service.dart';
import '../services/firebase/firestore_review_service.dart';
import '../services/firebase/firestore_user_service.dart';
import '../services/firebase/firestore_chat_service.dart';
import '../services/firebase/firebase_storage_service.dart';
import '../services/firebase/geolocator_location_service.dart';
import '../services/firebase/fcm_notification_service.dart';
import '../services/ai/groq_ai_service.dart';

import '../services/firebase/firestore_trip_service.dart';

import '../providers/restaurant_provider.dart';
import '../providers/review_provider.dart';
import '../providers/user_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/saved_places_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/ai_provider.dart';
import '../providers/auth_provider.dart';

class ServiceProvider {
  static const bool useFirebase = true;

  static List<SingleChildWidget> getProviders() {
    final restaurantService = useFirebase ? FirestoreRestaurantService() : MockRestaurantService();
    final reviewService = useFirebase ? FirestoreReviewService() : MockReviewService();
    final userService = useFirebase ? FirestoreUserService() : MockUserService();
    final tripService = useFirebase ? FirestoreTripService() : MockTripService();
    final chatService = useFirebase ? FirestoreChatService() : MockChatService();
    final storageService = useFirebase ? FirebaseStorageService() : MockStorageService();
    final locationService = useFirebase ? GeolocatorLocationService() : MockLocationService();
    final notificationService = useFirebase ? FcmNotificationService() : MockNotificationService();
    final aiService = useFirebase ? GroqAiService() : MockAiService();
    final subscriptionService = MockSubscriptionService();

    return [
      // Base Interfaces
      Provider<IRestaurantService>(create: (_) => restaurantService),
      Provider<IReviewService>(create: (_) => reviewService),
      Provider<IUserService>(create: (_) => userService),
      Provider<ITripService>(create: (_) => tripService),
      Provider<IChatService>(create: (_) => chatService),
      Provider<IStorageService>(create: (_) => storageService),
      Provider<ILocationService>(create: (_) => locationService),
      Provider<INotificationService>(create: (_) => notificationService),
      Provider<IAiService>(create: (_) => aiService),
      Provider<ISubscriptionService>(create: (_) => subscriptionService),

      // State Providers
      ChangeNotifierProvider(create: (_) => AuthProvider(userService)),
      ChangeNotifierProvider(create: (_) => RestaurantProvider(restaurantService)),
      ChangeNotifierProvider(create: (_) => ReviewProvider(reviewService, aiService)),
      ChangeNotifierProvider(create: (_) => UserProvider(userService)),
      ChangeNotifierProvider(create: (_) => TripProvider(tripService)),
      ChangeNotifierProvider(create: (_) => ChatProvider(chatService, aiService)),
      ChangeNotifierProvider(create: (_) => SavedPlacesProvider(userService, notificationService)),
      ChangeNotifierProvider(create: (_) => OnboardingProvider(userService, aiService)),
      ChangeNotifierProvider(create: (_) => NotificationProvider(notificationService)),
      ChangeNotifierProvider(create: (_) => AiProvider(aiService, reviewService)),
    ];
  }
}
