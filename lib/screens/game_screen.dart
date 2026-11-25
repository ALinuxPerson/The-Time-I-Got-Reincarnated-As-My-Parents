import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../theme/omori_theme.dart';
import '../widgets/sketchy_widgets.dart';
import 'ending_screen.dart';
import 'live_roadmap_screen.dart';

class GameScreen extends StatefulWidget {
  final int sessionId;

  const GameScreen({super.key, required this.sessionId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _customChoiceController = TextEditingController();
  final _aiService = AiService();

  Player? _player;
  GameSession? _session;
  List<Scenario> _scenarios = [];
  List<int> _milestoneAges = [];
  List<DecisionWithDetails> _decisions = [];

  bool _loading = true;
  bool _submitting = false;
  bool _showStats = false; // Collapsed by default
  bool _optionsOpen = false; // Options drop down
  bool _showCustomInput = false;
  DecisionWithDetails? _activeReactionBeat;

  int get _nextScenarioIndex => _decisions.length;
  bool get _hasMoreScenarios => _nextScenarioIndex < _scenarios.length;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _customChoiceController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final db = DatabaseHelper.instance;
    final session = await db.getSession(widget.sessionId);
    if (session == null) return;

    final player = await db.getPlayer(session.playerId);
    if (player == null) return;

    final scenarios = await db.getScenariosForTargetAge(session.targetAge);
    final decisions = await db.getDecisionsForSession(widget.sessionId);
    final ages = _computeMilestoneAges(scenarios, session.targetAge);

    if (!mounted) return;
    setState(() {
      _session = session;
      _player = player;
      _scenarios = scenarios;
      _milestoneAges = ages;
      _decisions = decisions;
      _loading = false;
    });

    if (decisions.length >= scenarios.length && scenarios.isNotEmpty) {
      _goToEnding();
    }
  }

  List<int> _computeMilestoneAges(List<Scenario> scenarios, int targetAge) {
    final ages = <int>[];
    int prevAge = 0;
    for (int i = 0; i < scenarios.length; i++) {
      final s = scenarios[i];
      final remaining = scenarios.length - 1 - i;
      final maxAllowed = (targetAge - 1 - remaining).clamp(1, targetAge);
      final ideal = ((s.minAge + s.maxAge) ~/ 2).clamp(s.minAge, s.maxAge);
      final assigned = ideal.clamp(prevAge + 1, maxAllowed);
      ages.add(assigned);
      prevAge = assigned;
    }
    return ages;
  }

  Future<void> _submitDecision(String choiceText) async {
    final trimmed = choiceText.trim();
    if (trimmed.isEmpty || _submitting || !_hasMoreScenarios) return;

    final player = _player!;
    final scenario = _scenarios[_nextScenarioIndex];
    final ageAtDecision = _milestoneAges[_nextScenarioIndex];

    setState(() {
      _submitting = true;
      _optionsOpen = false;
      _showCustomInput = false;
    });

    final db = DatabaseHelper.instance;
    final decision = await db.insertDecision(
      sessionId: widget.sessionId,
      scenarioId: scenario.scenarioId!,
      choiceText: trimmed,
      ageAtDecision: ageAtDecision,
    );

    final aiResult = await _aiService.analyzeDecision(
      player: player,
      scenario: scenario,
      choiceText: trimmed,
      ageAtDecision: ageAtDecision,
      priorDecisions: _decisions,
    );

    final analysis = await db.insertAiAnalysis(
      decisionId: decision.decisionId!,
      interpretation: aiResult.interpretation,
      childReaction: aiResult.childReaction,
      mood: aiResult.mood,
      happinessDelta: aiResult.happinessDelta,
      healthDelta: aiResult.healthDelta,
      smartsDelta: aiResult.smartsDelta,
      ambitionDelta: aiResult.ambitionDelta,
    );

    final updatedSession = _session!.copyWith(
      currentAge: ageAtDecision,
      happiness: (_session!.happiness + aiResult.happinessDelta).clamp(0, 100),
      health: (_session!.health + aiResult.healthDelta).clamp(0, 100),
      smarts: (_session!.smarts + aiResult.smartsDelta).clamp(0, 100),
      ambition: (_session!.ambition + aiResult.ambitionDelta).clamp(0, 100),
    );
    await db.updateSessionProgress(
      sessionId: widget.sessionId,
      currentAge: updatedSession.currentAge,
      happiness: updatedSession.happiness,
      health: updatedSession.health,
      smarts: updatedSession.smarts,
      ambition: updatedSession.ambition,
    );

    _customChoiceController.clear();

    final completedItem = DecisionWithDetails(
      decision: decision,
      scenario: scenario,
      analysis: analysis,
    );

    if (!mounted) return;
    setState(() {
      _session = updatedSession;
      _decisions = [..._decisions, completedItem];
      _activeReactionBeat = completedItem;
      _submitting = false;
    });
  }

  void _continueFromReaction() {
    if (!_hasMoreScenarios) {
      _goToEnding();
      return;
    }
    setState(() {
      _activeReactionBeat = null;
      _optionsOpen = false;
      _showCustomInput = false;
    });
  }

  void _goToEnding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => EndingScreen(sessionId: widget.sessionId),
      ),
    );
  }

  int _displayAge() {
    if (_activeReactionBeat != null) {
      return _activeReactionBeat!.decision.ageAtDecision;
    }
    if (_hasMoreScenarios) {
      return _milestoneAges[_nextScenarioIndex];
    }
    return _session?.targetAge ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _player == null || _session == null) {
      return const Scaffold(
        backgroundColor: OmoriColors.whiteSpace,
        body: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: OmoriColors.mutedInk,
            ),
          ),
        ),
      );
    }

    final session = _session!;
    final currentAge = _displayAge();

    return Scaffold(
      backgroundColor: OmoriColors.whiteSpace,
      body: SafeArea(
        child: Column(
          children: [
            // --- BORDERLESS TOP BAR (AGE + COLLAPSED ICON STATS + CLOSE) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'age $currentAge',
                        style: OmoriTheme.hand(
                          size: 17,
                          color: OmoriColors.mutedInk,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Decision roadmap',
                        icon: const Icon(
                          Icons.map_outlined,
                          color: OmoriColors.mutedInk,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => LiveRoadmapScreen(
                                player: _player!,
                                session: session,
                                scenarios: _scenarios,
                                milestoneAges: _milestoneAges,
                                decisions: _decisions,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: _showStats ? 'Hide stats' : 'Show stats',
                        icon: Icon(
                          _showStats
                              ? Icons.expand_less_rounded
                              : Icons.auto_awesome_outlined,
                          color: OmoriColors.mutedInk,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _showStats = !_showStats),
                      ),
                      IconButton(
                        tooltip: 'Leave',
                        icon: const Icon(
                          Icons.close_rounded,
                          color: OmoriColors.mutedInk,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState: _showStats
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 8),
                      child: _IconStatsRow(
                        happiness: session.happiness,
                        health: session.health,
                        smarts: session.smarts,
                        ambition: session.ambition,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- CENTERED SCENARIO ALONE IN THE MIDDLE + DROPDOWN OPTIONS ---
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _submitting
                        ? Center(
                            child: Text(
                              '...',
                              style: OmoriTheme.hand(
                                size: 26,
                                color: OmoriColors.mutedInk,
                              ),
                            ),
                          )
                        : _activeReactionBeat != null
                        ? _buildReactionBeat(_activeReactionBeat!)
                        : _hasMoreScenarios
                        ? _buildScenarioStage(_scenarios[_nextScenarioIndex])
                        : Text(
                            'Age ${session.targetAge} arrives.\nThe sky turns gray with rain...',
                            textAlign: TextAlign.center,
                            style: OmoriTheme.hand(size: 21, height: 1.5),
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

  Widget _buildScenarioStage(Scenario scenario) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Scenario title & typewriter narrative floating alone in White Space
        Text(
          scenario.title,
          textAlign: TextAlign.center,
          style: OmoriTheme.hand(
            size: 24,
            weight: FontWeight.w600,
            color: OmoriColors.ink,
          ),
        ),
        const SizedBox(height: 14),
        TypewriterText(
          key: ValueKey(scenario.scenarioId),
          text: scenario.description,
          textAlign: TextAlign.center,
          style: OmoriTheme.hand(
            size: 20,
            height: 1.55,
            color: OmoriColors.ink,
          ),
        ),
        const SizedBox(height: 36),

        // Soft borderless dropdown trigger for options
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _optionsOpen = !_optionsOpen),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _optionsOpen ? 'hide choices' : 'what do you do?',
                  style: OmoriTheme.hand(
                    size: 18,
                    color: OmoriColors.dreamIndigo,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _optionsOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: OmoriColors.dreamIndigo,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // Dropdown options list (no borders, no lines, no dividers)
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _optionsOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final choice in scenario.presetChoices) ...[
                  _SoftChoiceTile(
                    label: choice,
                    onTap: () => _submitDecision(choice),
                  ),
                  const SizedBox(height: 8),
                ],
                if (!_showCustomInput)
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _showCustomInput = true),
                      child: Text(
                        'write your own...',
                        style: OmoriTheme.hand(
                          size: 17,
                          color: OmoriColors.mutedInk,
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      children: [
                        TextField(
                          controller: _customChoiceController,
                          maxLines: 3,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          style: OmoriTheme.hand(size: 18),
                          decoration: InputDecoration(
                            hintText: 'say or do anything...',
                            filled: true,
                            fillColor: OmoriColors.pastelLavender,
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
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  setState(() => _showCustomInput = false),
                              child: Text(
                                'cancel',
                                style: OmoriTheme.hand(
                                  size: 17,
                                  color: OmoriColors.mutedInk,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () =>
                                  _submitDecision(_customChoiceController.text),
                              child: Text(
                                'respond →',
                                style: OmoriTheme.hand(
                                  size: 18,
                                  weight: FontWeight.w600,
                                  color: OmoriColors.dreamIndigo,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReactionBeat(DecisionWithDetails beat) {
    final reaction = beat.analysis?.childReaction ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TypewriterText(
          key: ValueKey('reaction_${beat.decision.decisionId}'),
          text: reaction,
          textAlign: TextAlign.center,
          style: OmoriTheme.hand(
            size: 21,
            height: 1.55,
            color: OmoriColors.ink,
          ),
        ),
        const SizedBox(height: 36),
        TextButton(
          onPressed: _continueFromReaction,
          child: Text(
            _hasMoreScenarios
                ? 'continue →'
                : 'age ${_session!.targetAge} →',
            style: OmoriTheme.hand(
              size: 19,
              color: OmoriColors.dreamIndigo,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconStatsRow extends StatelessWidget {
  final int happiness;
  final int health;
  final int smarts;
  final int ambition;

  const _IconStatsRow({
    required this.happiness,
    required this.health,
    required this.smarts,
    required this.ambition,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatIconItem(
          icon: Icons.sentiment_satisfied_alt_rounded,
          value: happiness,
          color: const Color(0xFFD99B26),
          tooltip: 'Happiness',
        ),
        _StatIconItem(
          icon: Icons.favorite_border_rounded,
          value: health,
          color: const Color(0xFF4B9E5B),
          tooltip: 'Health',
        ),
        _StatIconItem(
          icon: Icons.auto_stories_outlined,
          value: smarts,
          color: OmoriColors.dreamIndigo,
          tooltip: 'Smarts',
        ),
        _StatIconItem(
          icon: Icons.local_fire_department_outlined,
          value: ambition,
          color: OmoriColors.redAccent,
          tooltip: 'Ambition',
        ),
      ],
    );
  }
}

class _StatIconItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  final String tooltip;

  const _StatIconItem({
    required this.icon,
    required this.value,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$tooltip: $value%',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: OmoriTheme.hand(
              size: 16,
              color: OmoriColors.mutedInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftChoiceTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SoftChoiceTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmoriColors.pastelLavender.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: OmoriTheme.hand(
              size: 18,
              color: OmoriColors.ink,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}
