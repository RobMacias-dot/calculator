import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFF4F6F8);
  static const ink = Color(0xFF202A35);
  static const muted = Color(0xFF5D6875);
  static const accent = Color(0xFFAF450D);
  static const accentSoft = Color(0xFFFFEBDD);
  static const darkBackground = Color(0xFF131A22);
  static const darkSurface = Color(0xFF202B37);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const iconPadding = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const contentWidth = 1080.0;
  static const compactBreakpoint = 600.0;
}

abstract final class AppRadius {
  static const input = 16.0;
  static const card = 24.0;
  static const capsule = 32.0;
}

abstract final class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x080F233C), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

abstract final class AppDurations {
  static const quick = Duration(milliseconds: 180);
}

abstract final class AppTypography {
  static TextTheme apply(TextTheme base) => base.copyWith(
    headlineLarge: base.headlineLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -1.2,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
    ),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: base.bodyLarge?.copyWith(height: 1.5),
    bodyMedium: base.bodyMedium?.copyWith(height: 1.5),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );
}
