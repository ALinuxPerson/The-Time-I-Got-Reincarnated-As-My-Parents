import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/sound_service.dart';
import '../theme/omori_theme.dart';

String childSpriteAssetForMood(String mood) {
  switch (mood.toLowerCase()) {
    case 'sad':
    case 'anxious':
    case 'quiet':
      return 'assets/images/child_wah.svg';
    default:
      return 'assets/images/child_happy.svg';
  }
}

String characterPortraitAssetForStage(String ageStage, String mood) {
  final stage = ageStage.toLowerCase();
  if (stage.contains('infan') ||
      stage.contains('early') ||
      stage.contains('child')) {
    return childSpriteAssetForMood(mood);
  }
  if (stage.contains('pre-teen') || stage.contains('teen')) {
    return 'assets/images/portrait_teen.jpg';
  }
  return 'assets/images/portrait_adult.jpg';
}

class ArtworkImage extends StatelessWidget {
  final String assetPath;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final WidgetBuilder? fallbackBuilder;

  const ArtworkImage({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.fallbackBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        placeholderBuilder: fallbackBuilder,
      );
    }
    return Image.asset(
      assetPath,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      errorBuilder: fallbackBuilder == null
          ? null
          : (context, _, _) => fallbackBuilder!(context),
    );
  }
}

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
  final UiSound sound;
  final bool inverted;
  final bool showPointer;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;

  const SketchButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.sound = UiSound.select,
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
      onTap: SoundService.withUiSound(widget.sound, widget.onPressed),
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

/// Gently fades a child in after [visible] becomes true + an optional [delay],
/// keeping layout space reserved so nothing jumps around.
class GradualReveal extends StatefulWidget {
  final Widget child;
  final bool visible;
  final Duration delay;
  final Duration duration;

  const GradualReveal({
    super.key,
    required this.child,
    this.visible = true,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
  });

  @override
  State<GradualReveal> createState() => _GradualRevealState();
}

