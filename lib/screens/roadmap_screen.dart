import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/models.dart';
import '../theme/omori_theme.dart';
import '../widgets/sketchy_widgets.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class RoadmapScreen extends StatefulWidget {
  final int sessionId;

  const RoadmapScreen({super.key, required this.sessionId});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  FullRoadmapView? _view;
  bool _loading = true;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance.getFullRoadmap(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _view = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _view == null) {
      return const Scaffold(
        backgroundColor: OmoriColors.whiteSpace,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: OmoriColors.ink,
          ),
        ),
      );
    }

    final view = _view!;
    final achieved = view.roadmap.dreamAchieved;

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
        title: Text('MEMORY TIMELINE', style: OmoriTheme.pixel(size: 22)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Summary Photo-Album Cover Card
            SketchBox(
              fillColor: achieved
                  ? OmoriColors.pastelLavender
                  : OmoriColors.warmPaper,
              borderColor: achieved ? OmoriColors.dreamIndigo : OmoriColors.ink,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SketchImageFrame(
                    assetPath: achieved
                        ? 'assets/images/ending_dream_achieved.jpg'
                        : 'assets/images/ending_dream_unfulfilled.jpg',
                    borderColor: achieved
                        ? OmoriColors.dreamIndigo
                        : OmoriColors.ink,
                    showShadow: false,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        color: achieved
                            ? OmoriColors.dreamIndigo
                            : OmoriColors.ink,
                        child: Text(
                          achieved
                              ? 'ENDING A • DREAM ACHIEVED'
                              : 'ENDING B • DREAM UNFULFILLED',
                          style: OmoriTheme.pixel(
                            size: 16,
                            color: OmoriColors.paper,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${view.player.name} • Age 0 to ${view.session.targetAge}',
                    style: OmoriTheme.hand(
                      size: 24,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dream Self: "${view.player.dreamSelfSummary}"',
                    style: OmoriTheme.hand(
                      size: 16,
                      color: OmoriColors.mutedInk,
                    ),
                  ),
                  const Divider(height: 22, color: OmoriColors.ink),
                  GestureDetector(
                    onTap: () => setState(() => _showStats = !_showStats),
                    child: Text(
                      _showStats ? 'FINAL STATS ▴' : 'FINAL STATS ▾',
                      style: OmoriTheme.pixel(
                        size: 16,
                        color: OmoriColors.mutedInk,
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _showStats
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: LifeStatsStrip(
                        happiness: view.session.happiness,
                        health: view.session.health,
                        smarts: view.session.smarts,
                        ambition: view.session.ambition,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    view.roadmap.generatedStory,
                    style: OmoriTheme.hand(size: 18, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: OmoriColors.paper,
                      border: Border.all(color: OmoriColors.ink, width: 1.5),
                    ),
                    child: Text(
                      view.roadmap.moralReflection,
                      style: OmoriTheme.hand(
                        size: 17,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'THE CHOICES THAT SHAPED THEM',
              style: OmoriTheme.pixel(size: 20, color: OmoriColors.mutedInk),
            ),
            const SizedBox(height: 14),

            // Story Events Timeline
            for (int i = 0; i < view.events.length; i++)
              _TimelineEventCard(
                index: i + 1,
                item: view.events[i],
                isLast: i == view.events.length - 1,
              ),

            const SizedBox(height: 24),
            SketchButton(
              label: 'Live Another Life',
              inverted: true,
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const OnboardingScreen(),
                  ),
                  (route) => route.isFirst,
                );
              },
            ),
            const SizedBox(height: 12),
            SketchButton(
              label: 'Return to White Space',
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineEventCard extends StatelessWidget {
  final int index;
  final StoryEventWithDetails item;
  final bool isLast;

  const _TimelineEventCard({
    required this.index,
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final d = item.decisionDetails.decision;
    final s = item.decisionDetails.scenario;
    final a = item.decisionDetails.analysis;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: OmoriColors.ink,
                    border: Border.all(color: OmoriColors.ink, width: 1.5),
                  ),
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: OmoriTheme.pixel(
                      size: 16,
                      color: OmoriColors.paper,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: OmoriColors.ink,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: SketchBox(
                showShadow: false,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AGE ${d.ageAtDecision} • ${s.ageStage.toUpperCase()} • ${s.theme.toUpperCase()}',
                      style: OmoriTheme.pixel(
                        size: 15,
                        color: OmoriColors.mutedInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.title,
                      style: OmoriTheme.hand(
                        size: 20,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your choice: "${d.choiceText}"',
                      style: OmoriTheme.hand(
                        size: 16,
                        color: OmoriColors.mutedInk,
                      ),
                    ),
                    if (a != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        a.childReaction,
                        style: OmoriTheme.hand(size: 16),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      color: OmoriColors.warmPaper,
                      child: Text(
                        item.event.eventSummary,
                        style: OmoriTheme.hand(
                          size: 16,
                          color: OmoriColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
