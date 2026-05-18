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

  @override
  Future<void> cacheSummary(String restaurantId, PlaceSummaryModel summary) async {
    // GroqAiService is replaced by GeminiAiService; this is kept for reference only
  }
}
