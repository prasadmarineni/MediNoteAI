import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinote_ai/features/settings/presentation/providers/preferences_provider.dart';
import 'package:medinote_ai/features/summary/data/services/gemini_ai_service.dart';
import 'package:medinote_ai/features/summary/data/services/mock_ai_service.dart';
import 'package:medinote_ai/features/summary/domain/services/ai_service_interface.dart';

final aiServiceProvider = Provider<IAIService>((ref) {
  final prefs = ref.watch(preferencesProvider);

  if (prefs.geminiApiKey.isNotEmpty) {
    return GeminiAIService(apiKey: prefs.geminiApiKey);
  }

  // Fallback to Mock if no key provided
  return MockAIService();
});
