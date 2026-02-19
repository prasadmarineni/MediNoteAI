import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinote_ai/features/settings/presentation/providers/preferences_provider.dart';
import 'package:medinote_ai/features/auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_rounded),
            title: const Text('Theme Mode'),
            subtitle: Text(prefs.themeMode.name.toUpperCase()),
            trailing: DropdownButton<ThemeMode>(
              value: prefs.themeMode,
              onChanged: (mode) {
                if (mode != null) notifier.setThemeMode(mode);
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Real-time Transcription'),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const Text('Default Language'),
            subtitle: const Text('Used for Azure Speech Services'),
            trailing: DropdownButton<String>(
              value: prefs.language,
              onChanged: (lang) {
                if (lang != null) notifier.setLanguage(lang);
              },
              items: [
                'English',
                'Kannada',
                'Hindi',
                'Tamil',
                'Telugu',
              ].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key_rounded),
            title: const Text('Azure API Key'),
            subtitle: const Text('Securely stored locally'),
            onTap: () => _showApiKeyDialog(
              context,
              'Azure',
              prefs.azureApiKey,
              (val) => notifier.setAzureApiKey(val),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_rounded),
            title: const Text('Gemini API Key'),
            subtitle: const Text('Used for AI Clinical Summaries'),
            onTap: () => _showApiKeyDialog(
              context,
              'Gemini',
              prefs.geminiApiKey,
              (val) => notifier.setGeminiApiKey(val),
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Text-to-Speech (TTS)'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildSlider(
                  context,
                  'Speech Rate',
                  prefs.ttsRate,
                  (val) => notifier.setTTSRate(val),
                  min: 0.0,
                  max: 1.0,
                ),
                _buildSlider(
                  context,
                  'Pitch',
                  prefs.ttsPitch,
                  (val) => notifier.setTTSPitch(val),
                  min: 0.5,
                  max: 2.0,
                ),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Recording Preference'),
          RadioListTile<RecordingMode>(
            title: const Text('Inbuilt Transcription'),
            subtitle: const Text('Live text capture (Android: short duration)'),
            value: RecordingMode.transcription,
            groupValue: prefs.recordingMode,
            onChanged: (mode) {
              if (mode != null) notifier.setRecordingMode(mode);
            },
          ),
          RadioListTile<RecordingMode>(
            title: const Text('Save Recording'),
            subtitle: const Text('Capture full audio for documentation'),
            value: RecordingMode.saveAudio,
            groupValue: prefs.recordingMode,
            onChanged: (mode) {
              if (mode != null) notifier.setRecordingMode(mode);
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('App Version'),
            trailing: Text('1.0.0 (Build 1)'),
          ),
          const ListTile(
            leading: Icon(Icons.security_rounded),
            title: Text('Privacy Policy'),
            trailing: Icon(Icons.chevron_right_rounded),
          ),
          const Divider(),
          _buildLogoutButton(context, ref),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> onChanged, {
    required double min,
    required double max,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value.toStringAsFixed(1))],
        ),
        Slider(value: value, onChanged: onChanged, min: min, max: max),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () {
          ref.read(authProvider.notifier).logout();
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.red),
        label: const Text('Logout', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showApiKeyDialog(
    BuildContext context,
    String provider,
    String currentKey,
    ValueChanged<String> onSave,
  ) {
    final controller = TextEditingController(text: currentKey);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$provider API Key'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter your $provider Key'),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
