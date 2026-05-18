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
