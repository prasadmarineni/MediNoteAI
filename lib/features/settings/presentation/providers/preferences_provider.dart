import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RecordingMode { transcription, saveAudio }

class UserPreferences {
  final ThemeMode themeMode;
  final String language;
  final double ttsRate;
  final double ttsPitch;
  final String azureApiKey;
  final String geminiApiKey;
  final String sarvamApiKey;
  final RecordingMode recordingMode;

  UserPreferences({
    required this.themeMode,
    required this.language,
    required this.ttsRate,
    required this.ttsPitch,
    required this.azureApiKey,
    required this.geminiApiKey,
    required this.sarvamApiKey,
    required this.recordingMode,
  });

  UserPreferences copyWith({
    ThemeMode? themeMode,
    String? language,
    double? ttsRate,
    double? ttsPitch,
    String? azureApiKey,
    String? geminiApiKey,
    String? sarvamApiKey,
    RecordingMode? recordingMode,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      ttsRate: ttsRate ?? this.ttsRate,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      azureApiKey: azureApiKey ?? this.azureApiKey,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      sarvamApiKey: sarvamApiKey ?? this.sarvamApiKey,
      recordingMode: recordingMode ?? this.recordingMode,
    );
  }
}

class PreferencesNotifier extends StateNotifier<UserPreferences> {
  final SharedPreferences _prefs;

  PreferencesNotifier(this._prefs)
    : super(
        UserPreferences(
          themeMode: _loadThemeMode(_prefs),
          language: _prefs.getString('language') ?? 'English',
          ttsRate: _prefs.getDouble('ttsRate') ?? 0.5,
          ttsPitch: _prefs.getDouble('ttsPitch') ?? 1.0,
          azureApiKey: _prefs.getString('azureApiKey') ?? '',
          geminiApiKey: _prefs.getString('geminiApiKey') ?? '',
          sarvamApiKey:
              _prefs.getString('sarvamApiKey') ??
              'sk_o27p3nj6_vqkyQHWdj4RqFQWHL2mwvXcE',
          recordingMode: _loadRecordingMode(_prefs),
        ),
      );

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final mode = prefs.getString('themeMode');
    if (mode == 'light') return ThemeMode.light;
    if (mode == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  static RecordingMode _loadRecordingMode(SharedPreferences prefs) {
    final mode = prefs.getString('recordingMode');
    if (mode == 'saveAudio') return RecordingMode.saveAudio;
    return RecordingMode.transcription;
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setString('themeMode', mode.name);
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
    _prefs.setString('language', language);
  }

  void setTTSRate(double rate) {
    state = state.copyWith(ttsRate: rate);
    _prefs.setDouble('ttsRate', rate);
  }

  void setTTSPitch(double pitch) {
    state = state.copyWith(ttsPitch: pitch);
    _prefs.setDouble('ttsPitch', pitch);
  }

  void setAzureApiKey(String key) {
    state = state.copyWith(azureApiKey: key);
    _prefs.setString('azureApiKey', key);
  }

  void setGeminiApiKey(String key) {
    state = state.copyWith(geminiApiKey: key);
    _prefs.setString('geminiApiKey', key);
  }

  void setSarvamApiKey(String key) {
    state = state.copyWith(sarvamApiKey: key);
    _prefs.setString('sarvamApiKey', key);
  }

  void setRecordingMode(RecordingMode mode) {
    state = state.copyWith(recordingMode: mode);
    _prefs.setString('recordingMode', mode.name);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, UserPreferences>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return PreferencesNotifier(prefs);
    });
