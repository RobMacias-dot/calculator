import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/glass_card.dart';
import '../domain/calculation_result.dart';

class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.result,
    required this.calculatorName,
  });
  final CalculationResult result;
  final String calculatorName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value =
        '${result.formattedValue}${result.unit == null || result.unit!.symbol.isEmpty ? '' : ' ${result.unit!.symbol}'}';
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Result', style: theme.textTheme.titleMedium),
              ),
              IconButton(
                tooltip: 'Copy result',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () async {
                  var message = 'Result copied';
                  final symbol =
                      result.resultLabel ??
                      result.formula.split('=').first.trim();
                  try {
                    await Clipboard.setData(
                      ClipboardData(
                        text:
                            '$calculatorName\n$symbol = $value\n${result.substitution}',
                      ),
                    );
                  } catch (_) {
                    message = 'Could not copy. Select the result to copy it.';
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(message)));
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: SelectableText(
              value,
              key: const ValueKey('result-value'),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const Divider(),
          for (final detail in result.details) ...[
            Text(detail.label, style: theme.textTheme.labelLarge),
            SelectableText(detail.value),
            const SizedBox(height: AppSpacing.md),
          ],
          Text('Formula', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(result.formula),
          const SizedBox(height: AppSpacing.md),
          Text('Substitution', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(result.substitution),
          const SizedBox(height: AppSpacing.md),
          Text('Explanation', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(result.explanation),
          for (final warning in result.warnings) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Note: $warning',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
