import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../theme/omori_theme.dart';
import '../widgets/sketchy_widgets.dart';
import 'game_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final DateTime Function()? clock;

  const OnboardingScreen({super.key, this.clock});

  /// Returns a natural time-of-day phrase relative to the given [now] clock.
  static String timeOfDayPhrase(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'this morning';
    if (hour >= 12 && hour < 17) return 'this afternoon';
    if (hour >= 17 && hour < 21) return 'this evening';
    return 'tonight';
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<String> _sexOptions = [
    'Female',
    'Male',
    'Non-binary',
    'Prefer not to say',
  ];

  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '21');
  final _dreamController = TextEditingController();

  // Wizard steps: 0 = intro text, 1 = name, 2 = sex, 3 = age, 4 = dream self
  int _wizardStep = 0;
  String? _selectedSex;
  bool _promptDone = false;
  bool _cutsceneTextDone = false;
  String? _errorText;
  bool _saving = false;
  int? _createdSessionId;
  int _introBeat = -1; // -1 = wizard, 0..3 = intro death cutscene

  String get _playerName => _nameController.text.trim();
  int get _playerAge => int.tryParse(_ageController.text.trim()) ?? 21;
  String get _dreamSummary => _dreamController.text.trim();
  String get _timeOfDay =>
      OnboardingScreen.timeOfDayPhrase((widget.clock ?? DateTime.now)());

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
        _promptDone = false;
        _wizardStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleNext() async {
    setState(() => _errorText = null);

    if (_wizardStep == 0) {
      setState(() {
        _promptDone = false;
        _wizardStep = 1;
      });
      return;
    }

    if (_wizardStep == 1) {
      if (_playerName.isEmpty) {
        setState(() => _errorText = 'please write your name.');
        return;
      }
      setState(() {
        _promptDone = false;
        _wizardStep = 2;
      });
      return;
    }

    if (_wizardStep == 2) {
      if (_selectedSex == null) {
        setState(() => _errorText = 'please select an option.');
        return;
      }
      setState(() {
        _promptDone = false;
        _wizardStep = 3;
      });
      return;
    }

    if (_wizardStep == 3) {
      final parsed = int.tryParse(_ageController.text.trim());
      if (parsed == null || parsed < 10 || parsed > 65) {
        setState(() => _errorText = 'enter an age between 10 and 65.');
        return;
      }
      setState(() {
        _promptDone = false;
        _wizardStep = 4;
      });
      return;
    }

    if (_wizardStep == 4) {
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
      sex: _selectedSex ?? 'Unspecified',
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
      _cutsceneTextDone = false;
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
      setState(() {
        _cutsceneTextDone = false;
        _introBeat++;
      });
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
      hintStyle: OmoriTheme.hand(
        size: 18,
        weight: FontWeight.w700,
        color: OmoriColors.mutedInk,
      ),
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
      body: SpaceParticlesBackground(
        child: SafeArea(
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
                        for (int i = 0; i < 5; i++)
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
                        duration: const Duration(milliseconds: 550),
                        switchInCurve: Curves.easeInOutSine,
                        switchOutCurve: Curves.easeInOutSine,
                        child: _buildWizardStep(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
              style: OmoriTheme.hand(
                size: 22,
                weight: FontWeight.w700,
                height: 1.5,
              ),
              onCompleted: () {
                if (mounted) setState(() => _promptDone = true);
              },
            ),
            const SizedBox(height: 40),
            GradualReveal(
              visible: _promptDone,
              delay: const Duration(milliseconds: 180),
              child: TextButton(
                onPressed: _handleNext,
                child: Text(
                  'begin →',
                  style: OmoriTheme.hand(
                    size: 20,
                    weight: FontWeight.w700,
                    color: OmoriColors.dreamIndigo,
                  ),
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
              style: OmoriTheme.hand(size: 23, weight: FontWeight.w700),
              onCompleted: () {
                if (mounted) setState(() => _promptDone = true);
              },
            ),
            const SizedBox(height: 24),
            GradualReveal(
              visible: _promptDone,
              delay: const Duration(milliseconds: 140),
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.words,
                style: OmoriTheme.hand(size: 20, weight: FontWeight.w700),
                decoration: _softInputDecoration('Sunny, Alex, Maya...'),
                onSubmitted: (_) => _handleNext(),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: OmoriTheme.hand(
                  size: 16,
                  weight: FontWeight.w700,
                  color: OmoriColors.redAccent,
                ),
              ),
            ],
            const SizedBox(height: 30),
            GradualReveal(
              visible: _promptDone,
              delay: const Duration(milliseconds: 480),
              child: TextButton(
                onPressed: _handleNext,
                child: Text(
                  'next →',
                  style: OmoriTheme.hand(
                    size: 20,
                    weight: FontWeight.w700,
                    color: OmoriColors.dreamIndigo,
                  ),
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
              text: 'What is your sex, $_playerName?',
              textAlign: TextAlign.center,
              style: OmoriTheme.hand(size: 23, weight: FontWeight.w700),
              onCompleted: () {
                if (mounted) setState(() => _promptDone = true);
              },
            ),
            const SizedBox(height: 24),
            GradualReveal(
              visible: _promptDone,
              delay: const Duration(milliseconds: 140),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final option in _sexOptions)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSex = option;
                          _errorText = null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedSex == option
                              ? OmoriColors.dreamIndigo
                              : OmoriColors.pastelLavender.withValues(
                                  alpha: 0.78,
                                ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          option,
                          style: OmoriTheme.hand(
                            size: 19,
                            weight: FontWeight.w700,
                            color: _selectedSex == option
                                ? OmoriColors.paper
                                : OmoriColors.ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: OmoriTheme.hand(
                  size: 16,
                  weight: FontWeight.w700,
                  color: OmoriColors.redAccent,
                ),
              ),
            ],
            const SizedBox(height: 30),
            GradualReveal(
              visible: _promptDone,
              delay: const Duration(milliseconds: 420),
              child: TextButton(
                onPressed: _handleNext,
                child: Text(
                  'next →',
                  style: OmoriTheme.hand(
                    size: 20,
                    weight: FontWeight.w700,
                    color: OmoriColors.dreamIndigo,
                  ),
                ),
              ),
            ),
          ],
        );

      case 3:
        return Column(
          key: const ValueKey('step_3'),
          mainAxisSize: MainAxisSize.min,
          children: [
            TypewriterText(
              key: const ValueKey('tw_step_3'),
              text: 'How old are you $_timeOfDay, $_playerName?',
              textAlign: TextAlign.center,
              style: OmoriTheme.hand(size: 23, weight: FontWeight.w700),
              onCompleted: () {
                if (mounted) setState(() => _promptDone = true);
              },
            ),
            const SizedBox(height: 24),
            GradualReveal(
              visible: _promptDone,
              delay: const Duration(milliseconds: 140),
              child: SizedBox(
                width: 160,
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: OmoriTheme.hand(size: 22, weight: FontWeight.w700),
                  decoration: _softInputDecoration('10 – 65'),
                  onSubmitted: (_) => _handleNext(),
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: OmoriTheme.hand(
                  size: 16,
                  weight: FontWeight.w700,
                  color: OmoriColors.redAccent,
                ),
              ),
            ],
            const SizedBox(height: 30),
            GradualReveal(
              visible: _promptDone,
              delay: const Duration(milliseconds: 480),
              child: TextButton(
                onPressed: _handleNext,
                child: Text(
                  'next →',
                  style: OmoriTheme.hand(
                    size: 20,
                    weight: FontWeight.w700,
                    color: OmoriColors.dreamIndigo,
                  ),
                ),
              ),
            ),
          ],
        );

      default:
        return Column(
          key: const ValueKey('step_4'),
          mainAxisSize: MainAxisSize.min,
          children: [
            TypewriterText(
              key: const ValueKey('tw_step_4'),
              text: 'Who did you wish you had become by age $_playerAge?',
              textAlign: TextAlign.center,
              style: OmoriTheme.hand(
                size: 23,
                weight: FontWeight.w700,
                height: 1.4,
              ),
              onCompleted: () {
                if (mounted) setState(() => _promptDone = true);
              },
            ),
            const SizedBox(height: 24),
            GradualReveal(
              visible: _promptDone,
              delay: const Duration(milliseconds: 140),
              child: TextField(
                controller: _dreamController,
                maxLines: 4,
                textAlign: TextAlign.center,
                style: OmoriTheme.hand(size: 19, weight: FontWeight.w700),
                decoration: _softInputDecoration(
                  'A confident artist who never felt afraid to fail...',
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: OmoriTheme.hand(
                  size: 16,
                  weight: FontWeight.w700,
                  color: OmoriColors.redAccent,
                ),
              ),
            ],
            const SizedBox(height: 32),
            GradualReveal(
              visible: _promptDone,
              delay: const Duration(milliseconds: 480),
              child: TextButton(
                onPressed: _saving ? null : _handleNext,
                child: Text(
                  _saving ? 'remembering...' : 'step into the rain →',
                  style: OmoriTheme.hand(
                    size: 20,
                    weight: FontWeight.w700,
                    color: OmoriColors.dreamIndigo,
                  ),
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
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeInOutSine,
      color: bgColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isFinalBeat) const Positioned.fill(child: _RebirthBlueBurst()),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SpaceParticlesBackground(
              darkMode: isAccidentBeat,
              pastelMode: isFinalBeat,
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 620),
                        switchInCurve: Curves.easeInOutSine,
                        switchOutCurve: Curves.easeInOutSine,
                        child: Column(
                          key: ValueKey('cutscene_$_introBeat'),
                          children: [
                            if (isFinalBeat)
                              const HangingLightbulb(cordHeight: 44, lit: true)
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
                                weight: FontWeight.w700,
                                color: textColor,
                                height: 1.5,
                              ),
                              onCompleted: () {
                                if (mounted) {
                                  setState(() => _cutsceneTextDone = true);
                                }
                              },
                            ),
                            const Spacer(),
                            GradualReveal(
                              visible: _cutsceneTextDone,
                              delay: const Duration(milliseconds: 200),
                              child: TextButton(
                                onPressed: _advanceBeat,
                                child: Text(
                                  isFinalBeat
                                      ? 'hold them close →'
                                      : 'continue →',
                                  style: OmoriTheme.hand(
                                    size: 20,
                                    weight: FontWeight.w700,
                                    color: isAccidentBeat
                                        ? OmoriColors.redAccent
                                        : (isFinalBeat
                                              ? const Color(0xFF1D4ED8)
                                              : OmoriColors.dreamIndigo),
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}

/// Radial blue explosion from White Space symbolizing being reborn.
class _RebirthBlueBurst extends StatefulWidget {
  const _RebirthBlueBurst();

  @override
  State<_RebirthBlueBurst> createState() => _RebirthBlueBurstState();
}

class _RebirthBlueBurstState extends State<_RebirthBlueBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _RebirthBlueBurstPainter(progress: _controller.value),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _RebirthBlueBurstPainter extends CustomPainter {
  final double progress;

  const _RebirthBlueBurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Origin sits right around the newborn portrait slightly above vertical center.
    final center = Offset(size.width * 0.5, size.height * 0.42);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) * 1.05;

    // Smooth explosive radial expansion into dreamy birth-sky blue.
    final burstT = Curves.easeOutExpo.transform(
      ((progress - 0.06) / 0.94).clamp(0.0, 1.0),
    );
    final currentRadius = maxRadius * burstT;

    if (currentRadius > 1.0) {
      final gradient = RadialGradient(
        center: Alignment(
          (center.dx / size.width) * 2 - 1,
          (center.dy / size.height) * 2 - 1,
        ),
        radius: 1.05,
        colors: const [
          Color(0xFFFFF8E8), // warm sunlit newborn glow
          Color(0xFFC8E7FF), // dreamy pastel sky blue
          Color(0xFF9ACFFF), // vivid soft sky blue
          Color(0xFFB7C5FF), // pastel periwinkle edge
        ],
        stops: const [0.0, 0.36, 0.72, 1.0],
      );

      final rect = Offset.zero & size;
      final fillPaint = Paint()..shader = gradient.createShader(rect);
      canvas.drawCircle(center, currentRadius, fillPaint);

      // Soft dreamy pastel aurora washes that bloom into the corners
      final washAlpha = Curves.easeOut.transform(burstT);
      final pinkCenter = Offset(size.width * 0.14, size.height * 0.22);
      final pinkR = size.shortestSide * 0.65;
      canvas.drawCircle(
        pinkCenter,
        pinkR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFB8D9).withValues(alpha: 0.42 * washAlpha),
              const Color(0x00FFB8D9),
            ],
          ).createShader(Rect.fromCircle(center: pinkCenter, radius: pinkR)),
      );

      final mintCenter = Offset(size.width * 0.88, size.height * 0.78);
      final mintR = size.shortestSide * 0.68;
      canvas.drawCircle(
        mintCenter,
        mintR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFA7F3D0).withValues(alpha: 0.42 * washAlpha),
              const Color(0x00A7F3D0),
            ],
          ).createShader(Rect.fromCircle(center: mintCenter, radius: mintR)),
      );

      final peachCenter = Offset(size.width * 0.86, size.height * 0.18);
      final peachR = size.shortestSide * 0.55;
      canvas.drawCircle(
        peachCenter,
        peachR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFE0A3).withValues(alpha: 0.40 * washAlpha),
              const Color(0x00FFE0A3),
            ],
          ).createShader(Rect.fromCircle(center: peachCenter, radius: peachR)),
      );
    }

    // Primary expanding pastel-blue & lilac shockwave rings.
    final ringT = Curves.easeOutCubic.transform(
      ((progress - 0.04) / 0.78).clamp(0.0, 1.0),
    );
    if (ringT > 0.0 && ringT < 1.0) {
      final ringR = maxRadius * 0.92 * ringT;
      final ringAlpha = (1.0 - ringT) * 0.55;
      final baseW = (18.0 * (1.0 - ringT)).clamp(1.5, 18.0);
      canvas.drawCircle(
        center,
        ringR,
        Paint()
          ..color = const Color(0xFFF472B6).withValues(alpha: ringAlpha * 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseW * 2.2,
      );
      canvas.drawCircle(
        center,
        ringR,
        Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseW,
      );
    }

    // Secondary soft pastel-gold inner ripple right behind the shockwave.
    final innerT = Curves.easeOutQuart.transform(
      ((progress - 0.14) / 0.80).clamp(0.0, 1.0),
    );
    if (innerT > 0.0 && innerT < 1.0) {
      final innerAlpha = (1.0 - innerT) * 0.48;
      final innerPaint = Paint()
        ..color = const Color(0xFFFFE58F).withValues(alpha: innerAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (10.0 * (1.0 - innerT)).clamp(1.0, 10.0);
      canvas.drawCircle(center, maxRadius * 0.72 * innerT, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RebirthBlueBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
