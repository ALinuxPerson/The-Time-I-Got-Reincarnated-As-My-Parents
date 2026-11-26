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

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          heading,
                          style: OmoriTheme.pixel(color: textColor),
                        ),
                        const SizedBox(height: 24),
                        if (!isMoralBeat) ...[
                          SketchImageFrame(
                            assetPath: isDeathBeat
                                ? 'assets/images/crosswalk_rain.jpg'
                                : dreamAchieved
                                ? 'assets/images/ending_dream_achieved.jpg'
                                : 'assets/images/ending_dream_unfulfilled.jpg',
                            maxHeight: 180,
                            borderColor: textColor,
                          ),
                          const SizedBox(height: 24),
                        ],
                        TypewriterText(
                          key: ValueKey(_beat),
                          text: body,
                          style: OmoriTheme.hand(color: textColor),
                          onCompleted: () {
                            if (mounted) setState(() => _beatTextDone = true);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_beatTextDone)
              Padding(
                padding: const EdgeInsets.all(24),
                child: SketchButton(
                  label: isMoralBeat ? 'Read memories' : 'Continue',
                  onPressed: _nextBeat,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
