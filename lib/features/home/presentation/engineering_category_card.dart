import 'package:flutter/material.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/glass_card.dart';
import '../../calculators/domain/calculator_category.dart';
import '../../calculators/presentation/category_visuals.dart';

class EngineeringCategoryCard extends StatelessWidget {
  const EngineeringCategoryCard({
    super.key,
    required this.category,
    required this.toolCount,
    required this.onTap,
  });
  final CalculatorCategory category;
  final int toolCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryIcon(category: category),
              const Spacer(),
              Icon(
                Icons.north_east_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(category.label, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            category.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$toolCount ${toolCount == 1 ? 'tool' : 'tools'}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
