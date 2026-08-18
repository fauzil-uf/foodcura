class ApiConstants {
  ApiConstants._();

  /// Gemini API Key dimuat dari environment (--dart-define=GEMINI_API_KEY=your_key)
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}
