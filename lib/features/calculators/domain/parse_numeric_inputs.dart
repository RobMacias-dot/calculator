import 'calculation_outcome.dart';
import 'calculator_input.dart';
import 'engineering_unit.dart';
import 'number_parser.dart';

/// Shared by scalar reports, resistor lists and quadratic roots.
CalculationOutcome<Map<String, double>> parseNumericInputs(
  List<CalculatorInput> fields,
  Map<String, String> raw,
  Map<String, EngineeringUnit> units,
) {
  final values = <String, double>{};
  final issues = <CalculationIssue>[];
  for (final input in fields) {
    final parsed = NumberParser.parse(raw[input.id] ?? '', fieldId: input.id);
    switch (parsed) {
      case CalculationFailure<double>(issues: final parseIssues):
        issues.addAll(parseIssues);
      case CalculationSuccess<double>(value: final value):
        final selected = units[input.id] ?? input.units.first;
        if (!input.units.contains(selected)) {
          issues.add(
            CalculationIssue(
              CalculationError.incompatibleUnit,
              'Choose a supported unit.',
              fieldId: input.id,
            ),
          );
          continue;
        }
        switch (selected.toBase(value)) {
          case CalculationFailure<double>(issues: final conversionIssues):
            issues.addAll(
              conversionIssues.map(
                (issue) => CalculationIssue(
                  issue.code,
                  issue.message,
                  fieldId: input.id,
                ),
              ),
            );
          case CalculationSuccess<double>(value: final converted):
            values[input.id] = converted;
        }
    }
  }
  return issues.isEmpty
      ? CalculationSuccess(Map.unmodifiable(values))
      : CalculationFailure(issues);
}
