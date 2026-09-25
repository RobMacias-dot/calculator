import 'package:flutter/material.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/glass_card.dart';
import '../domain/calculator_definition.dart';
import 'category_visuals.dart';
import 'favorite_button.dart';
import '../../preferences/preferences_controller.dart';

class CalculatorTile extends StatelessWidget {
  const CalculatorTile({
    super.key,
    required this.definition,
    required this.onTap,
    required this.preferences,
  });
  final CalculatorDefinition definition;
  final VoidCallback onTap;
  final PreferencesController preferences;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CategoryIcon(category: definition.category),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(definition.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  definition.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  definition.isAvailable ? 'Ready to calculate' : 'Coming soon',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FavoriteButton(definition: definition, preferences: preferences),
        ],
      ),
    );
  }
}
