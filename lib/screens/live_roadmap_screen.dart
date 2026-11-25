import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/omori_theme.dart';

/// Interactive pan/zoom node-and-arrow decision map accessible anytime during a run.
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

class _LiveRoadmapScreenState extends State<LiveRoadmapScreen> {
  int? _selectedDecisionIndex;

  @override
  void initState() {
    super.initState();
    if (widget.decisions.isNotEmpty) {
      _selectedDecisionIndex = widget.decisions.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.scenarios.length;
    final completedCount = widget.decisions.length;

    // Layout geometry: Birth -> N scenario columns (with choice node + ghost alt) -> Target Age
    const double colWidth = 210;
    const double startX = 90;
    const double centerY = 210;
    const double canvasHeight = 420;
    final double canvasWidth = startX + (totalSteps + 2) * colWidth;

    final nodes = <_MapNode>[];
    final edges = <_MapEdge>[];

    // 1. Birth node
    final birthPos = const Offset(startX, centerY);
    nodes.add(
      _MapNode(
        id: 'birth',
        center: birthPos,
        radiusX: 46,
        radiusY: 32,
        title: 'Age 0',
        subtitle: 'Birth',
        kind: _NodeKind.origin,
      ),
    );

    Offset prevAnchor = birthPos;

    // 2. Milestone nodes & branching choice ovals
    for (int i = 0; i < totalSteps; i++) {
      final scenario = widget.scenarios[i];
      final age = i < widget.milestoneAges.length
          ? widget.milestoneAges[i]
          : scenario.minAge;
      final isDone = i < completedCount;
      final isCurrent = i == completedCount;
      final decision = isDone ? widget.decisions[i] : null;

      final x = startX + (i + 1) * colWidth;
      // Gentle organic wave up/down so the map feels hand-sketched
      final yWave = (i % 2 == 0) ? -28.0 : 28.0;
      final mainPos = Offset(x, centerY + yWave);

      if (isDone && decision != null) {
        // Show one faded "unchosen path" ghost oval branching above/below
        final altY = yWave < 0 ? centerY + 95.0 : centerY - 95.0;
        final altPos = Offset(x - 42, altY);
        nodes.add(
          _MapNode(
            id: 'alt_$i',
            center: altPos,
            radiusX: 36,
            radiusY: 22,
            title: 'other path',
            subtitle: '',
            kind: _NodeKind.unchosen,
          ),
        );
        edges.add(_MapEdge(from: prevAnchor, to: altPos, faint: true));
        edges.add(_MapEdge(from: altPos, to: mainPos, faint: true));

        // Chosen path oval
        nodes.add(
          _MapNode(
            id: 'dec_$i',
            center: mainPos,
            radiusX: 62,
            radiusY: 38,
            title: 'Age $age',
            subtitle: scenario.theme,
            kind: _NodeKind.chosen,
            decisionIndex: i,
          ),
        );
        edges.add(_MapEdge(from: prevAnchor, to: mainPos, faint: false));
      } else if (isCurrent) {
        nodes.add(
          _MapNode(
            id: 'cur_$i',
            center: mainPos,
            radiusX: 58,
            radiusY: 36,
            title: 'Age $age',
            subtitle: 'now',
            kind: _NodeKind.current,
          ),
        );
        edges.add(_MapEdge(from: prevAnchor, to: mainPos, faint: false));
      } else {
        nodes.add(
          _MapNode(
            id: 'fut_$i',
            center: mainPos,
            radiusX: 44,
            radiusY: 28,
            title: 'Age $age',
            subtitle: '?',
            kind: _NodeKind.future,
          ),
        );
        edges.add(_MapEdge(from: prevAnchor, to: mainPos, faint: true));
      }

      prevAnchor = mainPos;
    }

    // 3. Final Crosswalk / Target Age node
    final endX = startX + (totalSteps + 1) * colWidth;
    final endPos = Offset(endX, centerY);
    nodes.add(
      _MapNode(
        id: 'end',
        center: endPos,
        radiusX: 58,
        radiusY: 38,
        title: 'Age ${widget.session.targetAge}',
        subtitle: 'the rain',
        kind: _NodeKind.ending,
      ),
    );
    edges.add(_MapEdge(from: prevAnchor, to: endPos, faint: completedCount < totalSteps));

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
            // Minimal borderless header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  Text(
                    'roadmap • ${widget.player.name}',
                    style: OmoriTheme.hand(
                      size: 19,
                      color: OmoriColors.mutedInk,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close map',
                    icon: const Icon(
                      Icons.close_rounded,
                      color: OmoriColors.mutedInk,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Pan/zoom interactive node-and-arrow canvas
            Expanded(
              child: InteractiveViewer(
                constrained: false,
                boundaryMargin: const EdgeInsets.all(100),
                minScale: 0.65,
                maxScale: 2.0,
                child: SizedBox(
                  width: canvasWidth,
                  height: canvasHeight,
                  child: Stack(
                    children: [
                      // Arrows layer
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RoadmapEdgesPainter(edges: edges),
                        ),
                      ),
                      // Oval nodes layer
                      for (final node in nodes)
                        Positioned(
                          left: node.center.dx - node.radiusX,
                          top: node.center.dy - node.radiusY,
                          width: node.radiusX * 2,
                          height: node.radiusY * 2,
                          child: _OvalNodeWidget(
                            node: node,
                            selected:
                                node.decisionIndex != null &&
                                node.decisionIndex == _selectedDecisionIndex,
                            onTap: node.decisionIndex != null
                                ? () => setState(
                                    () => _selectedDecisionIndex =
                                        node.decisionIndex,
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Soft detail panel for the tapped decision node
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: selectedDecision == null
                    ? Text(
                        'drag to explore your path • tap any completed circle to revisit a choice',
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
                          vertical: 16,
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
                            const SizedBox(height: 6),
                            Text(
                              '“${selectedDecision.decision.choiceText}”',
                              style: OmoriTheme.hand(
                                size: 17,
                                color: OmoriColors.dreamIndigo,
                              ),
                            ),
                            if (selectedDecision.analysis != null) ...[
                              const SizedBox(height: 6),
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

enum _NodeKind { origin, chosen, unchosen, current, future, ending }

class _MapNode {
  final String id;
  final Offset center;
  final double radiusX;
  final double radiusY;
  final String title;
  final String subtitle;
  final _NodeKind kind;
  final int? decisionIndex;

  const _MapNode({
    required this.id,
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.title,
    required this.subtitle,
    required this.kind,
    this.decisionIndex,
  });
}

class _MapEdge {
  final Offset from;
  final Offset to;
  final bool faint;

  const _MapEdge({
    required this.from,
    required this.to,
    required this.faint,
  });
}

class _RoadmapEdgesPainter extends CustomPainter {
  final List<_MapEdge> edges;

  const _RoadmapEdgesPainter({required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final color = edge.faint
          ? OmoriColors.ink.withValues(alpha: 0.16)
          : OmoriColors.ink.withValues(alpha: 0.72);
      final paint = Paint()
        ..color = color
        ..strokeWidth = edge.faint ? 1.4 : 2.1
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final dx = edge.to.dx - edge.from.dx;
      final dy = edge.to.dy - edge.from.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < 1) continue;

      final ux = dx / dist;
      final uy = dy / dist;

      // Trim start and end so arrows sit cleanly outside ovals
      final start = Offset(edge.from.dx + ux * 54, edge.from.dy + uy * 34);
      final end = Offset(edge.to.dx - ux * 60, edge.to.dy - uy * 38);

      canvas.drawLine(start, end, paint);

      // Hand-drawn arrowhead
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      const arrowLen = 10.0;
      const arrowAngle = 0.48;
      final p1 = Offset(
        end.dx - arrowLen * math.cos(angle - arrowAngle),
        end.dy - arrowLen * math.sin(angle - arrowAngle),
      );
      final p2 = Offset(
        end.dx - arrowLen * math.cos(angle + arrowAngle),
        end.dy - arrowLen * math.sin(angle + arrowAngle),
      );

      final head = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();
      canvas.drawPath(head, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadmapEdgesPainter oldDelegate) =>
      oldDelegate.edges != edges;
}

class _OvalNodeWidget extends StatelessWidget {
  final _MapNode node;
  final bool selected;
  final VoidCallback? onTap;

  const _OvalNodeWidget({
    required this.node,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFaint =
        node.kind == _NodeKind.unchosen || node.kind == _NodeKind.future;
    final isEnding = node.kind == _NodeKind.ending;
    final isCurrent = node.kind == _NodeKind.current;

    Color fill = OmoriColors.paper;
    Color stroke = OmoriColors.ink;
    if (selected) {
      fill = OmoriColors.pastelLavender;
      stroke = OmoriColors.dreamIndigo;
    } else if (isCurrent) {
      fill = OmoriColors.pastelLavender.withValues(alpha: 0.7);
      stroke = OmoriColors.dreamIndigo;
    } else if (isEnding) {
      fill = OmoriColors.whiteSpace;
      stroke = OmoriColors.redAccent.withValues(alpha: 0.75);
    } else if (isFaint) {
      fill = OmoriColors.whiteSpace;
      stroke = OmoriColors.ink.withValues(alpha: 0.2);
    }

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _OvalPainter(
          fill: fill,
          stroke: stroke,
          strokeWidth: selected ? 2.6 : (isFaint ? 1.3 : 2.0),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  node.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OmoriTheme.hand(
                    size: isFaint ? 13 : 16,
                    weight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: isFaint
                        ? OmoriColors.mutedInk.withValues(alpha: 0.45)
                        : (isEnding ? OmoriColors.redAccent : OmoriColors.ink),
                  ),
                ),
                if (node.subtitle.isNotEmpty)
                  Text(
                    node.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OmoriTheme.hand(
                      size: 13,
                      color: isFaint
                          ? OmoriColors.mutedInk.withValues(alpha: 0.35)
                          : OmoriColors.mutedInk,
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

class _OvalPainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  final double strokeWidth;

  const _OvalPainter({
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(rect, Paint()..color = fill);
    canvas.drawOval(
      rect,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _OvalPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.stroke != stroke ||
      oldDelegate.strokeWidth != strokeWidth;
}
