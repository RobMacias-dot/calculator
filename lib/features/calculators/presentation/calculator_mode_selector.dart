import 'package:flutter/material.dart';

import '../domain/calculator_mode.dart';
import 'calculator_view_model.dart';

/// Shared by the ordinary form and Playground; mode selection retains the
/// ViewModel's existing clear-inputs/clear-result behavior.
class CalculatorModeSelector extends StatelessWidget {
  const CalculatorModeSelector({super.key, required this.viewModel});
  final CalculatorViewModel viewModel;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<CalculatorMode>(
    key: ValueKey('solve-for-${viewModel.mode.id}'),
    initialValue: viewModel.mode,
    isExpanded: true,
    itemHeight: null,
    decoration: const InputDecoration(labelText: 'Solve for'),
    items: [
      for (final mode in viewModel.definition.modes)
        DropdownMenuItem(value: mode, child: Text(mode.label)),
    ],
    onChanged: (mode) {
      if (mode != null) viewModel.selectMode(mode);
    },
  );
}
