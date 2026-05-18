class AppConstants {
  // Firestore collection names
  static const String kColRestaurants = 'restaurants';
  static const String kColReviews = 'reviews';
  static const String kColUsers = 'users';
  static const String kColChats = 'chats';
  static const String kColMessages = 'messages';
  static const String kColTrips = 'trips';
  static const String kColUserTrips = 'userTrips';
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
