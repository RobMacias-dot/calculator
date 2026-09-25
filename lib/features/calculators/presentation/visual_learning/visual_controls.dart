import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../../../../core/formatting/number_formatting.dart';
import '../../domain/calculation_context.dart';
import '../../domain/calculation_outcome.dart';
import '../calculator_view_model.dart';
import 'visual_models.dart';

/// A bounded exploration control. Out-of-range manual values stay intact until
/// an explicit edit; only the thumb is clamped. Labels show the actual value.
class VisualInputControl extends StatelessWidget {
  const VisualInputControl({
    super.key,
    required this.input,
    required this.viewModel,
    required this.minimum,
    required this.maximum,
    this.label,
  });
  final CalculatedInput input;
  final CalculatorViewModel viewModel;
  final double minimum;
  final double maximum;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final title = label ?? input.input.label;
    final outside = input.baseValue < minimum || input.baseValue > maximum;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$title: ${quantityLabel(input)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Semantics(
            label: title,
            child: Slider(
              key: ValueKey('visual-control-${input.input.id}'),
              min: minimum,
              max: maximum,
              value: input.baseValue.clamp(minimum, maximum),
              semanticFormatterCallback: (value) =>
                  '${NumberFormatting.format(value)} ${input.baseUnit.symbol}',
              onChanged: (value) {
                // The form may use kV/kΩ, etc. Reuse its unit conversion, and
                // round-trip the number, never write a formatted/rounded label.
                final selected = viewModel.unitFor(input.input.id);
                if (selected == null) return;
                final converted = selected.fromBase(value);
                if (converted case CalculationSuccess<double>(:final value)) {
                  viewModel.updateAndCalculate(
                    input.input.id,
                    value.toString(),
                  );
                }
              },
            ),
          ),
          Text(
            'Explore ${NumberFormatting.format(minimum)} to ${NumberFormatting.format(maximum)} ${input.baseUnit.symbol}. '
            '${outside ? 'Manual value is outside this slider range and is retained until you adjust it.' : 'Use the main form for other values.'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
