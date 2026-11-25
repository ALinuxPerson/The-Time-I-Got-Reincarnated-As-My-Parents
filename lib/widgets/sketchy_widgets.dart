import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import '../theme/omori_theme.dart';

/// Hand-drawn sketchy ink box inspired by OMORI's dialogue & menu frames.
class SketchBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color fillColor;
  final Color borderColor;
  final bool showShadow;
  final double strokeWidth;

  const SketchBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.fillColor = OmoriColors.paper,
    this.borderColor = OmoriColors.ink,
    this.showShadow = true,
    this.strokeWidth = 2.2,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SketchBoxPainter(
        fillColor: fillColor,
        borderColor: borderColor,
        showShadow: showShadow,
        strokeWidth: strokeWidth,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _SketchBoxPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final bool showShadow;
  final double strokeWidth;

  const _SketchBoxPainter({
    required this.fillColor,
    required this.borderColor,
    required this.showShadow,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    if (showShadow) {
      final shadowPaint = Paint()..color = borderColor;
      canvas.drawRect(rect.shift(const Offset(4, 4)), shadowPaint);
    }

    final fillPaint = Paint()..color = fillColor;
    canvas.drawRect(rect, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.miter;

    // Primary crisp border
    canvas.drawRect(rect, borderPaint);

    // Subtle second hand-drawn pass for sketchbook texture
    final sketchPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final path = Path()
      ..moveTo(1.5, -0.8)
      ..lineTo(size.width - 1.2, 0.9)
      ..lineTo(size.width + 0.8, size.height - 1.5)
      ..lineTo(-0.8, size.height + 0.6)
      ..close();
    canvas.drawPath(path, sketchPaint);
  }

  @override
  bool shouldRepaint(covariant _SketchBoxPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.showShadow != showShadow ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Pressable OMORI-style menu/choice button.
class SketchButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool inverted;
  final bool showPointer;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;

  const SketchButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.inverted = false,
    this.showPointer = true,
    this.accentColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
  });

  @override
  State<SketchButton> createState() => _SketchButtonState();
}

class _SketchButtonState extends State<SketchButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final activeColor = widget.accentColor ?? OmoriColors.ink;
    final fill = widget.inverted
        ? activeColor
        : (_pressed ? OmoriColors.pastelLavender : OmoriColors.paper);
    final textColor = widget.inverted
        ? OmoriColors.paper
        : (enabled ? OmoriColors.ink : OmoriColors.mutedInk);

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(
          _pressed ? 2 : 0,
          _pressed ? 2 : 0,
          0,
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: SketchBox(
            fillColor: fill,
            borderColor: activeColor,
            showShadow: !_pressed,
            padding: widget.padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showPointer) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 10),
                    child: Text(
                      '▶',
                      style: OmoriTheme.pixel(size: 16, color: textColor),
                    ),
                  ),
                ],
                Expanded(
                  child: Text(
                    widget.label,
                    style: OmoriTheme.hand(
                      size: 18,
                      weight: FontWeight.w500,
                      color: textColor,
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

/// Character-by-character typewriter dialogue. Tapping completes immediately.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDelay;
  final VoidCallback? onCompleted;
  final TextAlign textAlign;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charDelay = const Duration(milliseconds: 30),
    this.onCompleted,
    this.textAlign = TextAlign.start,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _timer;
  int _visibleCount = 0;

  bool get _isComplete => _visibleCount >= widget.text.length;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _visibleCount = 0;
      _start();
    }
  }

  void _start() {
    if (widget.text.isEmpty) {
      widget.onCompleted?.call();
      return;
    }
    _timer = Timer.periodic(widget.charDelay, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_visibleCount < widget.text.length) {
        final nextChar = widget.text[_visibleCount];
        setState(() => _visibleCount++);
        if (nextChar.trim().isNotEmpty) {
          SoundService.playTypewriterBlip();
        }
      } else {
        timer.cancel();
        widget.onCompleted?.call();
      }
    });
  }

  void completeNow() {
    if (!_isComplete) {
      _timer?.cancel();
      setState(() => _visibleCount = widget.text.length);
      widget.onCompleted?.call();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: completeNow,
      child: Text(
        widget.text.substring(0, _visibleCount.clamp(0, widget.text.length)),
        textAlign: widget.textAlign,
        style: widget.style ?? OmoriTheme.hand(size: 19),
      ),
    );
  }
}

