import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../interfaces/i_ai_service.dart';
import '../../models/onboarding_prefs_model.dart';
import '../../models/place_summary_model.dart';
import '../../models/review_model.dart';
import '../../core/constants/env.dart';

class GeminiAiService implements IAiService {
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<String> _generate(String prompt) async {
    final uri = Uri.parse('$_baseUrl?key=${Env.geminiApiKey}');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'responseMimeType': 'text/plain',
          },
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        final errorMsg = _tryExtractErrorMessage(response.body);
        throw Exception('Gemini API error: ${response.statusCode} - $errorMsg');
      }

      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini returned no response. This may be due to safety filters.');
      }

      final firstCandidate = candidates[0] as Map<String, dynamic>;
      final content = firstCandidate['content'] as Map<String, dynamic>?;
      
      if (content == null || content['parts'] == null) {
        final finishReason = firstCandidate['finishReason'] ?? 'Unknown';
        throw Exception('No content in Gemini response (Finish reason: $finishReason)');
      }

      final parts = content['parts'] as List;
      if (parts.isEmpty) throw Exception('Empty parts in Gemini response');
      
      return parts[0]['text'] as String;
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: Check your connection');
      }
      rethrow;
    }
  }

  String _tryExtractErrorMessage(String body) {
    try {
      final data = jsonDecode(body);
      return data['error']?['message'] ?? body;
    } catch (_) {
      return body;
    }
  }

  String _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) {
      throw Exception('No valid JSON found in response');
    }
    return raw.substring(start, end + 1);
  }

  String _extractText(String raw) {
    // Remove markdown code blocks like ```text ... ``` or just ``` ... ```
    final regExp = RegExp(r'```(?:\w+)?\n?([\s\S]*?)```');
    final match = regExp.firstMatch(raw);
    if (match != null) {
      return match.group(1)?.trim() ?? raw.trim();
    }
    return raw.trim();
  }

  @override
  Future<Map<String, double>> generateTasteWeights(
      OnboardingPrefsModel prefs) async {
    final prompt = '''
You are a hyper-local travel curator. The user likes: ${prefs.vibes.join(', ')}.
Their budget is ${prefs.budget}. They prefer atmosphere: ${prefs.atmosphere.join(', ')}.
Return ONLY a JSON object of {category: weight} pairs (weight 0.0-1.0), no explanation.
Example: {"Japanese": 0.9, "Street Food": 0.8}
''';
    try {
      final raw = await _generate(prompt);
      final jsonStr = _extractJson(raw);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
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
    final raw = await _generate(prompt);
    return _extractText(raw);
  }

  @override
  Future<PlaceSummaryModel> summarizeReviews({
    required String restaurantId,
    required List<ReviewModel> reviews,
  }) async {
    final reviewTexts =
        reviews.take(50).map((r) => '- (${r.rating}★) ${r.text}').join('\n');
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
    final raw = await _generate(prompt);
    final jsonStr = _extractJson(raw);
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return PlaceSummaryModel(
      vibeOneLiner: json['vibeOneLiner'] ?? '',
      topAspects: List<String>.from(json['topAspects'] ?? []),
      mainDish: json['mainDish'] ?? '',
      caveats: List<String>.from(json['caveats'] ?? []),
      bestTime: json['bestTime'] ?? '',
      generatedAt: DateTime.now(),
      reviewCountAtGeneration: reviews.length,
    );
  }

  @override
  Future<void> cacheSummary(String restaurantId, PlaceSummaryModel summary) async {
    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('summary')
        .doc('data')
        .set(summary.toFirestore());
  }
}
