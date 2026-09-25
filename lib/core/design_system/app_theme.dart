import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static final light = _create(Brightness.light);
  static final dark = _create(Brightness.dark);

  static ThemeData _create(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFFFFB78C) : AppColors.accent,
          onPrimary: dark ? const Color(0xFF512000) : Colors.white,
          primaryContainer: dark
              ? const Color(0xFF59301C)
              : AppColors.accentSoft,
          onPrimaryContainer: dark ? const Color(0xFFFFDBC5) : AppColors.accent,
          surface: dark ? AppColors.darkSurface : Colors.white,
          onSurface: dark ? const Color(0xFFEBEFF4) : AppColors.ink,
          onSurfaceVariant: dark ? const Color(0xFFB8C2CF) : AppColors.muted,
          outlineVariant: dark
              ? const Color(0xFF3E4B5A)
              : const Color(0xFFDEE4EA),
        );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return base.copyWith(
      scaffoldBackgroundColor: dark
          ? AppColors.darkBackground
          : AppColors.background,
      textTheme: AppTypography.apply(base.textTheme),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: AppSpacing.xl,
      ),
    );
  }
}