/// Iconic OMORI hanging black lightbulb for White Space screens.
class HangingLightbulb extends StatelessWidget {
  final double cordHeight;
  final Color color;

  const HangingLightbulb({
    super.key,
    this.cordHeight = 64,
    this.color = OmoriColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: cordHeight + 46,
      child: CustomPaint(
        painter: _LightbulbPainter(cordHeight: cordHeight, color: color),
      ),
    );
  }
}

class _LightbulbPainter extends CustomPainter {
  final double cordHeight;
  final Color color;

  const _LightbulbPainter({required this.cordHeight, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Cord
    canvas.drawLine(Offset(cx, 0), Offset(cx, cordHeight), linePaint);

    // Socket
    final socketRect = Rect.fromCenter(
      center: Offset(cx, cordHeight + 5),
      width: 12,
      height: 10,
    );
    canvas.drawRect(socketRect, Paint()..color = color);

    // Bulb silhouette (black filled like OMORI's White Space bulb)
    final bulbCenter = Offset(cx, cordHeight + 25);
    canvas.drawCircle(bulbCenter, 15, Paint()..color = color);

    // Subtle white inner filament doodle
    final filamentPaint = Paint()
      ..color = OmoriColors.whiteSpace
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final filament = Path()
      ..moveTo(cx - 4, cordHeight + 16)
      ..lineTo(cx - 2, cordHeight + 26)
      ..lineTo(cx, cordHeight + 23)
      ..lineTo(cx + 2, cordHeight + 26)
      ..lineTo(cx + 4, cordHeight + 16);
    canvas.drawPath(filament, filamentPaint);
  }

  @override
  bool shouldRepaint(covariant _LightbulbPainter oldDelegate) =>
      oldDelegate.cordHeight != cordHeight || oldDelegate.color != color;
}

/// Framed pixel/sketchbook scene illustration with bounded desktop-safe sizing.
class SketchImageFrame extends StatelessWidget {
  final String assetPath;
  final double aspectRatio;
  final double maxWidth;
  final double maxHeight;
  final Color borderColor;
  final bool showShadow;
  final Widget? fallback;

