import 'package:flutter/material.dart';

import '../../../core/design_system/app_tokens.dart';
import '../domain/calculator_category.dart';

/// Maps domain categories to platform-specific visuals at the UI boundary.
extension CategoryVisuals on CalculatorCategory {
  IconData get icon => switch (this) {
    CalculatorCategory.electrical => Icons.bolt_outlined,
    CalculatorCategory.mechanical => Icons.settings_outlined,
    CalculatorCategory.fluids => Icons.water_drop_outlined,
    CalculatorCategory.thermodynamics => Icons.thermostat_outlined,
    CalculatorCategory.networking => Icons.hub_outlined,
    CalculatorCategory.mathematics => Icons.functions_rounded,
  };

  Color get tint => switch (this) {
    CalculatorCategory.electrical => const Color(0xFFFFEAD9),
    CalculatorCategory.mechanical => const Color(0xFFE9EDF4),
    CalculatorCategory.fluids => const Color(0xFFDEEEF9),
    CalculatorCategory.thermodynamics => const Color(0xFFFFE3DE),
    CalculatorCategory.networking => const Color(0xFFE8E3F6),
    CalculatorCategory.mathematics => const Color(0xFFE0EFE7),
  };

  Color get foreground => switch (this) {
    CalculatorCategory.electrical => const Color(0xFF9B480C),
    CalculatorCategory.mechanical => const Color(0xFF52657D),
    CalculatorCategory.fluids => const Color(0xFF256C96),
    CalculatorCategory.thermodynamics => const Color(0xFFAC4C3C),
    CalculatorCategory.networking => const Color(0xFF7051A0),
    CalculatorCategory.mathematics => const Color(0xFF3B7559),
  };
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category});
  final CalculatorCategory category;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.iconPadding),
    decoration: BoxDecoration(
      color: category.tint,
      borderRadius: BorderRadius.circular(AppRadius.input),
    ),
    child: Icon(category.icon, color: category.foreground, size: 26),
  );
}
