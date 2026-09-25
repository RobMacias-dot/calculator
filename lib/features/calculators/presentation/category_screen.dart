import 'package:flutter/material.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/glass_card.dart';
import '../domain/calculator_category.dart';
import '../domain/calculator_definition.dart';
import 'calculator_tile.dart';
import '../../preferences/preferences_controller.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({
    super.key,
    required this.category,
    required this.calculators,
    required this.onBack,
    required this.onCalculator,
    required this.preferences,
  });
  final CalculatorCategory category;
  final List<CalculatorDefinition> calculators;
  final VoidCallback onBack;
  final ValueChanged<CalculatorDefinition> onCalculator;
  final PreferencesController preferences;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                category.label,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                category.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${calculators.length} ${calculators.length == 1 ? 'tool' : 'tools'}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
      if (calculators.isEmpty)
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: GlassCard(
              child: Text(
                'New possibilities ahead. Tools for this field will be added in a future update.',
              ),
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverList.builder(
          itemCount: calculators.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: CalculatorTile(
              definition: calculators[index],
              preferences: preferences,
              onTap: () => onCalculator(calculators[index]),
            ),
          ),
        ),
      ),
    ],
  );
}
