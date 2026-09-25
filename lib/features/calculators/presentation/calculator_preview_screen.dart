import 'package:flutter/material.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/detail_page.dart';
import '../../../core/design_system/glass_card.dart';
import '../domain/calculator_definition.dart';

class CalculatorPreviewScreen extends StatelessWidget {
  const CalculatorPreviewScreen({
    super.key,
    required this.definition,
    required this.onBack,
  });
  final CalculatorDefinition definition;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DetailPage(
      title: definition.name,
      subtitle: definition.description,
      onBack: onBack,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.construction_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  Text(
                    'Coming soon',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'This is a preview of the tool. Calculation and input validation will be available in the next phase.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The principle', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              SelectableText(
                definition.formula,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(definition.explanation),
              const Divider(),
              Text('Planned inputs', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final input in definition.inputs)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    '${input.label}${input.units.isEmpty ? '' : ' · ${input.units.map((unit) => unit.symbol).join(' / ')}'}',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
