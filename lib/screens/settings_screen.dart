import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import '../services/sound_service.dart';
import '../theme/omori_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _apiKey = AiService.runtimeApiKey ?? '';

  void _save() {
    SoundService.playUi(UiSound.confirm);
    AiService.runtimeApiKey = _apiKey.trim();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: SoundService.withUiSound(
            UiSound.back,
            () => Navigator.maybePop(context),
          ),
        ),
        title: Text('Settings', style: OmoriTheme.hand(size: 24)),
        backgroundColor: OmoriColors.whiteSpace,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Story engine',
                      style: OmoriTheme.hand(size: 30, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a Gemini API key for live interpretations and story '
                    'roadmaps. If no key is configured, the game uses the '
                    'offline story engine.',
                    style: OmoriTheme.hand(
                      size: 16,
                      color: OmoriColors.mutedInk,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    initialValue: _apiKey,
                    onChanged: (value) => _apiKey = value,
                    onFieldSubmitted: (_) => _save(),
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    style: OmoriTheme.hand(size: 16),
                    decoration: const InputDecoration(
                      labelText: 'Gemini API key (optional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        enableFeedback: false,
                        textStyle: theme.textTheme.bodyLarge,
                        minimumSize: const Size(88, 48),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
