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
      appBar: AppBar(title: Text('MEMORIES', style: OmoriTheme.pixel())),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(view.player.name, style: OmoriTheme.hand(size: 28)),
                const SizedBox(height: 8),
                Text(
                  achieved ? 'DREAM ACHIEVED' : 'DREAM UNFULFILLED',
                  style: OmoriTheme.pixel(size: 16),
                ),
                const SizedBox(height: 16),
                Text(view.roadmap.generatedStory, style: OmoriTheme.hand()),
                const SizedBox(height: 16),
                Text(view.roadmap.moralReflection, style: OmoriTheme.hand()),
                const SizedBox(height: 24),
                SketchButton(
                  label: _showStats ? 'Hide final stats' : 'Final stats',
                  onPressed: () => setState(() => _showStats = !_showStats),
                ),
                if (_showStats)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: LifeStatsStrip(
                      happiness: view.session.happiness,
                      health: view.session.health,
                      smarts: view.session.smarts,
                      ambition: view.session.ambition,
                    ),
                  ),
                const SizedBox(height: 32),
                for (final item in view.events) ...[
                  Text(
                    'AGE ${item.decisionDetails.decision.ageAtDecision} YEARS',
                    style: OmoriTheme.pixel(size: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.decisionDetails.scenario.title,
                    style: OmoriTheme.hand(size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.decisionDetails.decision.choiceText,
                    style: OmoriTheme.hand(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.event.eventSummary,
                    style: OmoriTheme.hand(
                      size: 16,
                      color: OmoriColors.mutedInk,
                    ),
                  ),
                  const Divider(height: 40),
                ],
                SketchButton(
                  label: 'New life',
                  inverted: true,
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const OnboardingScreen(),
                    ),
                    (route) => route.isFirst,
                  ),
                ),
                const SizedBox(height: 8),
                SketchButton(
                  label: 'Return to title',
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                    (_) => false,
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
