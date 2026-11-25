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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '21');
  final _dreamController = TextEditingController();

  bool _saving = false;
  int? _createdSessionId;
  int _introBeat = -1; // -1 = form, 0..3 = intro death sequence

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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
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

  @override
  Widget build(BuildContext context) {
    if (_introBeat >= 0) {
      return _buildIntroCutscene();
    }

    return Scaffold(
      backgroundColor: OmoriColors.whiteSpace,
      appBar: AppBar(
        backgroundColor: OmoriColors.whiteSpace,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: OmoriColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('BEFORE THE RAIN', style: OmoriTheme.pixel(size: 22)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SketchBox(
                  fillColor: OmoriColors.warmPaper,
                  child: Text(
                    'Before everything resets, write down who you are — and who you always wished you had grown up to be.',
                    style: OmoriTheme.hand(size: 18),
                  ),
                ),
                const SizedBox(height: 22),
                Text('YOUR NAME', style: OmoriTheme.pixel(size: 20)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: OmoriTheme.hand(size: 18),
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Sunny, Alex, Maya...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please write your name.'
                      : null,
                ),
                const SizedBox(height: 18),
                Text(
                  'YOUR CURRENT AGE (TARGET AGE)',
                  style: OmoriTheme.pixel(size: 20),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  style: OmoriTheme.hand(size: 18),
                  decoration: const InputDecoration(
                    hintText: 'Between 10 and 65',
                  ),
                  validator: (v) {
                    final parsed = int.tryParse(v?.trim() ?? '');
                    if (parsed == null || parsed < 10 || parsed > 65) {
                      return 'Enter an age between 10 and 65.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  'YOUR DREAM SELF',
                  style: OmoriTheme.pixel(size: 20),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _dreamController,
                  maxLines: 4,
                  style: OmoriTheme.hand(size: 18),
                  decoration: const InputDecoration(
                    hintText:
                        'Who did you wish you had become? (e.g., "A confident musician who never felt afraid to fail, surrounded by people I love.")',
                  ),
                  validator: (v) => (v == null || v.trim().length < 6)
                      ? 'Describe your dream self in a short sentence.'
                      : null,
                ),
                const SizedBox(height: 26),
                SketchButton(
                  label: _saving ? 'Remembering...' : 'Step Into the Rain',
                  inverted: true,
                  onPressed: _saving ? null : _submitForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                  const SizedBox(height: 18),
                ] else if (isFinalBeat) ...[
                  const OmoriPortrait(
                    ageStage: 'Infancy',
                    mood: 'quiet',
                    size: 96,
                  ),
                  const SizedBox(height: 18),
                ],
                SketchBox(
                  fillColor: isAccidentBeat
                      ? OmoriColors.ink
                      : OmoriColors.paper,
                  borderColor: isAccidentBeat
                      ? OmoriColors.redAccent
                      : OmoriColors.ink,
                  showShadow: !isAccidentBeat,
                  padding: const EdgeInsets.all(20),
                  child: TypewriterText(
                    key: ValueKey(_introBeat),
                    text: _introLines[_introBeat],
                    style: OmoriTheme.hand(
                      size: 20,
                      color: textColor,
                      height: 1.45,
                    ),
                  ),
                ),
                const Spacer(),
                SketchButton(
                  label: isFinalBeat ? 'Hold Them Close' : 'Continue',
                  inverted: !isAccidentBeat,
                  accentColor: isAccidentBeat
                      ? OmoriColors.redAccent
                      : OmoriColors.ink,
                  onPressed: _advanceBeat,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
