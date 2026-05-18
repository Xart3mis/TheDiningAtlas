class Env {
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
}