class _GradualRevealState extends State<GradualReveal> {
  Timer? _timer;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _syncVisibility();
  }

  @override
  void didUpdateWidget(covariant GradualReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible ||
        oldWidget.delay != widget.delay) {
      _syncVisibility();
    }
  }

  void _syncVisibility() {
    _timer?.cancel();
    if (!widget.visible) {
      if (_shown) setState(() => _shown = false);
      return;
    }
    if (widget.delay == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.visible) setState(() => _shown = true);
      });
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted && widget.visible) setState(() => _shown = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_shown,
      child: AnimatedOpacity(
        opacity: _shown ? 1.0 : 0.0,
        duration: widget.duration,
        curve: Curves.easeInOutSine,
        child: widget.child,
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

/// Iconic OMORI hanging lightbulb — black void in White Space, or warmly lit
/// with glowing pastel-gold rays during rebirth.
class HangingLightbulb extends StatelessWidget {
  final double cordHeight;
  final Color color;
  final bool lit;

  const HangingLightbulb({
    super.key,
    this.cordHeight = 64,
    this.color = OmoriColors.ink,
    this.lit = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: lit ? 112 : 48,
      height: cordHeight + (lit ? 64 : 46),
      child: CustomPaint(
        painter: _LightbulbPainter(
          cordHeight: cordHeight,
          color: color,
          lit: lit,
        ),
      ),
    );
  }
}

class _LightbulbPainter extends CustomPainter {
  final double cordHeight;
  final Color color;
  final bool lit;

  const _LightbulbPainter({
    required this.cordHeight,
    required this.color,
    required this.lit,
  });

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

    final bulbCenter = Offset(cx, cordHeight + 25);

    if (lit) {
      // Soft luminous golden-pastel radial glow behind the lit bulb
      final glowRect = Rect.fromCircle(center: bulbCenter, radius: 52);
      final glowGradient = const RadialGradient(
        colors: [
          Color(0xCCFFF3A6),
          Color(0x66FFE08A),
          Color(0x28FFB3D9),
          Color(0x00FFF3A6),
        ],
        stops: [0.0, 0.38, 0.70, 1.0],
      );
      canvas.drawCircle(
        bulbCenter,
        52,
        Paint()..shader = glowGradient.createShader(glowRect),
      );

      // Gentle sun-like light rays
      final rayPaint = Paint()
        ..color = const Color(0xFFFFC94A).withValues(alpha: 0.72)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      const rayCount = 8;
      for (int i = 0; i < rayCount; i++) {
        final angle = (i * math.pi * 2 / rayCount) + math.pi / 8;
        final start = Offset(
          bulbCenter.dx + math.cos(angle) * 21,
          bulbCenter.dy + math.sin(angle) * 21,
        );
        final end = Offset(
          bulbCenter.dx + math.cos(angle) * 30,
          bulbCenter.dy + math.sin(angle) * 30,
        );
        canvas.drawLine(start, end, rayPaint);
      }

      // Warm glowing bulb fill
      final bulbRect = Rect.fromCircle(center: bulbCenter, radius: 15);
      final bulbFill = const RadialGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFFFF5B8),
          Color(0xFFFFD86B),
        ],
        stops: [0.0, 0.55, 1.0],
      );
      canvas.drawCircle(
        bulbCenter,
        15,
        Paint()..shader = bulbFill.createShader(bulbRect),
      );

      // Crisp sketchy outline
      canvas.drawCircle(
        bulbCenter,
        15,
        Paint()
          ..color = const Color(0xFFD9941E)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke,
      );

      // Bright glowing inner filament
      final filamentPaint = Paint()
        ..color = const Color(0xFFE08E1B)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final filament = Path()
        ..moveTo(cx - 4, cordHeight + 16)
        ..lineTo(cx - 2, cordHeight + 26)
        ..lineTo(cx, cordHeight + 23)
        ..lineTo(cx + 2, cordHeight + 26)
        ..lineTo(cx + 4, cordHeight + 16);
      canvas.drawPath(filament, filamentPaint);
    } else {
      // Bulb silhouette (black filled like OMORI's White Space bulb)
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
  }

  @override
  bool shouldRepaint(covariant _LightbulbPainter oldDelegate) =>
      oldDelegate.cordHeight != cordHeight ||
      oldDelegate.color != color ||
      oldDelegate.lit != lit;
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
              child: ArtworkImage(
                assetPath: characterPortraitAssetForStage(ageStage, mood),
                fit: BoxFit.cover,
                fallbackBuilder: (_) => CustomPaint(
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

/// Interactive 3D parallax space graph (small Obsidian-style nodes that drift
/// across depth layers and dynamically connect when nearby). Moving the mouse
/// cursor smoothly tilts the 3D camera, glides each depth plane at its own
/// parallax speed, and illuminates nearby node clusters.
///
/// Optimized for zero per-frame widget rebuilds and minimal allocations by
/// driving a `CustomPainter` directly from the `AnimationController` with
/// pre-allocated typed buffers and reusable `Paint` instances.
class SpaceParticlesBackground extends StatefulWidget {
  final bool darkMode;
  final bool pastelMode;
  final int particleCount;
  final Widget? child;

  const SpaceParticlesBackground({
    super.key,
    this.darkMode = false,
    this.pastelMode = false,
    this.particleCount = 54,
    this.child,
  });

  @override
  State<SpaceParticlesBackground> createState() =>
      _SpaceParticlesBackgroundState();
}

class _SpaceParticlesBackgroundState extends State<SpaceParticlesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final _SpaceGraphEngine _engine;
  late final _SpaceParticlesPainter _painter;

  @override
  void initState() {
    super.initState();
    _engine = _SpaceGraphEngine(
      particleCount: widget.particleCount,
      darkMode: widget.darkMode,
      pastelMode: widget.pastelMode,
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(_onTick);
    _painter = _SpaceParticlesPainter(
      engine: _engine,
      repaint: _controller,
    );
    _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant SpaceParticlesBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.darkMode != widget.darkMode) {
      _engine.darkMode = widget.darkMode;
    }
    if (oldWidget.pastelMode != widget.pastelMode) {
      _engine.pastelMode = widget.pastelMode;
    }
  }

  void _onTick() {
    _engine.step(_controller.value * 60.0);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onHover: (event) => _engine.setPointer(event.localPosition),
      onExit: (_) => _engine.clearPointer(),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerMove: (event) => _engine.setPointer(event.localPosition),
        onPointerDown: (event) => _engine.setPointer(event.localPosition),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _painter,
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            if (widget.child != null) widget.child!,
          ],
        ),
      ),
    );
  }
}

