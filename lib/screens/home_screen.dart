import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../theme/omori_theme.dart';
import '../widgets/sketchy_widgets.dart';
import 'game_screen.dart';
import 'onboarding_screen.dart';
import 'past_lives_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameSession? _inProgressSession;
  Player? _inProgressPlayer;
  int _completedCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final db = DatabaseHelper.instance;
    final active = await db.getLatestInProgressSession();
    Player? activePlayer;
    if (active != null) {
      activePlayer = await db.getPlayer(active.playerId);
    }
    final pastLives = await db.getCompletedPastLives();

    if (!mounted) return;
    setState(() {
      _inProgressSession = active;
      _inProgressPlayer = activePlayer;
      _completedCount = pastLives.length;
      _loading = false;
    });
  }

  Future<void> _openApiKeyDialog() async {
    var apiKey = AiService.runtimeApiKey ?? '';
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SingleChildScrollView(
          child: SketchBox(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'GEMINI API KEY (OPTIONAL)',
                  style: OmoriTheme.pixel(size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a Gemini API key for live AI interpretations and story roadmaps. Leave blank to use the built-in offline story engine.',
                  style: OmoriTheme.hand(size: 16, color: OmoriColors.mutedInk),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: apiKey,
                  onChanged: (value) => apiKey = value,
                  obscureText: true,
                  style: OmoriTheme.hand(size: 16),
                  decoration: const InputDecoration(hintText: 'AIza...'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SketchButton(
                        label: 'Cancel',
                        showPointer: false,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SketchButton(
                        label: 'Save',
                        inverted: true,
                        showPointer: false,
                        onPressed: () {
                          AiService.runtimeApiKey = apiKey.trim();
                          Navigator.pop(context);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _night = Color(0xFF1C1929);
  static const _paper = Color(0xFFFFF2DC);
  static const _mutedPaper = Color(0xFFE1D6C9);
  static const _sunlight = Color(0xFFFFD294);

  Future<void> _openScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (mounted) await _loadState();
  }

  ButtonStyle _menuStyle(Color foreground) {
    return TextButton.styleFrom(
      foregroundColor: foreground,
      backgroundColor: Colors.transparent,
      overlayColor: _sunlight,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
      alignment: Alignment.centerLeft,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(3)),
      ),
    );
  }

  Widget _menuEntry(
    String label,
    VoidCallback onPressed, {
    bool primary = false,
  }) {
    final color = primary ? _sunlight : _paper;

    return TextButton(
      onPressed: onPressed,
      style: _menuStyle(color),
      child: Row(
        children: [
          Icon(
            primary
                ? Icons.arrow_right_alt_rounded
                : Icons.chevron_right_rounded,
            size: 22,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              style: OmoriTheme.hand(
                size: 19,
                color: color,
                height: 1.15,
                weight: primary ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _inProgressSession;
    final player = _inProgressPlayer;
    final hasSavedLife = session != null && player != null;
    final hasApiKey = AiService.hasApiKey;

    return Scaffold(
      backgroundColor: _night,
      body: LayoutBuilder(
        builder: (context, viewport) {
          final wide = viewport.maxWidth >= 720;
          final compact = viewport.maxHeight < 620;
          final horizontalInset = (viewport.maxWidth * 0.065).clamp(
            22.0,
            110.0,
          );
          final verticalInset = compact
              ? 18.0
              : (viewport.maxHeight * 0.065).clamp(32.0, 68.0);
          final titleSize = wide
              ? (viewport.maxHeight * 0.08).clamp(36.0, 62.0)
              : 36.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/banner.gif',
                fit: BoxFit.cover,
                alignment: Alignment(wide ? 0.18 : 0.50, 0.9),
                filterQuality: FilterQuality.none,
                excludeFromSemantics: true,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: wide
                        ? const [Color(0x651C1929), Color(0x001C1929)]
                        : [
                            Color(0xEC1C1929),
                            Color(0xBF1C1929),
                            compact ? Color(0xAE1C1929) : Color(0x141C1929),
                          ],
                    stops: wide ? const [0.12, 0.66] : const [0, 0.57, 1],
                  ),
                ),
              ),
              if (wide)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xEE1C1929),
                        Color(0xA31C1929),
                        Color(0x001C1929),
                      ],
                      stops: [0, 0.30, 0.73],
                    ),
                  ),
                ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalInset,
                    vertical: verticalInset,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 550),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: compact ? 12 : 18),
                            child: Semantics(
                              header: true,
                              child: Text(
                                'The Time I Got\nReincarnated as\nMy Parents',
                                style: OmoriTheme.hand(
                                  size: titleSize,
                                  height: 0.99,
                                  color: _paper,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            'You already know how it ends.\nHow will you live the years before it?',
                            style: OmoriTheme.hand(
                              size: 15,
                              height: 1.28,
                              color: _mutedPaper,
                            ),
                          ),
                          SizedBox(height: compact ? 12 : 22),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 410),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_loading)
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: EdgeInsets.all(11),
                                      child: SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _sunlight,
                                        ),
                                      ),
                                    ),
                                  )
                                else ...[
                                  if (hasSavedLife)
                                    _menuEntry(
                                      'Continue: ${player.name} (Age ${session.currentAge} / ${session.targetAge})',
                                      () => _openScreen(
                                        GameScreen(
                                          sessionId: session.sessionId!,
                                        ),
                                      ),
                                      primary: true,
                                    ),
                                  _menuEntry(
                                    'Begin a New Life',
                                    () => _openScreen(const OnboardingScreen()),
                                    primary: !hasSavedLife,
                                  ),
                                  _menuEntry(
                                    _completedCount > 0
                                        ? 'Past Lives & Memory Album ($_completedCount)'
                                        : 'Past Lives & Memory Album',
                                    () => _openScreen(const PastLivesScreen()),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 14),
                          TextButton.icon(
                            onPressed: _openApiKeyDialog,
                            style: _menuStyle(_mutedPaper),
                            icon: Icon(
                              hasApiKey ? Icons.auto_awesome : Icons.key,
                              size: 15,
                            ),
                            label: Text(
                              hasApiKey
                                  ? 'Gemini AI connected · Edit key'
                                  : 'Offline story engine · Add Gemini key',
                              style: OmoriTheme.hand(
                                size: 13,
                                color: _mutedPaper,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
