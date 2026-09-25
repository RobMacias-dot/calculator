import 'package:flutter/material.dart';

import '../../../core/design_system/app_tokens.dart';
import '../domain/calculator_definition.dart';
import 'calculator_view_model.dart';

class CalculatorInputField extends StatelessWidget {
  const CalculatorInputField({
    super.key,
    required this.input,
    required this.viewModel,
  });
  final CalculatorInput input;
  final CalculatorViewModel viewModel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        key: ValueKey('input-${input.id}-${viewModel.revision}'),
        initialValue: viewModel.valueFor(input.id),
        onChanged: (value) => viewModel.setValue(input.id, value),
        keyboardType:
            input.kind == CalculatorInputKind.ipv4 ||
                input.kind == CalculatorInputKind.text
            ? TextInputType.text
            : TextInputType.numberWithOptions(
                decimal: input.kind == CalculatorInputKind.decimal,
                signed: true,
              ),
        textInputAction: TextInputAction.next,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: input.label,
          errorText: viewModel.errorFor(input.id),
          errorMaxLines: 4,
        ),
      ),
      if (input.units.length > 1) ...[
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<EngineeringUnit>(
          key: ValueKey('unit-${input.id}-${viewModel.revision}'),
          initialValue: viewModel.unitFor(input.id),
          isExpanded: true,
          itemHeight: null,
          decoration: InputDecoration(labelText: '${input.label} unit'),
          items: [
            for (final unit in input.units)
              DropdownMenuItem(value: unit, child: Text(unit.symbol)),
          ],
          onChanged: (unit) {
            if (unit != null) viewModel.setUnit(input.id, unit);
          },
        ),
      ] else if (input.units.isNotEmpty && input.units.single.symbol.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            'Unit: ${input.units.single.symbol}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ],
  );
}
