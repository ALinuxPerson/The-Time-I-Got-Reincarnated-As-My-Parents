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
    final controller = TextEditingController(
      text: AiService.runtimeApiKey ?? '',
    );
    await showDialog<void>(
      context: context,
      animationStyle: const AnimationStyle(
        duration: OmoriTheme.motion,
        reverseDuration: OmoriTheme.motion,
        curve: OmoriTheme.curve,
      ),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SketchBox(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('STORY SETTINGS', style: OmoriTheme.pixel(size: 22)),
                const SizedBox(height: 8),
                Text(
                  'The story works offline. An optional Gemini key adds generated responses.',
                  style: OmoriTheme.hand(size: 16, color: OmoriColors.mutedInk),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
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
                          AiService.runtimeApiKey = controller.text.trim();
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
    controller.dispose();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    _loadState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (bounds.maxHeight - 48).clamp(0, double.infinity),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Text(
                              'THE TIME I GOT\nREINCARNATED AS\nMY PARENTS',
                              style: OmoriTheme.hand(size: 28, height: 1.15),
                            ),
                          ),
                        ),
                        const HangingLightbulb(cordHeight: 56),
                      ],
                    ),
                    const SizedBox(height: 80),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: FocusTraversalGroup(
                        policy: OrderedTraversalPolicy(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_loading)
                              Text('Loading...', style: OmoriTheme.pixel())
                            else ...[
                              if (_inProgressSession != null &&
                                  _inProgressPlayer != null) ...[
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(0),
                                  child: SketchButton(
                                    label: 'Continue',
                                    inverted: true,
                                    onPressed: () => _open(
                                      GameScreen(
                                        sessionId:
                                            _inProgressSession!.sessionId!,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(1),
                                child: SketchButton(
                                  label: 'New life',
                                  inverted: _inProgressSession == null,
                                  onPressed: () =>
                                      _open(const OnboardingScreen()),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(2),
                                child: SketchButton(
                                  label: _completedCount == 0
                                      ? 'Memories'
                                      : 'Memories ($_completedCount)',
                                  onPressed: () =>
                                      _open(const PastLivesScreen()),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(3),
                                child: SketchButton(
                                  label: 'Settings',
                                  onPressed: _openApiKeyDialog,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
