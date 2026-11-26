import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/omori_theme.dart';
import '../widgets/sketchy_widgets.dart';

class LiveRoadmapScreen extends StatelessWidget {
  final Player player;
  final GameSession session;
  final List<Scenario> scenarios;
  final List<int> milestoneAges;
  final List<DecisionWithDetails> decisions;

  const LiveRoadmapScreen({
    super.key,
    required this.player,
    required this.session,
    required this.scenarios,
    required this.milestoneAges,
    required this.decisions,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(player.name, style: OmoriTheme.hand(size: 28)),
                const SizedBox(height: 8),
                Text(player.dreamSelfSummary, style: OmoriTheme.hand()),
                const SizedBox(height: 32),
                if (decisions.isEmpty)
                  Text(
                    'Your first memory is still ahead.',
                    style: OmoriTheme.hand(),
                  ),
                for (final beat in decisions) ...[
                  Text(
                    'AGE ${beat.decision.ageAtDecision} YEARS',
                    style: OmoriTheme.pixel(size: 16),
                  ),
                  const SizedBox(height: 8),
                  SketchBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          beat.scenario.title,
                          style: OmoriTheme.hand(size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          beat.decision.choiceText,
                          style: OmoriTheme.hand(),
                        ),
                        if (beat.analysis != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            beat.analysis!.childReaction,
                            style: OmoriTheme.hand(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            beat.analysis!.interpretation,
                            style: OmoriTheme.hand(
                              size: 16,
                              color: OmoriColors.mutedInk,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  decisions.length < scenarios.length
                      ? 'The rest is unwritten.'
                      : 'All the years you remember.',
                  style: OmoriTheme.hand(size: 16, color: OmoriColors.mutedInk),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
