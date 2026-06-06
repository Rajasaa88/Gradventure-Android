import 'api_key.dart';

class GeminiConfig {
  /// Gemini API Key loaded securely from --dart-define environment variables
  /// or falling back to the ignored secrets file key if not provided via environment.
  static const String apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: geminiApiKey,
  );

  /// Default model used for AI Chat
  static const String modelName = 'gemini-2.5-flash';

  /// System instructions for the Gradventure AI assistant
  static const String systemInstruction = 
      "Kamu adalah asisten AI khusus untuk aplikasi akademik kampus bernama Gradventure. "
      "Tugasmu adalah menjawab pertanyaan yang berkaitan dengan perkuliahan, jadwal, KRS, tugas akhir, dan kehidupan kampus Universitas Mataram. "
      "Jika pengguna bertanya di luar topik akademik kampus (misalnya resep masakan, gosip artis, atau sepak bola), "
      "tolak secara sopan dan ingatkan mereka bahwa kamu hanya bisa membantu dalam hal akademik.";
}