class _SpaceParticle {
  double x;
  double y;
  final double depth;
  final double z0;
  final double depthCurve;
  final double baseRadius;
  final double driftX;
  final double driftY;
  final double phase;
  final double twinkleSpeed;
  final double baseOpacity;
  final bool accent;
  final int pastelIndex;

  _SpaceParticle({
    required this.x,
    required this.y,
    required this.depth,
    required this.z0,
    required this.depthCurve,
    required this.baseRadius,
    required this.driftX,
    required this.driftY,
    required this.phase,
    required this.twinkleSpeed,
    required this.baseOpacity,
    required this.accent,
    required this.pastelIndex,
  });
}

/// Holds mutable simulation state and reusable typed buffers so each animation
/// frame performs zero widget rebuilds and minimal heap allocations.
class _SpaceGraphEngine {
  static const List<Color> pastelPalette = [
    Color(0xFFFF7EB6), // pastel rose pink
    Color(0xFFFFC94D), // warm buttercup yellow
    Color(0xFF4ADEA8), // pastel mint
    Color(0xFF8B84FF), // dreamy periwinkle
    Color(0xFFFF9E7D), // soft peach
    Color(0xFFC084FC), // lilac lavender
    Color(0xFF38BDF8), // bright sky cyan
  ];

  final List<_SpaceParticle> particles;
  bool darkMode;
  bool pastelMode;

  Size viewportSize = Size.zero;
  Offset? _targetPointer;
  Offset? smoothPointer;
  Offset smoothParallax = Offset.zero;
  double pointerStrength = 0.0;
  double elapsed = 0.0;
  double _lastTick = 0.0;

  // Pre-allocated projection buffers (sized to particleCount).
  final Float64List projX;
  final Float64List projY;
  final Float64List projDepth;
  final Float64List projRadius;
  final Float64List projOpacity;
  final Float64List projHover;
  final Uint8List projAccent;
  final Uint8List projPastel;
  final Int32List linkCounts;

  _SpaceGraphEngine({
    required int particleCount,
    required this.darkMode,
    required this.pastelMode,
  }) : particles = _buildParticles(particleCount),
       projX = Float64List(particleCount),
       projY = Float64List(particleCount),
       projDepth = Float64List(particleCount),
       projRadius = Float64List(particleCount),
       projOpacity = Float64List(particleCount),
       projHover = Float64List(particleCount),
       projAccent = Uint8List(particleCount),
       projPastel = Uint8List(particleCount),
       linkCounts = Int32List(particleCount);

