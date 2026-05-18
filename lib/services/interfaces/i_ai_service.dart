import '../../models/onboarding_prefs_model.dart';
import '../../models/place_summary_model.dart';
import '../../models/review_model.dart';

abstract class IAiService {
  Future<Map<String, double>> generateTasteWeights(OnboardingPrefsModel prefs);
  Future<String> translate({required String text, required String targetLang});
  Future<PlaceSummaryModel> summarizeReviews({required String restaurantId, required List<ReviewModel> reviews});
  Future<void> cacheSummary(String restaurantId, PlaceSummaryModel summary);
}
