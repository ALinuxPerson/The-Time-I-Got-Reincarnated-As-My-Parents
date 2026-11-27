import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/sound_service.dart';
import '../theme/omori_theme.dart';
import '../widgets/sketchy_widgets.dart';

/// Simplified Road-to-Empress-inspired horizontal story map in OMORI x Stardew style.
/// Accessible anytime during a run via the map icon.
class LiveRoadmapScreen extends StatefulWidget {
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
  State<LiveRoadmapScreen> createState() => _LiveRoadmapScreenState();
}

enum _RoadmapStyle {
  storyMap('Story Map'),
  lifeBoard('Life Board'),
  memoryJournal('Memory Journal');

  const _RoadmapStyle(this.label);

  final String label;
}

class _LiveRoadmapScreenState extends State<LiveRoadmapScreen> {
  int? _selectedDecisionIndex;
  _RoadmapStyle _style = _RoadmapStyle.storyMap;

  @override
  void initState() {
    super.initState();
    if (widget.decisions.isNotEmpty) {
      _selectedDecisionIndex = widget.decisions.length - 1;
    }
  }

  void _previewDecision(int index) {
    SoundService.playUi(UiSound.select);
    setState(() => _selectedDecisionIndex = index);
  }

  String _portraitForStage(String ageStage, {String mood = 'neutral'}) =>
      characterPortraitAssetForStage(ageStage, mood);

  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.scenarios.length;
    final completedCount = widget.decisions.length;

    const double stepSpacing = 250;
    const double startX = 110;
    const double centerY = 230;
    const double canvasHeight = 460;
    final double canvasWidth = startX + (totalSteps + 1) * stepSpacing + 180;

    final cards = <_MilestoneCardNode>[];
    final dots = <_BranchDotNode>[];
    final paths = <_FlowPath>[];

    // 1. Birth origin card
    final birthPos = const Offset(startX, centerY);
    cards.add(
      _MilestoneCardNode(
        id: 'birth',
        center: birthPos,
        title: 'Birth',
        subtitle: 'age 0',
        assetPath: characterPortraitAssetForStage('Infancy', 'neutral'),
        state: _CardState.completed,
      ),
    );

    Offset prevPos = birthPos;

    // 2. Flowing milestones + Road-to-Empress decision dots & unchosen branches
    for (int i = 0; i < totalSteps; i++) {
      final scenario = widget.scenarios[i];
      final age = i < widget.milestoneAges.length
          ? widget.milestoneAges[i]
          : scenario.minAge;
      final isDone = i < completedCount;
      final isCurrent = i == completedCount;
      final portraitMood = isDone && i < widget.decisions.length
          ? widget.decisions[i].analysis?.mood ?? 'neutral'
          : 'neutral';

      final x = startX + (i + 1) * stepSpacing;
      final yOffset = (i % 2 == 0) ? -48.0 : 48.0;
      final cardPos = Offset(x, centerY + yOffset);

      // Midpoint decision dot along the active path
      final midX = (prevPos.dx + cardPos.dx) / 2;
      final activeDotPos = Offset(midX, cardPos.dy);

      paths.add(
        _FlowPath(
          from: prevPos,
          to: cardPos,
          active: isDone || isCurrent,
        ),
      );

      if (isDone) {
        dots.add(
          _BranchDotNode(
            center: activeDotPos,
            filled: true,
            decisionIndex: i,
          ),
        );

        // Two subtle unchosen sibling branch threads trailing off with hollow dots
        final altDir = yOffset < 0 ? 1.0 : -1.0;
        final altEnd1 = Offset(midX + 46, prevPos.dy + altDir * 86);
        final altEnd2 = Offset(midX + 18, prevPos.dy + altDir * 124);

        paths.add(_FlowPath(from: prevPos, to: altEnd1, active: false));
        dots.add(_BranchDotNode(center: altEnd1, filled: false));

        paths.add(_FlowPath(from: prevPos, to: altEnd2, active: false));
        dots.add(_BranchDotNode(center: altEnd2, filled: false));
      } else if (isCurrent) {
        dots.add(
          _BranchDotNode(
            center: activeDotPos,
            filled: false,
            highlighted: true,
          ),
        );
      }

      cards.add(
        _MilestoneCardNode(
          id: 'step_$i',
          center: cardPos,
          title: isDone || isCurrent ? scenario.title : '???',
          subtitle: 'age $age',
          assetPath: _portraitForStage(scenario.ageStage, mood: portraitMood),
          state: isDone
              ? _CardState.completed
              : (isCurrent ? _CardState.current : _CardState.locked),
          decisionIndex: isDone ? i : null,
        ),
      );

      prevPos = cardPos;
    }

