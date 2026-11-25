import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../theme/omori_theme.dart';
import '../widgets/sketchy_widgets.dart';
import 'game_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '21');
  final _dreamController = TextEditingController();

  // Wizard steps: 0 = intro text, 1 = name, 2 = age, 3 = dream self
  int _wizardStep = 0;
  String? _errorText;
  bool _saving = false;
  int? _createdSessionId;
  int _introBeat = -1; // -1 = wizard, 0..3 = intro death cutscene

  String get _playerName => _nameController.text.trim();
  int get _playerAge => int.tryParse(_ageController.text.trim()) ?? 21;
  String get _dreamSummary => _dreamController.text.trim();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _dreamController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_wizardStep > 0) {
      setState(() {
        _errorText = null;
        _wizardStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleNext() async {
    setState(() => _errorText = null);

    if (_wizardStep == 0) {
      setState(() => _wizardStep = 1);
      return;
    }

    if (_wizardStep == 1) {
      if (_playerName.isEmpty) {
        setState(() => _errorText = 'please write your name.');
        return;
      }
      setState(() => _wizardStep = 2);
      return;
    }

    if (_wizardStep == 2) {
      final parsed = int.tryParse(_ageController.text.trim());
      if (parsed == null || parsed < 10 || parsed > 65) {
        setState(() => _errorText = 'enter an age between 10 and 65.');
        return;
      }
      setState(() => _wizardStep = 3);
      return;
    }

    if (_wizardStep == 3) {
      if (_dreamSummary.length < 6) {
        setState(
          () => _errorText = 'describe your dream self in a short sentence.',
        );
        return;
      }
      await _submitForm();
    }
  }

  Future<void> _submitForm() async {
    setState(() => _saving = true);

    final db = DatabaseHelper.instance;
    final player = await db.createPlayer(
      name: _playerName,
      age: _playerAge,
      dreamSelfSummary: _dreamSummary,
    );
    final session = await db.createSession(
      playerId: player.playerId!,
      targetAge: player.age,
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
      _createdSessionId = session.sessionId;
      _introBeat = 0;
    });
  }

  List<String> get _introLines => [
    'You are $_playerAge years old. Waiting at a crosswalk in the pouring rain, you catch yourself thinking one last quiet thought...',
    '"If only I had been raised differently... maybe by now I would have become: $_dreamSummary."',
    'The pedestrian light flickers.\nA delivery truck’s headlights tear through the rain.\nTires scream against wet asphalt — and everything cuts to white.',
    '[ SYSTEM: REINCARNATION COMPLETE ]\n\nWhen you open your eyes, the rain is gone. In your trembling arms is a newborn — tiny, crying, wearing your name: $_playerName.\n\nYou have been reborn in another timeline... as your own parents.',
  ];

  void _advanceBeat() {
    if (_introBeat < _introLines.length - 1) {
      setState(() => _introBeat++);
    } else if (_createdSessionId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(sessionId: _createdSessionId!),
        ),
      );
    }
  }

  InputDecoration _softInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: OmoriColors.pastelLavender.withValues(alpha: 0.7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_introBeat >= 0) {
      return _buildIntroCutscene();
    }

    return Scaffold(
      backgroundColor: OmoriColors.whiteSpace,
      body: SafeArea(
        child: Column(
          children: [
            // Minimal borderless top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: OmoriColors.mutedInk,
                      size: 20,
                    ),
                    onPressed: _handleBack,
                  ),
                  const Spacer(),
                  // Quiet step dots
                  Row(
                    children: [
                      for (int i = 0; i < 4; i++)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i <= _wizardStep
                                ? OmoriColors.ink
                                : OmoriColors.subtleLine,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Centered single-step wizard stage
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _buildWizardStep(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardStep() {
    switch (_wizardStep) {
      case 0:
        return Column(
          key: const ValueKey('step_0'),
          mainAxisSize: MainAxisSize.min,
          children: [
            TypewriterText(
              key: const ValueKey('tw_step_0'),
              text:
                  'Before everything resets, write down who you are — and who you always wished you had grown up to be.',
              textAlign: TextAlign.center,
              style: OmoriTheme.hand(size: 22, height: 1.5),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: _handleNext,
              child: Text(
                'begin →',
                style: OmoriTheme.hand(
                  size: 20,
                  color: OmoriColors.dreamIndigo,
                ),
              ),
            ),
          ],
        );

      case 1:
        return Column(
          key: const ValueKey('step_1'),
          mainAxisSize: MainAxisSize.min,
          children: [
            TypewriterText(
              key: const ValueKey('tw_step_1'),
              text: 'What is your name?',
              textAlign: TextAlign.center,
              style: OmoriTheme.hand(size: 23),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              autofocus: true,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              style: OmoriTheme.hand(size: 20),
              decoration: _softInputDecoration('Sunny, Alex, Maya...'),
              onSubmitted: (_) => _handleNext(),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: OmoriTheme.hand(size: 16, color: OmoriColors.redAccent),
              ),
            ],
            const SizedBox(height: 30),
            TextButton(
              onPressed: _handleNext,
              child: Text(
                'next →',
                style: OmoriTheme.hand(
                  size: 20,
                  color: OmoriColors.dreamIndigo,
                ),
              ),
            ),
          ],
        );

      case 2:
        return Column(
          key: const ValueKey('step_2'),
          mainAxisSize: MainAxisSize.min,
          children: [
            TypewriterText(
              key: const ValueKey('tw_step_2'),
              text: 'How old are you tonight, $_playerName?',
              textAlign: TextAlign.center,
              style: OmoriTheme.hand(size: 23),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              child: TextField(
                controller: _ageController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: OmoriTheme.hand(size: 22),
                decoration: _softInputDecoration('10 – 65'),
                onSubmitted: (_) => _handleNext(),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: OmoriTheme.hand(size: 16, color: OmoriColors.redAccent),
              ),
            ],
            const SizedBox(height: 30),
            TextButton(
              onPressed: _handleNext,
              child: Text(
                'next →',
                style: OmoriTheme.hand(
                  size: 20,
                  color: OmoriColors.dreamIndigo,
                ),
              ),
            ),
          ],
        );

      default:
        return Column(
          key: const ValueKey('step_3'),
          mainAxisSize: MainAxisSize.min,
          children: [
            TypewriterText(
              key: const ValueKey('tw_step_3'),
              text: 'Who did you wish you had become by age $_playerAge?',
              textAlign: TextAlign.center,
              style: OmoriTheme.hand(size: 23, height: 1.4),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _dreamController,
              autofocus: true,
              maxLines: 4,
              textAlign: TextAlign.center,
              style: OmoriTheme.hand(size: 19),
              decoration: _softInputDecoration(
                'A confident artist who never felt afraid to fail...',
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: OmoriTheme.hand(size: 16, color: OmoriColors.redAccent),
              ),
            ],
            const SizedBox(height: 32),
            TextButton(
              onPressed: _saving ? null : _handleNext,
              child: Text(
                _saving ? 'remembering...' : 'step into the rain →',
                style: OmoriTheme.hand(
                  size: 20,
                  weight: FontWeight.w600,
                  color: OmoriColors.dreamIndigo,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildIntroCutscene() {
    final isAccidentBeat = _introBeat == 2;
    final isFinalBeat = _introBeat == _introLines.length - 1;
    final bgColor = isAccidentBeat ? OmoriColors.ink : OmoriColors.whiteSpace;
    final textColor = isAccidentBeat ? OmoriColors.paper : OmoriColors.ink;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (isFinalBeat)
                      const HangingLightbulb(cordHeight: 48)
                    else
                      const SizedBox(height: 48),
                    const Spacer(),
                    if (isAccidentBeat) ...[
                      const SketchImageFrame(
                        assetPath: 'assets/images/crosswalk_rain.jpg',
                        borderColor: OmoriColors.redAccent,
                        showShadow: false,
                      ),
                      const SizedBox(height: 22),
                    ] else if (isFinalBeat) ...[
                      const OmoriPortrait(
                        ageStage: 'Infancy',
                        mood: 'quiet',
                        size: 96,
                      ),
                      const SizedBox(height: 22),
                    ],
                    TypewriterText(
                      key: ValueKey(_introBeat),
                      text: _introLines[_introBeat],
                      textAlign: TextAlign.center,
                      style: OmoriTheme.hand(
                        size: 20,
                        color: textColor,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _advanceBeat,
                      child: Text(
                        isFinalBeat ? 'hold them close →' : 'continue →',
                        style: OmoriTheme.hand(
                          size: 20,
                          color: isAccidentBeat
                              ? OmoriColors.redAccent
                              : OmoriColors.dreamIndigo,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
