import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sound_service.dart';
import '../theme/omori_theme.dart';

/// Hand-drawn sketchy ink box inspired by OMORI's dialogue & menu frames.
class SketchBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color fillColor;
  final Color borderColor;
  final double strokeWidth;

  const SketchBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.fillColor = OmoriColors.paper,
    this.borderColor = OmoriColors.ink,
    this.strokeWidth = 2.2,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SketchBoxPainter(
        fillColor: fillColor,
        borderColor: borderColor,
        strokeWidth: strokeWidth,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _SketchBoxPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double strokeWidth;

  const _SketchBoxPainter({
    required this.fillColor,
    required this.borderColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    canvas.drawRect(rect, Paint()..color = fillColor);
    canvas.drawRect(
      rect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _SketchBoxPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Pressable OMORI-style menu/choice button.
class SketchButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool inverted;
  final bool showPointer;
  final EdgeInsetsGeometry padding;

  const SketchButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.inverted = false,
    this.showPointer = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
  });

  @override
  State<SketchButton> createState() => _SketchButtonState();
}

class _SketchButtonState extends State<SketchButton> {
  bool _pressed = false;
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final selected = _focused || _hovered;
    final dark = widget.inverted || _pressed;
    final textColor = dark ? OmoriColors.paper : OmoriColors.ink;
    return Semantics(
      button: true,
      enabled: enabled,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) {
          if (MediaQuery.sizeOf(context).shortestSide >= 600) {
            setState(() => _hovered = value);
          }
        },
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: OmoriTheme.motion,
            curve: OmoriTheme.curve,
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: dark ? OmoriColors.ink : OmoriColors.paper,
              border: Border.all(
                color: selected ? OmoriColors.accent : OmoriColors.ink,
                width: selected ? 3 : 2,
              ),
            ),
            child: Row(
              children: [
                if (widget.showPointer) ...[
                  SizedBox(
                    width: 24,
                    height: 20,
                    child: !enabled
                        ? Text('-', style: OmoriTheme.pixel(color: textColor))
                        : selected || widget.inverted || _pressed
                        ? CustomPaint(
                            key: const ValueKey('selection_pointer'),
                            painter: _SelectionPointer(
                              color: textColor,
                              pressed: _pressed,
                            ),
                          )
                        : null,
                  ),
                ],
                Expanded(
                  child: Text(
                    widget.label,
                    textAlign: widget.showPointer
                        ? TextAlign.start
                        : TextAlign.center,
                    style: OmoriTheme.hand(
                      size: widget.showPointer ? 20 : 16,
                      color: enabled
                          ? textColor
                          : (dark
                                ? OmoriColors.subtleLine
                                : OmoriColors.mutedInk),
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

class _SelectionPointer extends CustomPainter {
  final Color color;
  final bool pressed;
  const _SelectionPointer({required this.color, required this.pressed});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    if (pressed) {
      canvas.drawRect(const Rect.fromLTWH(5, 6, 8, 8), paint);
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(5, 4)
          ..lineTo(13, 10)
          ..lineTo(5, 16)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SelectionPointer old) =>
      old.color != color || old.pressed != pressed;
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCompleted?.call();
      });
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Text(
          widget.text.substring(0, _visibleCount.clamp(0, widget.text.length)),
          textAlign: widget.textAlign,
          style: widget.style ?? OmoriTheme.hand(size: 19),
        ),
      ),
    );
  }
}

/// Ink drawing used on the title and rebirth screens.
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

    canvas.drawCircle(
      bulbCenter,
      15,
      Paint()..color = lit ? OmoriColors.paper : color,
    );
    canvas.drawCircle(bulbCenter, 15, linePaint);
    final filament = Path()
      ..moveTo(cx - 4, cordHeight + 16)
      ..lineTo(cx - 2, cordHeight + 26)
      ..lineTo(cx, cordHeight + 23)
      ..lineTo(cx + 2, cordHeight + 26)
      ..lineTo(cx + 4, cordHeight + 16);
    canvas.drawPath(
      filament,
      Paint()
        ..color = lit ? color : OmoriColors.paper
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
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
  final Widget? fallback;

  const SketchImageFrame({
    super.key,
    required this.assetPath,
    this.aspectRatio = 16 / 9,
    this.maxWidth = 420,
    this.maxHeight = 236,
    this.borderColor = OmoriColors.ink,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: SketchBox(
            padding: EdgeInsets.zero,
            borderColor: borderColor,
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
        _StatBar(label: 'HAPPINESS', value: happiness),
        const SizedBox(height: 12),
        _StatBar(label: 'HEALTH', value: health),
        const SizedBox(height: 12),
        _StatBar(label: 'SMARTS', value: smarts),
        const SizedBox(height: 12),
        _StatBar(label: 'AMBITION', value: ambition),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int value;

  const _StatBar({required this.label, required this.value});

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
            child: Container(color: OmoriColors.ink),
          ),
        ),
      ],
    );
  }
}

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

  static String skyAssetForMood(String mood) =>
      'assets/images/window/sky_${normalizedMood(mood)}.png';

  static String characterAssetForAge(int age) =>
      'assets/images/window/standing_${ageBucket(age)}.png';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final width = compact ? 150.0 : 240.0;
        return ColoredBox(
          color: OmoriColors.whiteSpace,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The existing world art lives in one window, leaving the room quiet.
              Positioned(
                top: compact ? 72 : 80,
                left: compact ? 24 : 64,
                width: width,
                height: compact ? 190 : 300,
                child: ExcludeSemantics(
                  child: IgnorePointer(
                    child: SketchBox(
                      padding: const EdgeInsets.all(6),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            skyAssetForMood(mood),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const ColoredBox(color: OmoriColors.subtleLine),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 16,
                            right: 16,
                            top: 16,
                            child: Image.asset(
                              characterAssetForAge(age),
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        );
      },
    );
  }
}
