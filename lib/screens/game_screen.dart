import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final _dialogueScroll = ScrollController();

  Player? _player;
  GameSession? _session;
  List<Scenario> _scenarios = [];
  List<int> _milestoneAges = [];
  List<DecisionWithDetails> _decisions = [];

  double _hudScale = 1;
  bool _loading = true;
  bool _submitting = false;
  bool _optionsOpen = false; // Options drop down
  bool _stageTextDone = false;
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
    _dialogueScroll.dispose();
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
      _stageTextDone = false;
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
      _stageTextDone = false;
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

  String _currentMood() {
    final activeMood = _activeReactionBeat?.analysis?.mood;
    if (activeMood != null && activeMood.isNotEmpty) return activeMood;

    if (_decisions.isNotEmpty) {
      final lastMood = _decisions.last.analysis?.mood;
      if (lastMood != null && lastMood.isNotEmpty) return lastMood;
    }

    final happiness = _session?.happiness ?? 50;
    if (happiness >= 68) return 'happy';
    if (happiness <= 34) return 'sad';
    return 'neutral';
  }

  Future<void> _openMenu() async {
    if (_loading || _session == null) return;
    final action = await showDialog<String>(
      context: context,
      barrierColor: OmoriColors.whiteSpace,
      animationStyle: const AnimationStyle(
        duration: OmoriTheme.motion,
        reverseDuration: OmoriTheme.motion,
        curve: OmoriTheme.curve,
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, updateMenu) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SketchBox(
              fillColor: OmoriColors.paper.withValues(alpha: 0.92),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_player!.name, style: OmoriTheme.hand(size: 28)),
                      Text(
                        'Age ${_displayAge()} ${_displayAge() == 1 ? 'year' : 'years'}',
                        style: OmoriTheme.pixel(),
                      ),
                      if (MediaQuery.sizeOf(context).width >= 600) ...[
                        const SizedBox(height: 16),
                        Text(
                          'HUD scale ${(_hudScale * 100).round()}%',
                          style: OmoriTheme.pixel(size: 16),
                        ),
                        Slider(
                          value: _hudScale,
                          min: 0.9,
                          max: 1.3,
                          divisions: 4,
                          label: '${(_hudScale * 100).round()}%',
                          onChanged: (value) {
                            setState(() => _hudScale = value);
                            updateMenu(() {});
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      LifeStatsStrip(
                        happiness: _session!.happiness,
                        health: _session!.health,
                        smarts: _session!.smarts,
                        ambition: _session!.ambition,
                      ),
                      const SizedBox(height: 24),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(0),
                        child: SketchButton(
                          label: 'Resume',
                          inverted: true,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(1),
                        child: SketchButton(
                          label: 'Memories',
                          onPressed: () => Navigator.pop(context, 'memories'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(2),
                        child: SketchButton(
                          label: 'Return to title',
                          onPressed: () => Navigator.pop(context, 'leave'),
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
    if (!mounted) return;
    if (action == 'leave') {
      Navigator.pop(context);
    } else if (action == 'memories') {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LiveRoadmapScreen(
            player: _player!,
            session: _session!,
            scenarios: _scenarios,
            milestoneAges: _milestoneAges,
            decisions: _decisions,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _player == null || _session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          MediaQuery.textScalerOf(context).scale(_hudScale),
        ),
      ),
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _openMenu},
        child: Scaffold(
          body: LayoutBuilder(
            builder: (context, bounds) {
              final compact = bounds.maxWidth < 600;
              return WindowSceneBackground(
                age: _displayAge(),
                mood: _currentMood(),
                child: SafeArea(
                  child: Stack(
                    children: [
                      if (!compact)
                        Positioned(
                          right: 16,
                          top: compact ? null : 16,
                          bottom: compact ? 16 : null,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: SketchButton(
                              key: const ValueKey('game_menu'),
                              label: 'Menu',
                              showPointer: false,
                              padding: EdgeInsets.zero,
                              onPressed: _openMenu,
                            ),
                          ),
                        ),
                      Positioned(
                        left: compact ? 16 : null,
                        right: compact ? 16 : 24,
                        bottom: compact ? 16 : 24,
                        width: compact
                            ? null
                            : (bounds.maxWidth * 0.52)
                                  .clamp(340, 600)
                                  .toDouble(),
                        child: SizedBox(
                          height: bounds.maxHeight * 0.32,
                          child: SketchBox(
                            key: const ValueKey('dialogue_panel'),
                            fillColor: OmoriColors.ink,
                            borderColor: OmoriColors.paper,
                            strokeWidth: 3,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Scrollbar(
                                    controller: _dialogueScroll,
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      controller: _dialogueScroll,
                                      child: AnimatedSwitcher(
                                        duration: OmoriTheme.motion,
                                        switchInCurve: OmoriTheme.curve,
                                        switchOutCurve: OmoriTheme.curve,
                                        child: _submitting
                                            ? Text(
                                                'Thinking...',
                                                style: OmoriTheme.hand(
                                                  color: OmoriColors.paper,
                                                ),
                                              )
                                            : _activeReactionBeat != null
                                            ? _buildReactionBeat(
                                                _activeReactionBeat!,
                                              )
                                            : _hasMoreScenarios
                                            ? _buildScenarioStage(
                                                _scenarios[_nextScenarioIndex],
                                              )
                                            : Text(
                                                'The rain returns.',
                                                style: OmoriTheme.hand(
                                                  color: OmoriColors.paper,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _stageTextDone && !_submitting
                                          ? SketchButton(
                                              label: _activeReactionBeat != null
                                                  ? 'Continue'
                                                  : _optionsOpen
                                                  ? 'Read again'
                                                  : 'What do you do?',
                                              onPressed:
                                                  _activeReactionBeat != null
                                                  ? _continueFromReaction
                                                  : _toggleChoices,
                                            )
                                          : const SizedBox(height: 48),
                                    ),
                                    if (compact) ...[
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: SketchButton(
                                          key: const ValueKey('game_menu'),
                                          label: 'Menu',
                                          showPointer: false,
                                          padding: EdgeInsets.zero,
                                          onPressed: _openMenu,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
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
      ),
    );
  }

  void _toggleChoices() {
    setState(() => _optionsOpen = !_optionsOpen);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dialogueScroll.hasClients) _dialogueScroll.jumpTo(0);
    });
  }

  Widget _buildScenarioStage(Scenario scenario) {
    return FocusTraversalGroup(
      key: ValueKey('scenario_${scenario.scenarioId}_$_optionsOpen'),
      policy: OrderedTraversalPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'AGE ${_displayAge()} ${_displayAge() == 1 ? 'YEAR' : 'YEARS'}',
            style: OmoriTheme.pixel(size: 16, color: OmoriColors.paper),
          ),
          const SizedBox(height: 8),
          if (!_optionsOpen) ...[
            TypewriterText(
              key: ValueKey(scenario.scenarioId),
              text: scenario.description,
              style: OmoriTheme.hand(color: OmoriColors.paper),
              onCompleted: () {
                if (mounted) setState(() => _stageTextDone = true);
              },
            ),
          ] else ...[
            for (int i = 0; i < scenario.presetChoices.length; i++) ...[
              FocusTraversalOrder(
                order: NumericFocusOrder(i.toDouble()),
                child: SketchButton(
                  label: scenario.presetChoices[i],
                  onPressed: () => _submitDecision(scenario.presetChoices[i]),
                ),
              ),
              const SizedBox(height: 8),
            ],
            FocusTraversalOrder(
              order: const NumericFocusOrder(50),
              child: SketchButton(
                label: 'Write your own...',
                onPressed: _writeChoice,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _writeChoice() async {
    final choice = await showDialog<String>(
      context: context,
      barrierColor: OmoriColors.whiteSpace,
      animationStyle: const AnimationStyle(
        duration: OmoriTheme.motion,
        reverseDuration: OmoriTheme.motion,
        curve: OmoriTheme.curve,
      ),
      builder: (context) => Dialog(
        child: SketchBox(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('What do you do?', style: OmoriTheme.hand()),
                const SizedBox(height: 16),
                TextField(
                  controller: _customChoiceController,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 3,
                  style: OmoriTheme.hand(),
                  decoration: const InputDecoration(
                    hintText: 'Say or do something...',
                  ),
                ),
                const SizedBox(height: 16),
                SketchButton(
                  label: 'Respond',
                  onPressed: () {
                    final text = _customChoiceController.text.trim();
                    if (text.isNotEmpty) Navigator.pop(context, text);
                  },
                ),
                const SizedBox(height: 8),
                SketchButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (choice != null && mounted) await _submitDecision(choice);
  }

  Widget _buildReactionBeat(DecisionWithDetails beat) {
    return Column(
      key: ValueKey('reaction_${beat.decision.decisionId}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TypewriterText(
          text: beat.analysis?.childReaction ?? '',
          style: OmoriTheme.hand(color: OmoriColors.paper),
          onCompleted: () {
            if (mounted) setState(() => _stageTextDone = true);
          },
        ),
      ],
    );
  }
}