  static List<_SpaceParticle> _buildParticles(int count) {
    final rng = math.Random(42);
    return List.generate(count, (i) {
      final double depth;
      final double baseRadius;
      final double baseOpacity;
      if (i < count * 0.42) {
        depth = 0.24 + rng.nextDouble() * 0.22;
        baseRadius = 1.4 + rng.nextDouble() * 0.9;
        baseOpacity = 0.26 + rng.nextDouble() * 0.22;
      } else if (i < count * 0.78) {
        depth = 0.62 + rng.nextDouble() * 0.34;
        baseRadius = 2.3 + rng.nextDouble() * 1.4;
        baseOpacity = 0.38 + rng.nextDouble() * 0.28;
      } else {
        depth = 1.12 + rng.nextDouble() * 0.48;
        baseRadius = 3.6 + rng.nextDouble() * 1.8;
        baseOpacity = 0.48 + rng.nextDouble() * 0.32;
      }

      return _SpaceParticle(
        x: (rng.nextDouble() - 0.5) * 1.45,
        y: (rng.nextDouble() - 0.5) * 1.45,
        depth: depth,
        z0: depth - 0.85,
        depthCurve: math.pow(depth, 1.35).toDouble(),
        baseRadius: baseRadius,
        driftX: (rng.nextDouble() - 0.5) * 0.015,
        driftY: -(0.006 + rng.nextDouble() * 0.014),
        phase: rng.nextDouble() * math.pi * 2,
        twinkleSpeed: 0.7 + rng.nextDouble() * 1.4,
        baseOpacity: baseOpacity,
        accent: i % 3 == 0,
        pastelIndex: i % pastelPalette.length,
      );
    })..sort((a, b) => a.depth.compareTo(b.depth));
  }

  void setPointer(Offset localPosition) {
    _targetPointer = localPosition;
  }

  void clearPointer() {
    _targetPointer = null;
  }

  void step(double nowSeconds) {
    var dt = nowSeconds - _lastTick;
    if (dt < 0) dt += 60.0;
    dt = dt.clamp(0.0, 0.05);
    _lastTick = nowSeconds;
    elapsed += dt;

    for (final p in particles) {
      final speedScale = 0.4 + p.depth * 0.6;
      p.x += p.driftX * dt * speedScale;
      p.y += p.driftY * dt * speedScale;
      if (p.x > 0.75) p.x -= 1.50;
      if (p.x < -0.75) p.x += 1.50;
      if (p.y > 0.75) p.y -= 1.50;
      if (p.y < -0.75) p.y += 1.50;
    }

    if (_targetPointer != null && !viewportSize.isEmpty) {
      smoothPointer = smoothPointer == null
          ? _targetPointer
          : Offset.lerp(smoothPointer, _targetPointer, 0.16);
      pointerStrength = (pointerStrength + dt * 4.5).clamp(0.0, 1.0);

      final nx = ((smoothPointer!.dx / viewportSize.width) - 0.5) * 2.0;
      final ny = ((smoothPointer!.dy / viewportSize.height) - 0.5) * 2.0;
      smoothParallax = Offset.lerp(
        smoothParallax,
        Offset(nx.clamp(-1.0, 1.0), ny.clamp(-1.0, 1.0)),
        0.09,
      )!;
    } else {
      pointerStrength = (pointerStrength - dt * 1.8).clamp(0.0, 1.0);
      smoothParallax = Offset.lerp(smoothParallax, Offset.zero, 0.045)!;
      if (pointerStrength == 0.0) {
        smoothPointer = null;
      }
    }
  }
}

class _SpaceParticlesPainter extends CustomPainter {
  final _SpaceGraphEngine engine;
  final Paint _edgePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _nodePaint = Paint()..style = PaintingStyle.fill;

