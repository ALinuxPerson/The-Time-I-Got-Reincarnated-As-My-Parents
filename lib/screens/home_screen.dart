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
    final controller = TextEditingController(text: AiService.runtimeApiKey ?? '');
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OmoriColors.whiteSpace,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 64,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const HangingLightbulb(cordHeight: 36),
                Column(
                  children: [
                    const SizedBox(height: 10),
                    const SketchImageFrame(
                      assetPath: 'assets/images/title_banner.jpg',
                      aspectRatio: 16 / 9,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'THE TIME I GOT\nREINCARNATED AS\nMY PARENTS',
                      textAlign: TextAlign.center,
                      style: OmoriTheme.hand(
                        size: 30,
                        weight: FontWeight.w700,
                        height: 1.12,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'welcome to white space.\nyou already know how it ends — how will you live the years before it?',
                      textAlign: TextAlign.center,
                      style: OmoriTheme.hand(
                        size: 16,
                        color: OmoriColors.mutedInk,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: OmoriColors.ink,
                          ),
                        ),
                      )
                    else ...[
                      if (_inProgressSession != null &&
                          _inProgressPlayer != null) ...[
                        SketchButton(
                          label:
                              'Continue: ${_inProgressPlayer!.name} (Age ${_inProgressSession!.currentAge} / ${_inProgressSession!.targetAge})',
                          inverted: true,
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => GameScreen(
                                  sessionId: _inProgressSession!.sessionId!,
                                ),
                              ),
                            );
                            _loadState();
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      SketchButton(
                        label: 'Begin a New Life',
                        inverted: _inProgressSession == null,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const OnboardingScreen(),
                            ),
                          );
                          _loadState();
                        },
                      ),
                      const SizedBox(height: 12),
                      SketchButton(
                        label: _completedCount > 0
                            ? 'Past Lives & Memory Album ($_completedCount)'
                            : 'Past Lives & Memory Album',
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const PastLivesScreen(),
                            ),
                          );
                          _loadState();
                        },
                      ),
                    ],
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  child: GestureDetector(
                    onTap: _openApiKeyDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AiService.hasApiKey ? Icons.auto_awesome : Icons.key,
                          size: 15,
                          color: AiService.hasApiKey
                              ? OmoriColors.dreamIndigo
                              : OmoriColors.mutedInk,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AiService.hasApiKey
                              ? 'GEMINI AI CONNECTED (TAP TO EDIT)'
                              : 'OFFLINE STORY ENGINE (TAP TO ADD GEMINI KEY)',
                          style: OmoriTheme.pixel(
                            size: 15,
                            color: AiService.hasApiKey
                                ? OmoriColors.dreamIndigo
                                : OmoriColors.mutedInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
