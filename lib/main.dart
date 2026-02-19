import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinote_ai/core/router/app_router.dart';
import 'package:medinote_ai/core/theme/app_theme.dart';
import 'package:medinote_ai/core/services/firebase_service.dart';
import 'package:medinote_ai/core/services/local_database_service.dart';
import 'package:medinote_ai/features/settings/presentation/providers/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  await LocalDatabaseService.initialize();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MediNoteApp(),
    ),
  );
}

class MediNoteApp extends ConsumerWidget {
  const MediNoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPrefs = ref.watch(preferencesProvider);

    return MaterialApp.router(
      title: 'MediNoteAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: userPrefs.themeMode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