    // 3. Final Crosswalk / Target Age card
    final endX = startX + (totalSteps + 1) * stepSpacing;
    final endPos = Offset(endX, centerY);
    paths.add(
      _FlowPath(
        from: prevPos,
        to: endPos,
        active: completedCount >= totalSteps,
      ),
    );
    cards.add(
      _MilestoneCardNode(
        id: 'ending',
        center: endPos,
        title: 'The Rain',
        subtitle: 'age ${widget.session.targetAge}',
        assetPath: 'assets/images/crosswalk_rain.jpg',
        state: completedCount >= totalSteps
            ? _CardState.completed
            : _CardState.endingLocked,
      ),
    );

    final selectedDecision =
        (_selectedDecisionIndex != null &&
            _selectedDecisionIndex! < widget.decisions.length)
        ? widget.decisions[_selectedDecisionIndex!]
        : null;

    return Scaffold(
      backgroundColor: OmoriColors.whiteSpace,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 12, 4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 550;
                  final toggle = _RoadmapStyleToggle(
                    style: _style,
                    onChanged: (next) => setState(() => _style = next),
                  );
                  final header = Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.player.name}’s path',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: OmoriTheme.hand(
                            size: 20,
                            color: OmoriColors.mutedInk,
                          ),
                        ),
                      ),
                      if (!compact) Flexible(flex: 2, child: toggle),
                      IconButton(
                        tooltip: 'Close roadmap',
                        icon: const Icon(
                          Icons.close_rounded,
                          color: OmoriColors.mutedInk,
                          size: 20,
                        ),
                        onPressed: SoundService.withUiSound(
                          UiSound.back,
                          () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [header, if (compact) toggle],
                  );
                },
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeInOutSine,
                switchOutCurve: Curves.easeInOutSine,
                child: _style == _RoadmapStyle.storyMap
                    ? InteractiveViewer(
                        key: const ValueKey('roadmap_story_map'),
                        constrained: false,
                        boundaryMargin: const EdgeInsets.all(100),
                        minScale: 0.6,
                        maxScale: 1.8,
                        child: SizedBox(
                          width: canvasWidth,
                          height: canvasHeight,
                          child: Stack(
                            children: [
                              // Soft floating stardust + curved branching threads
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _StoryMapPainter(paths: paths),
                                ),
                              ),

                              // Small decision dots along the paths
                              for (final dot in dots)
                                Positioned(
                                  left: dot.center.dx - 11,
                                  top: dot.center.dy - 11,
                                  width: 22,
                                  height: 22,
                                  child: GestureDetector(
                                    onTap: dot.decisionIndex != null
                                        ? () => _previewDecision(
                                            dot.decisionIndex!,
                                          )
                                        : null,
                                    child: Center(
                                      child: Container(
                                        width: dot.filled || dot.highlighted
                                            ? 11
                                            : 8,
                                        height: dot.filled || dot.highlighted
                                            ? 11
                                            : 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: dot.filled
                                              ? (dot.decisionIndex ==
                                                        _selectedDecisionIndex
                                                    ? OmoriColors.dreamIndigo
                                                    : OmoriColors.ink)
                                              : OmoriColors.whiteSpace,
                                          border: Border.all(
                                            color: dot.highlighted
                                                ? OmoriColors.dreamIndigo
                                                : (dot.filled
                                                      ? OmoriColors.ink
                                                      : OmoriColors.ink
                                                            .withValues(
                                                              alpha: 0.28,
                                                            )),
                                            width: 1.6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Illustrated milestone cards
                              for (final card in cards)
                                Positioned(
                                  left: card.center.dx - 66,
                                  top: card.center.dy - 50,
                                  width: 132,
                                  child: _MilestoneCardWidget(
                                    node: card,
                                    selected:
                                        card.decisionIndex != null &&
                                        card.decisionIndex ==
                                            _selectedDecisionIndex,
                                    onTap: card.decisionIndex != null
                                        ? () => _previewDecision(
                                            card.decisionIndex!,
                                          )
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    : _style == _RoadmapStyle.lifeBoard
                    ? _GameOfLifeBoardView(
                        key: const ValueKey('roadmap_life_board'),
                        player: widget.player,
                        scenarios: widget.scenarios,
                        milestoneAges: widget.milestoneAges,
                        decisions: widget.decisions,
                        targetAge: widget.session.targetAge,
                        selectedDecisionIndex: _selectedDecisionIndex,
                        onSelectDecision: (idx) =>
                            setState(() => _selectedDecisionIndex = idx),
                      )
                    : _MemoryJournalView(
                        key: const ValueKey('roadmap_memory_journal'),
                        player: widget.player,
                        decisions: widget.decisions,
                        hasRemainingMilestones: completedCount < totalSteps,
                      ),
              ),
            ),

            // Soft borderless memory preview for the tapped node (Story Map only;
            // Life Board opens a full detail popup when you tap any shape).
            if (_style == _RoadmapStyle.storyMap)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: selectedDecision == null
                      ? Text(
                          'drag to pan • tap any memory card to revisit your choice',
                          textAlign: TextAlign.center,
                          style: OmoriTheme.hand(
                            size: 16,
                            color: OmoriColors.mutedInk,
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: OmoriColors.pastelLavender.withValues(
                              alpha: 0.55,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'age ${selectedDecision.decision.ageAtDecision} — ${selectedDecision.scenario.title}',
                                style: OmoriTheme.hand(
                                  size: 19,
                                  weight: FontWeight.w600,
                                  color: OmoriColors.ink,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '“${selectedDecision.decision.choiceText}”',
                                style: OmoriTheme.hand(
                                  size: 17,
                                  color: OmoriColors.dreamIndigo,
                                ),
                              ),
                              if (selectedDecision.analysis != null) ...[
                                const SizedBox(height: 5),
                                Text(
                                  selectedDecision.analysis!.childReaction,
                                  style: OmoriTheme.hand(
                                    size: 16,
                                    color: OmoriColors.mutedInk,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _CardState { completed, current, locked, endingLocked }

class _MilestoneCardNode {
  final String id;
  final Offset center;
  final String title;
  final String subtitle;
  final String assetPath;
  final _CardState state;
  final int? decisionIndex;

  const _MilestoneCardNode({
    required this.id,
    required this.center,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.state,
    this.decisionIndex,
  });
}

class _BranchDotNode {
  final Offset center;
  final bool filled;
  final bool highlighted;
  final int? decisionIndex;

  const _BranchDotNode({
    required this.center,
    required this.filled,
    this.highlighted = false,
    this.decisionIndex,
  });
}

class _FlowPath {
  final Offset from;
  final Offset to;
  final bool active;

  const _FlowPath({
    required this.from,
    required this.to,
    required this.active,
  });
}

class _StoryMapPainter extends CustomPainter {
  final List<_FlowPath> paths;

  const _StoryMapPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle floating Headspace/Stardew dust motes
    final rng = math.Random(42);
    for (int i = 0; i < 36; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      final r = 1.0 + rng.nextDouble() * 1.8;
      canvas.drawCircle(
        Offset(dx, dy),
        r,
        Paint()..color = OmoriColors.dreamIndigo.withValues(alpha: 0.12),
      );
    }

    // Smooth curved horizontal step-bends (Road to Empress inspired, minimal)
    for (final p in paths) {
      final paint = Paint()
        ..color = p.active
            ? OmoriColors.ink.withValues(alpha: 0.55)
            : OmoriColors.ink.withValues(alpha: 0.16)
        ..strokeWidth = p.active ? 2.0 : 1.3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final midX = p.from.dx + (p.to.dx - p.from.dx) * 0.45;
      final curve = Path()
        ..moveTo(p.from.dx, p.from.dy)
        ..cubicTo(
          midX,
          p.from.dy,
          midX,
          p.to.dy,
          p.to.dx,
          p.to.dy,
        );
      canvas.drawPath(curve, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StoryMapPainter oldDelegate) =>
      oldDelegate.paths != paths;
}

class _MilestoneCardWidget extends StatelessWidget {
  final _MilestoneCardNode node;
  final bool selected;
  final VoidCallback? onTap;

  const _MilestoneCardWidget({
    required this.node,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = node.state == _CardState.locked;
    final isEndingLocked = node.state == _CardState.endingLocked;
    final isCurrent = node.state == _CardState.current;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isLocked ? 0.38 : (isEndingLocked ? 0.65 : 1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 112,
              height: 70,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: OmoriColors.warmPaper,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? OmoriColors.dreamIndigo.withValues(alpha: 0.28)
                        : (isCurrent
                              ? OmoriColors.dreamIndigo.withValues(alpha: 0.18)
                              : Colors.black.withValues(alpha: 0.08)),
                    blurRadius: selected ? 14 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: isLocked
                  ? Center(
                      child: Text(
                        '?',
                        style: OmoriTheme.hand(
                          size: 24,
                          color: OmoriColors.mutedInk,
                        ),
                      ),
                    )
                  : ArtworkImage(
                      assetPath: node.assetPath,
                      fit: BoxFit.cover,
                      fallbackBuilder: (_) => Container(
                        color: OmoriColors.pastelLavender,
                        alignment: Alignment.center,
                        child: Text(
                          node.subtitle,
                          style: OmoriTheme.hand(
                            size: 14,
                            color: OmoriColors.mutedInk,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              node.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: OmoriTheme.hand(
                size: 15,
                weight: selected || isCurrent
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected || isCurrent
                    ? OmoriColors.dreamIndigo
                    : (isEndingLocked
                          ? OmoriColors.redAccent
                          : OmoriColors.ink),
              ),
            ),
            Text(
              node.subtitle,
              style: OmoriTheme.hand(
                size: 13,
                color: OmoriColors.mutedInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadmapStyleToggle extends StatelessWidget {
  final _RoadmapStyle style;
  final ValueChanged<_RoadmapStyle> onChanged;

  const _RoadmapStyleToggle({required this.style, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: OmoriColors.pastelLavender.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          for (final option in _RoadmapStyle.values)
            _ToggleChip(
              label: option.label,
              active: style == option,
              onTap: () {
                if (style == option) return;
                SoundService.playUi(UiSound.select);
                onChanged(option);
              },
            ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(8));

    return Semantics(
      button: true,
      selected: active,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: active ? OmoriColors.dreamIndigo : Colors.transparent,
              borderRadius: radius,
            ),
            child: Text(
              label,
              style: OmoriTheme.hand(
                size: 14,
                weight: FontWeight.w700,
                color: active ? OmoriColors.paper : OmoriColors.mutedInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryJournalView extends StatelessWidget {
  final Player player;
  final List<DecisionWithDetails> decisions;
  final bool hasRemainingMilestones;

  const _MemoryJournalView({
    super.key,
    required this.player,
    required this.decisions,
    required this.hasRemainingMilestones,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          key: const PageStorageKey('memory_journal_scroll'),
          padding: const EdgeInsets.all(24),
          children: [
            Text(player.name, style: OmoriTheme.hand(size: 28)),
            const SizedBox(height: 8),
            Text(player.dreamSelfSummary, style: OmoriTheme.hand()),
            const SizedBox(height: 32),
            if (decisions.isEmpty)
              Text(
                'Your first memory is still ahead.',
                style: OmoriTheme.hand(color: OmoriColors.mutedInk),
              ),
            for (final entry in decisions) ...[
              Text(
                'AGE ${entry.decision.ageAtDecision} YEARS',
                style: OmoriTheme.pixel(size: 16),
              ),
              const SizedBox(height: 8),
              SketchBox(
                showShadow: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.scenario.title,
                      style: OmoriTheme.hand(size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text(entry.decision.choiceText, style: OmoriTheme.hand()),
                    if (entry.analysis case final analysis?) ...[
                      const SizedBox(height: 12),
                      Text(analysis.childReaction, style: OmoriTheme.hand()),
                      const SizedBox(height: 12),
                      Text(
                        analysis.interpretation,
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
            if (decisions.isNotEmpty)
              Text(
                hasRemainingMilestones
                    ? 'The rest is unwritten.'
                    : 'All the years you remember.',
                style: OmoriTheme.hand(size: 16, color: OmoriColors.mutedInk),
              ),
          ],
        ),
      ),
    );
  }
}

/// Game-of-Life-inspired winding colorful ribbon path with yellow Start/Finish
/// medallions, blue/pink/green curved tile segments, and black numbered badges.
/// Zoomed in and freely pannable; tapping any shape opens a rich detail popup.
class _GameOfLifeBoardView extends StatefulWidget {
  final Player player;
  final List<Scenario> scenarios;
  final List<int> milestoneAges;
  final List<DecisionWithDetails> decisions;
  final int targetAge;
  final int? selectedDecisionIndex;
  final ValueChanged<int> onSelectDecision;

  const _GameOfLifeBoardView({
    super.key,
    required this.player,
    required this.scenarios,
    required this.milestoneAges,
    required this.decisions,
    required this.targetAge,
    required this.selectedDecisionIndex,
    required this.onSelectDecision,
  });

  @override
  State<_GameOfLifeBoardView> createState() => _GameOfLifeBoardViewState();
}

class _GameOfLifeBoardViewState extends State<_GameOfLifeBoardView> {
  static const Color _tileBlue = Color(0xFF29C5F6);
  static const Color _tilePink = Color(0xFFF7A6C4);
  static const Color _tileGreen = Color(0xFF22C07A);
  static const Color _tileLocked = Color(0xFFE7ECF2);
  static const Color _medallionYellow = Color(0xFFFFC107);

  static const double _boardWidth = 640;
  static const double _boardHeight = 860;
  static const double _ribbonWidth = 74;
  static const double _medallionSize = 96;

  final TransformationController _transformController =
      TransformationController();
  bool _initializedTransform = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Path _buildWindingPath() {
    const double left = _boardWidth * 0.16;
    const double right = _boardWidth * 0.84;
    const double row1Y = _boardHeight * 0.13;
    const double row2Y = _boardHeight * 0.42;
    const double row3Y = _boardHeight * 0.71;
    const double row4Y = _boardHeight * 0.90;

    return Path()
      ..moveTo(left, row1Y)
      ..cubicTo(
        _boardWidth * 0.42,
        row1Y + 48,
        _boardWidth * 0.64,
        row1Y - 48,
        right,
        row1Y + 14,
      )
      ..cubicTo(
        _boardWidth * 0.97,
        row1Y + 74,
        _boardWidth * 0.95,
        row2Y - 62,
        right - 22,
        row2Y,
      )
      ..cubicTo(
        _boardWidth * 0.62,
        row2Y + 50,
        _boardWidth * 0.38,
        row2Y - 50,
        left,
        row2Y + 10,
      )
      ..cubicTo(
        _boardWidth * 0.03,
        row2Y + 70,
        _boardWidth * 0.05,
        row3Y - 62,
        left + 20,
        row3Y,
      )
      ..cubicTo(
        _boardWidth * 0.42,
        row3Y - 48,
        _boardWidth * 0.66,
        row3Y + 48,
        right - 10,
        row3Y + 12,
      )
      ..cubicTo(
        _boardWidth * 0.96,
        row3Y + 62,
        _boardWidth * 0.94,
        row4Y - 36,
        right - 14,
        row4Y,
      );
  }

  Path _buildTilePolygon(PathMetric metric, double d0, double d1) {
    const halfW = _ribbonWidth * 0.5;
    const samples = 22;
    final leftPts = <Offset>[];
    final rightPts = <Offset>[];

    for (int s = 0; s <= samples; s++) {
      final d = d0 + (d1 - d0) * (s / samples);
      final t = metric.getTangentForOffset(d);
      if (t == null) continue;
      final nx = -t.vector.dy;
      final ny = t.vector.dx;
      leftPts.add(
        Offset(t.position.dx + nx * halfW, t.position.dy + ny * halfW),
      );
      rightPts.add(
        Offset(t.position.dx - nx * halfW, t.position.dy - ny * halfW),
      );
    }

    final poly = Path();
    if (leftPts.length < 2) return poly;
    poly.moveTo(leftPts.first.dx, leftPts.first.dy);
    for (int i = 1; i < leftPts.length; i++) {
      poly.lineTo(leftPts[i].dx, leftPts[i].dy);
    }
    for (int i = rightPts.length - 1; i >= 0; i--) {
      poly.lineTo(rightPts[i].dx, rightPts[i].dy);
    }
    poly.close();
    return poly;
  }

  String _portraitForStage(String ageStage, {String mood = 'neutral'}) =>
      characterPortraitAssetForStage(ageStage, mood);

  Widget _buildDetailBanner({
    required String backgroundAsset,
    String? portraitAsset,
    String? fullBleedAsset,
    bool locked = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        height: 146,
        child: fullBleedAsset != null
            ? Image.asset(
                fullBleedAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: OmoriColors.pastelLavender),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ArtworkImage(
                    assetPath: backgroundAsset,
                    fit: BoxFit.cover,
                    fallbackBuilder: (_) =>
                        Container(color: OmoriColors.pastelLavender),
                  ),
                  if (locked)
                    Container(
                      color: OmoriColors.whiteSpace.withValues(alpha: 0.65),
                      alignment: Alignment.center,
                      child: Text(
                        '?',
                        style: OmoriTheme.hand(
                          size: 38,
                          weight: FontWeight.w700,
                          color: OmoriColors.mutedInk,
                        ),
                      ),
                    )
                  else if (portraitAsset != null)
                    Center(
                      child: Container(
                        width: 106,
                        height: 106,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: OmoriColors.paper,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: ArtworkImage(
                            assetPath: portraitAsset,
                            fit: BoxFit.cover,
                            fallbackBuilder: (_) =>
                                Container(color: OmoriColors.warmPaper),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  void _showTileDetailDialog(_BoardTileData tile) {
    SoundService.playUi(tile.isDone ? UiSound.memory : UiSound.select);
    if (tile.isDone) {
      widget.onSelectDecision(tile.index);
    }
    final decision =
        tile.isDone && tile.index < widget.decisions.length
        ? widget.decisions[tile.index]
        : null;
    final scenario = widget.scenarios[tile.index];
    final mood = decision?.analysis?.mood ?? 'neutral';
    final backgroundAsset = WindowSceneBackground.backgroundAsset;
    final portraitAsset = _portraitForStage(
      scenario.ageStage,
      mood: tile.isDone || tile.isCurrent ? mood : 'neutral',
    );

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: OmoriColors.paper,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: tile.isDone || tile.isCurrent
                    ? tile.color
                    : OmoriColors.subtleLine,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tile.isDone || tile.isCurrent
                              ? OmoriColors.ink
                              : OmoriColors.mutedInk,
                        ),
                        child: Text(
                          '${tile.index + 1}',
                          style: OmoriTheme.hand(
                            size: 14,
                            weight: FontWeight.w700,
                            color: OmoriColors.paper,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tile.isDone || tile.isCurrent
                              ? '${tile.ageLabel} — ${scenario.title}'
                              : '${tile.ageLabel} — Upcoming Moment',
                          style: OmoriTheme.hand(
                            size: 20,
                            weight: FontWeight.w700,
                            color: OmoriColors.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: OmoriColors.mutedInk,
                        ),
                        onPressed: SoundService.withUiSound(
                          UiSound.back,
                          () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailBanner(
                    backgroundAsset: backgroundAsset,
                    portraitAsset: portraitAsset,
                    locked: !tile.isDone && !tile.isCurrent,
                  ),
                  const SizedBox(height: 14),
                  if (decision != null) ...[
                    Text(
                      scenario.description,
                      style: OmoriTheme.hand(
                        size: 16,
                        color: OmoriColors.mutedInk,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: OmoriColors.pastelLavender.withValues(
                          alpha: 0.7,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '“${decision.decision.choiceText}”',
                        style: OmoriTheme.hand(
                          size: 17,
                          weight: FontWeight.w700,
                          color: OmoriColors.dreamIndigo,
                        ),
                      ),
                    ),
                    if (decision.analysis != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        decision.analysis!.childReaction,
                        style: OmoriTheme.hand(
                          size: 16,
                          color: OmoriColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        decision.analysis!.interpretation,
                        style: OmoriTheme.hand(
                          size: 15,
                          color: OmoriColors.mutedInk,
                        ),
                      ),
                      const SizedBox(height: 10),
                      StatDeltaChips(
                        happinessDelta: decision.analysis!.happinessDelta,
                        healthDelta: decision.analysis!.healthDelta,
                        smartsDelta: decision.analysis!.smartsDelta,
                        ambitionDelta: decision.analysis!.ambitionDelta,
                      ),
                    ],
                  ] else if (tile.isCurrent) ...[
                    Text(
                      scenario.description,
                      style: OmoriTheme.hand(size: 17, color: OmoriColors.ink),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Currently unfolding — return to the main screen to choose.',
                      style: OmoriTheme.hand(
                        size: 15,
                        color: OmoriColors.dreamIndigo,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'This moment has not arrived yet. Keep living forward to uncover what happens at ${tile.ageLabel}.',
                      style: OmoriTheme.hand(
                        size: 16,
                        color: OmoriColors.mutedInk,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMedallionDialog({required bool isStart}) {
    SoundService.playUi(UiSound.memory);
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: OmoriColors.paper,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _medallionYellow, width: 3),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isStart
                              ? 'Birth — ${widget.player.name}'
                              : 'The Rain — Age ${widget.targetAge}',
                          style: OmoriTheme.hand(
                            size: 21,
                            weight: FontWeight.w700,
                            color: OmoriColors.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: OmoriColors.mutedInk,
                        ),
                        onPressed: SoundService.withUiSound(
                          UiSound.back,
                          () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailBanner(
                    backgroundAsset: WindowSceneBackground.backgroundAsset,
                    portraitAsset: isStart
                        ? characterPortraitAssetForStage('Infancy', 'neutral')
                        : null,
                    fullBleedAsset: isStart
                        ? null
                        : 'assets/images/crosswalk_rain.jpg',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isStart
                        ? 'Reborn as your own parents to raise ${widget.player.name} from age 0.\n\nDream self: “${widget.player.dreamSelfSummary}”'
                        : 'At age ${widget.targetAge}, the rainy crosswalk arrives once more. Every choice along this board shapes who ${widget.player.name} has become by that moment.',
                    style: OmoriTheme.hand(
                      size: 16,
                      color: OmoriColors.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.scenarios.length;
    final completedCount = widget.decisions.length;

    final path = _buildWindingPath();
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return const SizedBox.shrink();
    final metric = metrics.first;
    final totalLen = metric.length;

    const double startPad = 56;
    const double endPad = 56;
    final usableLen = math.max(totalLen - startPad - endPad, 1.0);
    final tileCount = math.max(totalSteps, 1);
    final segLen = usableLen / tileCount;

    final tiles = <_BoardTileData>[];
    for (int i = 0; i < totalSteps; i++) {
      final d0 = startPad + i * segLen;
      final d1 = startPad + (i + 1) * segLen;
      final dMid = (d0 + d1) * 0.5;
      final tangent = metric.getTangentForOffset(dMid);
      if (tangent == null) continue;

      final isDone = i < completedCount;
      final isCurrent = i == completedCount;
      final isCrossroad = i % 3 == 2;
      final Color fill;
      if (!isDone && !isCurrent) {
        fill = _tileLocked;
      } else if (isCrossroad) {
        fill = _tileGreen;
      } else if (i.isEven) {
        fill = _tileBlue;
      } else {
        fill = _tilePink;
      }

      final scenario = widget.scenarios[i];
      final age = i < widget.milestoneAges.length
          ? widget.milestoneAges[i]
          : scenario.minAge;

      final u = tangent.vector;
      final normal = i.isEven ? Offset(-u.dy, u.dx) : Offset(u.dy, -u.dx);
      final badgePos = tangent.position + normal * (_ribbonWidth * 0.5 + 4);
      final screenAngle = math.atan2(u.dy, u.dx);
      final polygon = _buildTilePolygon(metric, d0 + 2.5, d1 - 2.5);

      tiles.add(
        _BoardTileData(
          index: i,
          startDist: d0,
          endDist: d1,
          center: tangent.position,
          angle: screenAngle,
          badgePos: badgePos,
          polygon: polygon,
          title: isDone || isCurrent ? scenario.title : '???',
          ageLabel: 'age $age',
          color: fill,
          isDone: isDone,
          isCurrent: isCurrent,
          isCrossroad: isCrossroad,
          isSelected: isDone && widget.selectedDecisionIndex == i,
        ),
      );
    }

    final startPos =
        metric.getTangentForOffset(14)?.position ?? const Offset(102, 112);
    final endPos =
        metric.getTangentForOffset(totalLen - 14)?.position ??
        const Offset(525, 770);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_initializedTransform &&
            constraints.maxWidth > 0 &&
            constraints.maxHeight > 0) {
          _initializedTransform = true;
          // Open nicely zoomed in, focused on the current/latest milestone.
          final initialScale = constraints.maxWidth >= 820 ? 1.45 : 1.12;
          final focusIdx = completedCount
              .clamp(0, math.max(tiles.length - 1, 0))
              .toInt();
          final focus = tiles.isNotEmpty ? tiles[focusIdx].center : startPos;
          final tx = constraints.maxWidth * 0.5 - focus.dx * initialScale;
          final ty = constraints.maxHeight * 0.45 - focus.dy * initialScale;
          _transformController.value = Matrix4.identity()
            ..setEntry(0, 3, tx)
            ..setEntry(1, 3, ty)
            ..setEntry(0, 0, initialScale)
            ..setEntry(1, 1, initialScale);
        }

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(280),
              minScale: 0.65,
              maxScale: 2.6,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) {
                  final pos = details.localPosition;
                  for (final tile in tiles) {
                    if (tile.polygon.contains(pos)) {
                      _showTileDetailDialog(tile);
                      return;
                    }
                  }
                },
                child: SizedBox(
                  width: _boardWidth,
                  height: _boardHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Smooth curved colorful ribbon tiles
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GameOfLifeBoardPainter(tiles: tiles),
                        ),
                      ),

                      // 2. Upright-clamped tile labels
                      for (final tile in tiles)
                        Positioned(
                          left: tile.center.dx - 58,
                          top: tile.center.dy - 30,
                          width: 116,
                          height: 60,
                          child: IgnorePointer(
                            child: Transform.rotate(
                              angle: _readableAngle(tile.angle),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        tile.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: OmoriTheme.hand(
                                          size: 12,
                                          weight: FontWeight.w700,
                                          height: 1.05,
                                          color: tile.isDone || tile.isCurrent
                                              ? OmoriColors.ink
                                              : OmoriColors.mutedInk,
                                        ),
                                      ),
                                      Text(
                                        tile.ageLabel,
                                        style: OmoriTheme.hand(
                                          size: 10,
                                          weight: FontWeight.w700,
                                          height: 1.05,
                                          color: OmoriColors.ink.withValues(
                                            alpha: tile.isDone || tile.isCurrent
                                                ? 0.72
                                                : 0.45,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // 3. Black circular numbered milestone badges
                      for (final tile in tiles)
                        Positioned(
                          left: tile.badgePos.dx - 14,
                          top: tile.badgePos.dy - 14,
                          width: 28,
                          height: 28,
                          child: GestureDetector(
                            onTap: () => _showTileDetailDialog(tile),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: tile.isSelected
                                    ? OmoriColors.dreamIndigo
                                    : (tile.isDone || tile.isCurrent
                                          ? OmoriColors.ink
                                          : OmoriColors.mutedInk.withValues(
                                              alpha: 0.55,
                                            )),
                                border: Border.all(
                                  color: OmoriColors.paper,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                '${tile.index + 1}',
                                style: OmoriTheme.hand(
                                  size: 11.5,
                                  weight: FontWeight.w700,
                                  height: 1.0,
                                  color: OmoriColors.paper,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // 4. Yellow circular Start medallion (Birth)
                      Positioned(
                        left: startPos.dx - _medallionSize / 2,
                        top: startPos.dy - _medallionSize / 2,
                        width: _medallionSize,
                        height: _medallionSize,
                        child: GestureDetector(
                          onTap: () => _showMedallionDialog(isStart: true),
                          child: _BoardMedallion(
                            color: _medallionYellow,
                            title: 'Start',
                            subtitle: 'Birth · 0',
                          ),
                        ),
                      ),

                      // 5. Yellow circular Finish medallion (Target Age)
                      Positioned(
                        left: endPos.dx - _medallionSize / 2,
                        top: endPos.dy - _medallionSize / 2,
                        width: _medallionSize,
                        height: _medallionSize,
                        child: GestureDetector(
                          onTap: () => _showMedallionDialog(isStart: false),
                          child: _BoardMedallion(
                            color: _medallionYellow,
                            title: 'The Rain',
                            subtitle: 'Age ${widget.targetAge}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Quiet floating hint pill at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: OmoriColors.paper.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'drag to pan • pinch/scroll to zoom • click any tile for details',
                      style: OmoriTheme.hand(
                        size: 14,
                        color: OmoriColors.mutedInk,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Keeps rotated text upright even when the winding path runs right-to-left.
  double _readableAngle(double rawAngle) {
    var a = rawAngle;
    while (a > math.pi / 2) {
      a -= math.pi;
    }
    while (a < -math.pi / 2) {
      a += math.pi;
    }
    return a * 0.72;
  }
}

class _BoardMedallion extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;

  const _BoardMedallion({
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: OmoriTheme.hand(
              size: 14,
              weight: FontWeight.w700,
              height: 1.05,
              color: OmoriColors.ink,
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: OmoriTheme.hand(
              size: 11,
              weight: FontWeight.w700,
              height: 1.1,
              color: OmoriColors.ink.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardTileData {
  final int index;
  final double startDist;
  final double endDist;
  final Offset center;
  final double angle;
  final Offset badgePos;
  final Path polygon;
  final String title;
  final String ageLabel;
  final Color color;
  final bool isDone;
  final bool isCurrent;
  final bool isCrossroad;
  final bool isSelected;

  const _BoardTileData({
    required this.index,
    required this.startDist,
    required this.endDist,
    required this.center,
    required this.angle,
    required this.badgePos,
    required this.polygon,
    required this.title,
    required this.ageLabel,
    required this.color,
    required this.isDone,
    required this.isCurrent,
    required this.isCrossroad,
    required this.isSelected,
  });
}

class _GameOfLifeBoardPainter extends CustomPainter {
  final List<_BoardTileData> tiles;

  const _GameOfLifeBoardPainter({required this.tiles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final tile in tiles) {
      final poly = tile.polygon;

      // Subtle soft drop shadow under the board ribbon
      canvas.drawPath(
        poly.shift(const Offset(0, 3)),
        Paint()..color = Colors.black.withValues(alpha: 0.06),
      );

      // Colored tile fill
      canvas.drawPath(poly, Paint()..color = tile.color);

      // Selected or current tile crisp highlight border
      if (tile.isSelected || tile.isCurrent) {
        canvas.drawPath(
          poly,
          Paint()
            ..color = tile.isSelected
                ? OmoriColors.dreamIndigo
                : OmoriColors.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GameOfLifeBoardPainter oldDelegate) => true;
}
