import 'calculation_outcome.dart';
import 'calculation_result.dart';
import 'calculator_input.dart';
import 'engineering_unit.dart';

typedef CalculateInputs = CalculationOutcome<CalculationResult> Function(
  Map<String, String> values,
  Map<String, EngineeringUnit> units,
);

/// Selection chooses a callback, never parses a formula or an operation string.
class CalculatorMode {
  CalculatorMode({
    required this.id,
    required this.label,
    required this.formula,
    required List<CalculatorInput> inputs,
    required this.calculate,
    this.inputHint =
        'Use a dot or comma for decimals. No thousands separators.',
  }) : inputs = List.unmodifiable(inputs) {
    if (id.isEmpty ||
        label.isEmpty ||
        inputs.isEmpty ||
        inputs.map((input) => input.id).toSet().length != inputs.length) {
      throw ArgumentError(
        'A mode needs an id, label and uniquely identified inputs.',
      );
    }
  }

  final String id;
  final String label;
  final String formula;
  final List<CalculatorInput> inputs;
  final CalculateInputs calculate;
  final String inputHint;
}
