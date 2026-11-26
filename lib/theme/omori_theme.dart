import 'package:flutter/material.dart';

class OmoriColors {
  static const whiteSpace = Color(0xFFFAFAF7);
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF171717);
  static const mutedInk = Color(0xFF595959);
  static const subtleLine = Color(0xFFD0D0CB);
  static const accent = Color(0xFF9B2929);
  static const redAccent = accent;
  static const warmPaper = whiteSpace;
}

class OmoriTheme {
  static bool useSystemFallbackFonts = false;
  static const double fontScale = 1;
  static const motion = Duration(milliseconds: 150);
  static const curve = Curves.easeOut;

  // One small, body, and display size throughout the interface.
  static double _size(double size) => size <= 17 ? 16 : (size <= 23 ? 20 : 28);

  static TextStyle hand({
    double size = 20,
    FontWeight weight = FontWeight.w400,
    Color color = OmoriColors.ink,
    double? height,
    double? letterSpacing,
  }) {
    final base = TextStyle(
      fontSize: _size(size),
      fontWeight: weight,
      color: color,
      height: height ?? 1.3,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return base.copyWith(
      fontFamily: useSystemFallbackFonts ? null : 'PatrickHand',
    );
  }

  static TextStyle pixel({
    double size = 20,
    Color color = OmoriColors.ink,
    double? letterSpacing,
  }) {
    final base = TextStyle(
      fontFamily: 'monospace',
      fontSize: _size(size),
      color: color,
      height: 1.2,
      letterSpacing: letterSpacing ?? 0.6,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return base.copyWith(
      fontFamily: useSystemFallbackFonts ? 'monospace' : 'VT323',
    );
  }

  static ThemeData build() {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: OmoriColors.ink, width: 2),
    );
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: OmoriColors.whiteSpace,
      splashFactory: NoSplash.splashFactory,
      scrollbarTheme: const ScrollbarThemeData(
        radius: Radius.zero,
        thickness: WidgetStatePropertyAll(3),
        thumbColor: WidgetStatePropertyAll(OmoriColors.subtleLine),
      ),
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        surface: OmoriColors.whiteSpace,
        primary: OmoriColors.accent,
        secondary: OmoriColors.accent,
        error: OmoriColors.accent,
        onSurface: OmoriColors.ink,
        onPrimary: OmoriColors.paper,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.macOS: _InkTransition(),
          TargetPlatform.iOS: _InkTransition(),
          TargetPlatform.android: _InkTransition(),
          TargetPlatform.linux: _InkTransition(),
          TargetPlatform.windows: _InkTransition(),
        },
      ),
      textTheme: TextTheme(
        headlineMedium: hand(size: 28),
        titleLarge: hand(size: 28),
        titleMedium: hand(size: 20),
        bodyLarge: hand(size: 20),
        bodyMedium: hand(size: 16),
        labelLarge: pixel(),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: OmoriColors.whiteSpace,
        foregroundColor: OmoriColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(),
          foregroundColor: OmoriColors.ink,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(),
          textStyle: hand(size: 20),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: OmoriColors.whiteSpace,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OmoriColors.paper,
        hintStyle: hand(size: 16, color: OmoriColors.mutedInk),
        contentPadding: const EdgeInsets.all(14),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: OmoriColors.accent, width: 3),
        ),
      ),
    );
  }
}

class _InkTransition extends PageTransitionsBuilder {
  const _InkTransition();

  @override
  Duration get transitionDuration => OmoriTheme.motion;
  @override
  Duration get reverseTransitionDuration => OmoriTheme.motion;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: OmoriTheme.curve),
      child: child,
    );
  }
}
