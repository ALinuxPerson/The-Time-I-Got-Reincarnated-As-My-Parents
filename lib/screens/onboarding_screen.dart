import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../theme/omori_theme.dart';
import '../widgets/sketchy_widgets.dart';
import 'game_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final DateTime Function()? clock;
  const OnboardingScreen({super.key, this.clock});

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
  final _form = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '21');
  final _dreamController = TextEditingController();
  String _sex = 'Prefer not to say';
  bool _saving = false;
  bool _textDone = false;
  int? _sessionId;
  int _beat = -1;
  String? _error;

  String get _playerName => _nameController.text.trim();
  int get _playerAge => int.parse(_ageController.text.trim());
  String get _dreamSummary => _dreamController.text.trim();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _dreamController.dispose();
    super.dispose();
  }

  Future<void> _begin() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final db = DatabaseHelper.instance;
      final player = await db.createPlayer(
        name: _playerName,
        sex: _sex,
        age: _playerAge,
        dreamSelfSummary: _dreamSummary,
      );
      final session = await db.createSession(
        playerId: player.playerId!,
        targetAge: player.age,
      );
      if (!mounted) return;
      setState(() {
        _sessionId = session.sessionId;
        _beat = 0;
        _saving = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Please try again.';
        });
      }
    }
  }

  void _next() {
    if (_beat < _introLines.length - 1) {
      setState(() {
        _beat++;
        _textDone = false;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(sessionId: _sessionId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_beat >= 0) return _cutscene();
    return Scaffold(
      appBar: AppBar(title: Text('NEW LIFE', style: OmoriTheme.pixel())),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Who were you?', style: OmoriTheme.hand(size: 28)),
                      const SizedBox(height: 8),
                      Text(
                        'Before you begin again, write down what you remember.',
                        style: OmoriTheme.hand(),
                      ),
                      const SizedBox(height: 24),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(0),
                        child: TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          style: OmoriTheme.hand(),
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (value) =>
                              value!.trim().isEmpty ? 'Write your name.' : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(1),
                        child: DropdownButtonFormField<String>(
                          initialValue: _sex,
                          isExpanded: true,
                          style: OmoriTheme.hand(),
                          decoration: const InputDecoration(labelText: 'Sex'),
                          items:
                              [
                                    'Female',
                                    'Male',
                                    'Non-binary',
                                    'Prefer not to say',
                                  ]
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) => setState(() => _sex = value!),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(2),
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          style: OmoriTheme.hand(),
                          decoration: const InputDecoration(
                            labelText: 'Age in years',
                          ),
                          validator: (value) {
                            final age = int.tryParse(value!.trim());
                            return age == null || age < 10 || age > 65
                                ? 'Enter 10-65 years.'
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(3),
                        child: TextFormField(
                          controller: _dreamController,
                          minLines: 2,
                          maxLines: 4,
                          style: OmoriTheme.hand(),
                          decoration: const InputDecoration(
                            labelText: 'Who did you wish you had become?',
                          ),
                          validator: (value) => value!.trim().length < 6
                              ? 'Write a short sentence.'
                              : null,
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _error!,
                            style: OmoriTheme.hand(color: OmoriColors.accent),
                          ),
                        ),
                      const SizedBox(height: 24),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(4),
                        child: SketchButton(
                          label: _saving ? 'Remembering...' : 'Begin',
                          inverted: true,
                          onPressed: _saving ? null : _begin,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cutscene() {
    final dark = _beat == 2;
    final color = dark ? OmoriColors.paper : OmoriColors.ink;
    return Scaffold(
      backgroundColor: dark ? OmoriColors.ink : OmoriColors.whiteSpace,
      body: SafeArea(
        child: Column(
          children: [
            if (_beat == 3) const HangingLightbulb(cordHeight: 32),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: TypewriterText(
                      key: ValueKey(_beat),
                      text: _introLines[_beat],
                      style: OmoriTheme.hand(color: color),
                      onCompleted: () {
                        if (mounted) setState(() => _textDone = true);
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (_textDone)
              Padding(
                padding: const EdgeInsets.all(24),
                child: SketchButton(
                  label: _beat == 3 ? 'Hold them close' : 'Continue',
                  onPressed: _next,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<String> get _introLines => [
    'You are $_playerAge years old. Waiting at a crosswalk in the pouring rain, you catch yourself thinking one last quiet thought...',
    '"If only I had been raised differently... maybe by now I would have become: $_dreamSummary."',
    'The pedestrian light flickers.\nA delivery truck’s headlights tear through the rain.\nTires scream against wet asphalt — and everything cuts to white.',
    'When you open your eyes, the rain is gone. In your trembling arms is a newborn — tiny, crying, wearing your name: $_playerName.\n\nYou have been reborn in another timeline... as your own parents.',
  ];
}
