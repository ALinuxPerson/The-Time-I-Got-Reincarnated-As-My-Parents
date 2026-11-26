import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../theme/omori_theme.dart';
import '../widgets/sketchy_widgets.dart';
import 'roadmap_screen.dart';

class EndingScreen extends StatefulWidget {
  final int sessionId;

  const EndingScreen({super.key, required this.sessionId});

  @override
  State<EndingScreen> createState() => _EndingScreenState();
}

class _EndingScreenState extends State<EndingScreen> {
  final _aiService = AiService();

  FullRoadmapView? _roadmapView;
  bool _loading = true;
  int _beat = 0; // 0 = who they became, 1 = mirrored death, 2 = moral lesson
  bool _beatTextDone = false;

  @override
  void initState() {
    super.initState();
    _generateOrLoadEnding();
  }

  Future<void> _generateOrLoadEnding() async {
    final db = DatabaseHelper.instance;
    final existing = await db.getFullRoadmap(widget.sessionId);
    if (existing != null) {
      if (!mounted) return;
      setState(() {
        _roadmapView = existing;
        _loading = false;
      });
      return;
    }

    final session = await db.getSession(widget.sessionId);
    if (session == null) return;
    final player = await db.getPlayer(session.playerId);
    if (player == null) return;
    final decisions = await db.getDecisionsForSession(widget.sessionId);

    final result = await _aiService.generateStoryRoadmap(
      player: player,
      targetAge: session.targetAge,
      decisions: decisions,
    );

    final events = decisions
        .map(
          (d) => (
            decisionId: d.decision.decisionId!,
            eventSummary:
                result.eventSummariesByDecisionId[d.decision.decisionId!] ??
                d.analysis?.interpretation ??
                'A defining memory at age ${d.decision.ageAtDecision}.',
          ),
        )
        .toList();

    await db.saveStoryRoadmap(
      sessionId: widget.sessionId,
      generatedStory: result.generatedStory,
      endingType: result.endingType,
      moralReflection: result.moralReflection,
      events: events,
    );
    await db.markSessionCompleted(widget.sessionId, session.targetAge);

    final fullView = await db.getFullRoadmap(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _roadmapView = fullView;
      _loading = false;
    });
  }

  void _nextBeat() {
    if (_beat < 2) {
      setState(() {
        _beatTextDone = false;
        _beat++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => RoadmapScreen(sessionId: widget.sessionId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _roadmapView == null) {
      return Scaffold(
        backgroundColor: OmoriColors.whiteSpace,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HangingLightbulb(cordHeight: 40),
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: OmoriColors.ink,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Gathering all the years you raised them...',
                    textAlign: TextAlign.center,
                    style: OmoriTheme.hand(
                      size: 19,
                      color: OmoriColors.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final view = _roadmapView!;
    final dreamAchieved = view.roadmap.dreamAchieved;
    final isDeathBeat = _beat == 1;
    final isMoralBeat = _beat == 2;

    final bgColor = isDeathBeat ? OmoriColors.ink : OmoriColors.whiteSpace;
    final textColor = isDeathBeat ? OmoriColors.paper : OmoriColors.ink;

    final String heading;
    final String body;
    if (_beat == 0) {
      heading = dreamAchieved
          ? 'AGE ${view.session.targetAge} • DREAM ACHIEVED'
          : 'AGE ${view.session.targetAge} • DREAM UNFULFILLED';
      body = view.roadmap.generatedStory;
    } else if (_beat == 1) {
      heading = 'THE RAIN RETURNS';
      body =
          'Then the sky opens up over the exact same crosswalk.\n\n'
          'The pedestrian light flickers. Headlights tear through the rain. Tires scream against wet asphalt.\n\n'
          'You always knew how it would end at age ${view.session.targetAge}. The ending never changed — only how you lived before it arrived.';
    } else {
      heading = 'WHITE SPACE';
      body = view.roadmap.moralReflection;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutSine,
      color: bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 680),
                  switchInCurve: Curves.easeInOutSine,
                  switchOutCurve: Curves.easeInOutSine,
                  child: Column(
                    key: ValueKey('ending_beat_$_beat'),
                    children: [
                if (isMoralBeat)
                  const HangingLightbulb(cordHeight: 48)
                else
                  const SizedBox(height: 40),
                const Spacer(),
                Text(
                  heading,
                  textAlign: TextAlign.center,
                  style: OmoriTheme.pixel(
                    size: 22,
                    color: isDeathBeat
                        ? OmoriColors.redAccent
                        : (dreamAchieved && _beat == 0
                              ? OmoriColors.dreamIndigo
                              : OmoriColors.mutedInk),
                  ),
                ),
                const SizedBox(height: 14),
                if (_beat == 0) ...[
                  SketchImageFrame(
                    assetPath: dreamAchieved
                        ? 'assets/images/ending_dream_achieved.jpg'
                        : 'assets/images/ending_dream_unfulfilled.jpg',
                    borderColor: dreamAchieved
                        ? OmoriColors.dreamIndigo
                        : OmoriColors.ink,
                  ),
                  const SizedBox(height: 16),
                ] else if (isDeathBeat) ...[
                  const SketchImageFrame(
                    assetPath: 'assets/images/crosswalk_rain.jpg',
                    borderColor: OmoriColors.redAccent,
                    showShadow: false,
                  ),
                  const SizedBox(height: 16),
                ],
                SketchBox(
                  fillColor: isDeathBeat
                      ? OmoriColors.ink
                      : OmoriColors.paper,
                  borderColor: isDeathBeat
                      ? OmoriColors.redAccent
                      : (dreamAchieved && _beat == 0
                            ? OmoriColors.dreamIndigo
                            : OmoriColors.ink),
                  showShadow: !isDeathBeat,
                  padding: const EdgeInsets.all(20),
                  child: TypewriterText(
                    key: ValueKey(_beat),
                    text: body,
                    style: OmoriTheme.hand(
                      size: 19,
                      color: textColor,
                      height: 1.45,
                    ),
                    onCompleted: () {
                      if (mounted) setState(() => _beatTextDone = true);
                    },
                  ),
                ),
                const Spacer(),
                GradualReveal(
                  visible: _beatTextDone,
                  delay: const Duration(milliseconds: 220),
                  child: SketchButton(
                    label: isMoralBeat
                        ? 'Open Memory Timeline'
                        : 'Continue',
                    inverted: !isDeathBeat,
                    accentColor: isDeathBeat
                        ? OmoriColors.redAccent
                        : OmoriColors.ink,
                    onPressed: _nextBeat,
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
    );
  }
}