  const SketchImageFrame({
    super.key,
    required this.assetPath,
    this.aspectRatio = 16 / 9,
    this.maxWidth = 420,
    this.maxHeight = 236,
    this.borderColor = OmoriColors.ink,
    this.showShadow = true,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: SketchBox(
            padding: EdgeInsets.zero,
            borderColor: borderColor,
            showShadow: showShadow,
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) =>
                  fallback ??
                  Container(
                    color: OmoriColors.warmPaper,
                    alignment: Alignment.center,
                    child: Text(
                      '[ SCENE SKETCH ]',
                      style: OmoriTheme.pixel(
                        size: 16,
                        color: OmoriColors.mutedInk,
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

/// Stardew x OMORI portrait adapting to age stage & mood, with painted fallback.
class OmoriPortrait extends StatelessWidget {
  final String ageStage;
  final String mood;
  final double size;

  const OmoriPortrait({
    super.key,
    required this.ageStage,
    required this.mood,
    this.size = 64,
  });

  String get _assetForStage {
    final stage = ageStage.toLowerCase();
    if (stage.contains('infan')) return 'assets/images/portrait_infancy.jpg';
    if (stage.contains('early') || stage.contains('child')) {
      return 'assets/images/portrait_childhood.jpg';
    }
    if (stage.contains('pre-teen') || stage.contains('teen')) {
      return 'assets/images/portrait_teen.jpg';
    }
    return 'assets/images/portrait_adult.jpg';
  }

  Color get _moodAccent {
    switch (mood) {
      case 'happy':
      case 'proud':
        return OmoriColors.dreamIndigo;
      case 'anxious':
      case 'sad':
        return OmoriColors.redAccent;
      default:
        return OmoriColors.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg = OmoriColors.paper;
    if (mood == 'happy' || mood == 'proud') {
      bg = OmoriColors.pastelLavender;
    } else if (mood == 'anxious' || mood == 'sad') {
      bg = const Color(0xFFF6F6F6);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: SketchBox(
              padding: EdgeInsets.zero,
              fillColor: bg,
              borderColor: _moodAccent,
              showShadow: false,
              strokeWidth: 2,
              child: Image.asset(
                _assetForStage,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => CustomPaint(
                  painter: _PortraitPainter(ageStage: ageStage, mood: mood),
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              color: _moodAccent,
              child: Text(
                mood.toUpperCase(),
                style: OmoriTheme.pixel(size: 10, color: OmoriColors.paper),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortraitPainter extends CustomPainter {
  final String ageStage;
  final String mood;

  const _PortraitPainter({required this.ageStage, required this.mood});

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = OmoriColors.ink
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillInk = Paint()..color = OmoriColors.ink;

    final cx = size.width / 2;
    final cy = size.height * 0.54;
    final r = size.width * 0.28;

    // Head outline
    canvas.drawCircle(Offset(cx, cy), r, ink);

    // Hair varies gently by age stage
    final stage = ageStage.toLowerCase();
    if (stage.contains('infan')) {
      // Single baby curl on top
      final curl = Path()
        ..moveTo(cx, cy - r)
        ..quadraticBezierTo(cx + 7, cy - r - 9, cx + 2, cy - r - 3);
      canvas.drawPath(curl, ink);
    } else if (stage.contains('early') || stage.contains('child')) {
      // Messy kid bangs
      final hair = Path()
        ..moveTo(cx - r * 0.9, cy - r * 0.35)
        ..lineTo(cx - r * 0.55, cy - r * 0.95)
        ..lineTo(cx - r * 0.15, cy - r * 0.65)
        ..lineTo(cx + r * 0.2, cy - r * 1.05)
        ..lineTo(cx + r * 0.6, cy - r * 0.7)
        ..lineTo(cx + r * 0.9, cy - r * 0.35);
      canvas.drawPath(hair, ink);
    } else {
      // Longer, sharper OMORI-style bangs for teen / young adult / adulthood
      final hair = Path()
        ..moveTo(cx - r * 1.02, cy + r * 0.1)
        ..quadraticBezierTo(cx - r * 1.05, cy - r * 1.15, cx, cy - r * 1.12)
        ..quadraticBezierTo(
          cx + r * 1.05,
          cy - r * 1.15,
          cx + r * 1.02,
          cy + r * 0.1,
        );
      canvas.drawPath(hair, ink);
      canvas.drawLine(
        Offset(cx - r * 0.5, cy - r * 0.95),
        Offset(cx - r * 0.25, cy - r * 0.4),
        ink,
      );
      canvas.drawLine(
        Offset(cx + r * 0.15, cy - r * 0.98),
        Offset(cx + r * 0.35, cy - r * 0.4),
        ink,
      );
    }

    // Eyes & Mouth by mood
    final leftEye = Offset(cx - r * 0.36, cy - r * 0.05);
    final rightEye = Offset(cx + r * 0.36, cy - r * 0.05);

    if (mood == 'quiet') {
      // Closed peaceful/quiet eyes
      canvas.drawLine(
        Offset(leftEye.dx - 3, leftEye.dy),
        Offset(leftEye.dx + 3, leftEye.dy),
        ink,
      );
      canvas.drawLine(
        Offset(rightEye.dx - 3, rightEye.dy),
        Offset(rightEye.dx + 3, rightEye.dy),
        ink,
      );
    } else {
      canvas.drawCircle(leftEye, 2.2, fillInk);
      canvas.drawCircle(rightEye, 2.2, fillInk);
    }

    // Mouth
    final mouthY = cy + r * 0.36;
    if (mood == 'happy' || mood == 'proud') {
      final smile = Path()
        ..moveTo(cx - 5, mouthY - 1)
        ..quadraticBezierTo(cx, mouthY + 5, cx + 5, mouthY - 1);
      canvas.drawPath(smile, ink);
    } else if (mood == 'sad' || mood == 'anxious') {
      final frown = Path()
        ..moveTo(cx - 5, mouthY + 3)
        ..quadraticBezierTo(cx, mouthY - 2, cx + 5, mouthY + 3);
      canvas.drawPath(frown, ink);
    } else {
      canvas.drawLine(
        Offset(cx - 4, mouthY + 1),
        Offset(cx + 4, mouthY + 1),
        ink,
      );
    }

    // Mood accents
    if (mood == 'anxious') {
      // Tiny sketchy scribble lines near top-right
      final stress = Paint()
        ..color = OmoriColors.redAccent
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(size.width - 13, 8),
        Offset(size.width - 7, 14),
        stress,
      );
      canvas.drawLine(
        Offset(size.width - 7, 8),
        Offset(size.width - 13, 14),
        stress,
      );
    } else if (mood == 'happy' || mood == 'proud') {
      // Tiny sparkle star
      final star = Paint()
        ..color = OmoriColors.dreamIndigo
        ..strokeWidth = 1.4;
      final sx = size.width - 11;
      const sy = 11.0;
      canvas.drawLine(Offset(sx - 4, sy), Offset(sx + 4, sy), star);
      canvas.drawLine(Offset(sx, sy - 4), Offset(sx, sy + 4), star);
    } else if (mood == 'sad') {
      // Tiny teardrop
      final tear = Paint()..color = OmoriColors.dreamIndigo;
      canvas.drawCircle(Offset(rightEye.dx + 2, rightEye.dy + 7), 1.8, tear);
    }

    // Subtle shoulder hints at bottom
    final shoulderArc = Rect.fromCenter(
      center: Offset(cx, size.height + 4),
      width: r * 2.2,
      height: r * 1.1,
    );
    canvas.drawArc(shoulderArc, math.pi, math.pi, false, ink);
  }

  @override
  bool shouldRepaint(covariant _PortraitPainter oldDelegate) =>
      oldDelegate.ageStage != ageStage || oldDelegate.mood != mood;
}

/// Compact 2x2 BitLife-style stat bars dressed in Stardew x OMORI ink framing.
class LifeStatsStrip extends StatelessWidget {
  final int happiness;
  final int health;
  final int smarts;
  final int ambition;

  const LifeStatsStrip({
    super.key,
    required this.happiness,
    required this.health,
    required this.smarts,
    required this.ambition,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatBar(
                label: 'HAPPINESS',
                value: happiness,
                color: const Color(0xFFD99B26),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatBar(
                label: 'HEALTH',
                value: health,
                color: const Color(0xFF4B9E5B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatBar(
                label: 'SMARTS',
                value: smarts,
                color: OmoriColors.dreamIndigo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatBar(
                label: 'AMBITION',
                value: ambition,
                color: OmoriColors.redAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: OmoriTheme.pixel(size: 14, color: OmoriColors.mutedInk),
            ),
            Text(
              '$clamped%',
              style: OmoriTheme.pixel(size: 14, color: OmoriColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: OmoriColors.whiteSpace,
            border: Border.all(color: OmoriColors.ink, width: 1.4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clamped / 100.0,
            child: Container(color: color),
          ),
        ),
      ],
    );
  }
}

/// Inline chips showing per-decision stat shifts (e.g., +8 HAPPINESS).
class StatDeltaChips extends StatelessWidget {
  final int happinessDelta;
  final int healthDelta;
  final int smartsDelta;
  final int ambitionDelta;

  const StatDeltaChips({
    super.key,
    required this.happinessDelta,
    required this.healthDelta,
    required this.smartsDelta,
    required this.ambitionDelta,
  });

  @override
  Widget build(BuildContext context) {
    final items = <(String, int)>[
      ('HAPPINESS', happinessDelta),
      ('HEALTH', healthDelta),
      ('SMARTS', smartsDelta),
      ('AMBITION', ambitionDelta),
    ].where((e) => e.$2 != 0).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final (label, delta) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: delta > 0
                  ? OmoriColors.pastelLavender
                  : const Color(0xFFFFEFEF),
              border: Border.all(
                color: delta > 0
                    ? OmoriColors.dreamIndigo
                    : OmoriColors.redAccent,
                width: 1,
              ),
            ),
            child: Text(
              '${delta > 0 ? '+' : ''}$delta $label',
              style: OmoriTheme.pixel(
                size: 13,
                color: delta > 0
                    ? OmoriColors.dreamIndigo
                    : OmoriColors.redAccent,
              ),
            ),
          ),
      ],
    );
  }
}