  _SpaceParticlesPainter({
    required this.engine,
    required super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    engine.viewportSize = size;

    final darkMode = engine.darkMode;
    final pastelMode = engine.pastelMode;
    final elapsed = engine.elapsed;
    final pointer = engine.smoothPointer;
    final pointerStrength = engine.pointerStrength;
    final parallax = engine.smoothParallax;

    final cx = size.width * 0.5;
    final cy = size.height * 0.5;
    final wScale = size.width * 0.72;
    final hScale = size.height * 0.72;

    final yaw = parallax.dx * 0.22;
    final pitch = parallax.dy * 0.18;
    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final cosP = math.cos(pitch);
    final sinP = math.sin(pitch);

    final maxShiftX = math.min(size.width * 0.18, 130.0);
    final maxShiftY = math.min(size.height * 0.18, 110.0);
    const shimmerRadius = 155.0;
    const shimmerRadiusSq = shimmerRadius * shimmerRadius;

    final projX = engine.projX;
    final projY = engine.projY;
    final projDepth = engine.projDepth;
    final projRadius = engine.projRadius;
    final projOpacity = engine.projOpacity;
    final projHover = engine.projHover;
    final projAccent = engine.projAccent;
    final projPastel = engine.projPastel;
    final linkCounts = engine.linkCounts;

    // 1. Project visible 3D particles into flat typed buffers.
    int count = 0;
    final hasPointer = pointer != null && pointerStrength > 0.01;
    final ptrX = hasPointer ? pointer.dx : 0.0;
    final ptrY = hasPointer ? pointer.dy : 0.0;

    for (final p in engine.particles) {
      final floatX = math.sin(elapsed * 0.55 + p.phase) * 0.008 * p.depth;
      final floatY = math.cos(elapsed * 0.45 + p.phase) * 0.008 * p.depth;

      final x0 = p.x + floatX;
      final y0 = p.y + floatY;
      final z0 = p.z0;

      final rx = x0 * cosY - z0 * sinY;
      final rz1 = x0 * sinY + z0 * cosY;
      final ry = y0 * cosP - rz1 * sinP;
      final rz = y0 * sinP + rz1 * cosP;

      final denom = (1.35 - rz * 0.35).clamp(0.55, 2.2);
      final perspective = 1.0 / denom;

      final shiftX = -parallax.dx * maxShiftX * p.depthCurve;
      final shiftY = -parallax.dy * maxShiftY * p.depthCurve;

      var dx = cx + rx * wScale * perspective + shiftX;
      var dy = cy + ry * hScale * perspective + shiftY;

      if (dx < -40 ||
          dx > size.width + 40 ||
          dy < -40 ||
          dy > size.height + 40) {
        continue;
      }

      var radius = (p.baseRadius * perspective * (pastelMode ? 1.25 : 1.0))
          .clamp(1.2, pastelMode ? 7.8 : 6.2);
      var hoverBoost = 0.0;

      if (hasPointer) {
        final vx = dx - ptrX;
        final vy = dy - ptrY;
        final distSq = vx * vx + vy * vy;
        if (distSq < shimmerRadiusSq && distSq > 0.25) {
          final dist = math.sqrt(distSq);
          final t = (1.0 - dist / shimmerRadius) * pointerStrength;
          final ease = t * t;
          final nudge = ease * 16.0 * p.depth;
          dx += (vx / dist) * nudge;
          dy += (vy / dist) * nudge;
          radius *= 1.0 + ease * 0.35;
          hoverBoost = ease;
        }
      }

      final twinkle =
          0.72 + 0.28 * math.sin(elapsed * p.twinkleSpeed + p.phase);
      final opacity =
          (p.baseOpacity * twinkle +
                  (pastelMode ? 0.16 : 0.0) +
                  hoverBoost * 0.35)
              .clamp(0.10, 0.95);

      projX[count] = dx;
      projY[count] = dy;
      projDepth[count] = p.depth;
      projRadius[count] = radius;
      projOpacity[count] = opacity;
      projHover[count] = hoverBoost;
      projAccent[count] = p.accent ? 1 : 0;
      projPastel[count] = p.pastelIndex;
      linkCounts[count] = 0;
      count++;
    }

    // 2. Draw Obsidian-style graph edges between nearby nodes in similar depth
    //    layers (particles are sorted by depth, so we can break early!).
    const maxLinksPerNode = 3;
    const baseConnectDist = 136.0;

    for (int i = 0; i < count; i++) {
      if (linkCounts[i] >= maxLinksPerNode) continue;
      final ax = projX[i];
      final ay = projY[i];
      final aDepth = projDepth[i];
      final aHover = projHover[i];

      for (int j = i + 1; j < count; j++) {
        if (linkCounts[i] >= maxLinksPerNode) break;
        final bDepth = projDepth[j];
        // Sorted by depth: once depth gap exceeds 0.48, no later node matches.
        if (bDepth - aDepth > 0.48) break;
        if (linkCounts[j] >= maxLinksPerNode) continue;

        final avgDepth = (aDepth + bDepth) * 0.5;
        final maxDist = baseConnectDist * (0.75 + avgDepth * 0.35);
        final ddx = ax - projX[j];
        final ddy = ay - projY[j];
        final distSq = ddx * ddx + ddy * ddy;
        if (distSq >= maxDist * maxDist) continue;

        final dist = math.sqrt(distSq);
        final proximity = 1.0 - (dist / maxDist);
        final clusterGlow = aHover > projHover[j] ? aHover : projHover[j];
        final edgeAlpha =
            (proximity * (0.16 + avgDepth * 0.08) + clusterGlow * 0.28).clamp(
              0.0,
              0.52,
            );

        if (pastelMode) {
          final baseEdgeColor = _SpaceGraphEngine.pastelPalette[projPastel[i]];
          _edgePaint.color = baseEdgeColor.withValues(
            alpha: (edgeAlpha * 1.15).clamp(0.0, 0.62),
          );
        } else if (darkMode) {
          _edgePaint.color = clusterGlow > 0.15
              ? OmoriColors.pastelLavender.withValues(alpha: edgeAlpha)
              : OmoriColors.paper.withValues(alpha: edgeAlpha * 0.72);
        } else {
          _edgePaint.color = clusterGlow > 0.15
              ? OmoriColors.dreamIndigo.withValues(alpha: edgeAlpha)
              : OmoriColors.ink.withValues(alpha: edgeAlpha * 0.62);
        }
        _edgePaint.strokeWidth = 0.75 + avgDepth * 0.35 + clusterGlow * 0.45;

        canvas.drawLine(Offset(ax, ay), Offset(projX[j], projY[j]), _edgePaint);

        linkCounts[i]++;
        linkCounts[j]++;
      }
    }

    // 3. Draw crisp circular graph nodes on top of edges.
    for (int i = 0; i < count; i++) {
      final dx = projX[i];
      final dy = projY[i];
      final depth = projDepth[i];
      final radius = projRadius[i];
      final opacity = projOpacity[i];
      final hover = projHover[i];
      final isHighlighted = hover > 0.15;
      final useAccent = projAccent[i] == 1 || isHighlighted;

      final Color nodeColor;
      if (pastelMode) {
        nodeColor = _SpaceGraphEngine.pastelPalette[projPastel[i]].withValues(
          alpha: opacity,
        );
      } else if (darkMode) {
        nodeColor = useAccent
            ? OmoriColors.pastelLavender.withValues(alpha: opacity)
            : OmoriColors.paper.withValues(alpha: opacity);
      } else {
        nodeColor = useAccent
            ? OmoriColors.dreamIndigo.withValues(alpha: opacity)
            : OmoriColors.ink.withValues(alpha: opacity * 0.80);
      }

      if (pastelMode || depth > 0.9 || isHighlighted) {
        _nodePaint.color = nodeColor.withValues(
          alpha: (opacity * ((pastelMode ? 0.24 : 0.16) + hover * 0.14)).clamp(
            0.0,
            0.42,
          ),
        );
        canvas.drawCircle(
          Offset(dx, dy),
          radius * ((pastelMode ? 2.4 : 2.1) + hover * 0.8),
          _nodePaint,
        );
      }

      _nodePaint.color = nodeColor;
      canvas.drawCircle(Offset(dx, dy), radius, _nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpaceParticlesPainter oldDelegate) =>
      oldDelegate.engine != engine;
}

/// Main choice-screen backdrop (`GameScreen`) with a mood-reactive character.
class WindowSceneBackground extends StatelessWidget {
  final int age;
  final String mood;
  final Widget child;

  const WindowSceneBackground({
    super.key,
    required this.age,
    required this.mood,
    required this.child,
  });

  static String ageBucket(int age) {
    if (age <= 2) return 'infancy';
    if (age <= 10) return 'childhood';
    if (age <= 17) return 'teen';
    return 'adult';
  }

  static String normalizedMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'proud':
      case 'neutral':
      case 'quiet':
      case 'anxious':
      case 'sad':
        return mood.toLowerCase();
      default:
        return 'neutral';
    }
  }

  static const String backgroundAsset = 'assets/images/background.png';

  static String characterAssetForAge(int age, String mood) => age <= 2
      ? childSpriteAssetForMood(mood)
      : 'assets/images/window/standing_${ageBucket(age)}.png';

  List<Color> _fallbackSkyColors(String m) {
    switch (m) {
      case 'happy':
        return const [Color(0xFF6CC2FF), Color(0xFFBAE8FF), Color(0xFFFFF4D6)];
      case 'proud':
        return const [Color(0xFF7C82E0), Color(0xFFF2A8C6), Color(0xFFFFEEBA)];
      case 'quiet':
        return const [Color(0xFF2C3466), Color(0xFF5C62A4), Color(0xFFBAAEDE)];
      case 'anxious':
        return const [Color(0xFF4A4874), Color(0xFF847AA2), Color(0xFFE0B2A4)];
      case 'sad':
        return const [Color(0xFF485C80), Color(0xFF7A92B2), Color(0xFFB8CADC)];
      default:
        return const [Color(0xFF90C0F5), Color(0xFFD6EAFC), Color(0xFFF6F2EC)];
    }
  }

  Color _characterMoodTint(String m) {
    switch (m) {
      case 'happy':
        return const Color(0xFFFFE58F).withValues(alpha: 0.14);
      case 'proud':
        return const Color(0xFFFFB07C).withValues(alpha: 0.18);
      case 'quiet':
        return const Color(0xFF4F46E5).withValues(alpha: 0.18);
      case 'anxious':
        return const Color(0xFF7C3AED).withValues(alpha: 0.16);
      case 'sad':
        return const Color(0xFF3B82F6).withValues(alpha: 0.22);
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = normalizedMood(mood);
    final stage = ageBucket(age);
    final charAsset = characterAssetForAge(age, m);
    final isDarkSky = m == 'quiet' || m == 'anxious' || m == 'sad';

    return LayoutBuilder(
      builder: (context, constraints) {
        final leftFourthWidth = (constraints.maxWidth * 0.25).clamp(
          110.0,
          constraints.maxWidth * 0.42,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-bleed shared pixel-art background
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 700),
                switchInCurve: Curves.easeInOutSine,
                switchOutCurve: Curves.easeInOutSine,
                child: ArtworkImage(
                  assetPath: backgroundAsset,
                  key: const ValueKey('game_background'),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  fallbackBuilder: (_) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _fallbackSkyColors(m),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Soft readability wash over the right 3/4 so narrative text
            //    pops clearly while the left fourth stays vibrant and crisp
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const [0.0, 0.22, 0.34, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        OmoriColors.whiteSpace.withValues(
                          alpha: isDarkSky ? 0.80 : 0.72,
                        ),
                        OmoriColors.whiteSpace.withValues(
                          alpha: isDarkSky ? 0.86 : 0.78,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Left-fourth full-height standing portrait of the person
            //    (changes by age & receives subtle mood lighting)
            Positioned(
              left: 0,
              top: 16,
              bottom: 12,
              width: leftFourthWidth,
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 650),
                    switchInCurve: Curves.easeInOutSine,
                    switchOutCurve: Curves.easeInOutSine,
                    child: ColorFiltered(
                      key: ValueKey('standing_${stage}_$m'),
                      colorFilter: ColorFilter.mode(
                        _characterMoodTint(m),
                        BlendMode.srcATop,
                      ),
                      child: ArtworkImage(
                        assetPath: charAsset,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        width: leftFourthWidth,
                        height: double.infinity,
                        fallbackBuilder: (_) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 4. Foreground screen content (choices & narrative)
            child,
          ],
        );
      },
    );
  }
}
