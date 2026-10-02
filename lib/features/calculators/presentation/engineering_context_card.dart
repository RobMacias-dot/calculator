import 'package:flutter/material.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/glass_card.dart';
import '../domain/calculator_definition.dart';
import '../domain/calculator_mode.dart';

/// The same model notes and disclosure in the form and Playground.
class EngineeringContextCard extends StatelessWidget {
  const EngineeringContextCard({
    super.key,
    required this.definition,
    required this.mode,
  });

  final CalculatorDefinition definition;
  final CalculatorMode mode;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: ExpansionTile(
      // A new mode starts closed; notes never depend on a numeric result.
      key: ValueKey('engineering-context-${mode.id}'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: AppSpacing.md),
      expansionAnimationStyle: AnimationStyle.noAnimation,
      title: const Text('Engineering context'),
      subtitle: const Text('Model assumptions and limitations'),
      children: [
        for (final note in [...definition.assumptions, ...mode.assumptions])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(note),
            ),
          ),
      ],
    ),
  );
}
