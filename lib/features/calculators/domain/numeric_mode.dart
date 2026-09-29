import '../../../core/formatting/number_formatting.dart';
import 'calculation_outcome.dart';
import 'calculation_result.dart';
import 'calculation_context.dart';
import 'calculator_definition.dart';
import 'calculator_mode.dart';
import 'parse_numeric_inputs.dart';

typedef NormalizedValues = Map<String, double>;

/// Reusable parsing/conversion/report boundary. Formulas live in typed solvers.
CalculatorMode numericMode({
  required String id,
  required String label,
  required String formula,
  required List<CalculatorInput> inputs,
  required EngineeringUnit unit,
  required CalculationOutcome<double> Function(NormalizedValues) solve,
  required String Function(NormalizedValues) substitution,
  required String Function(NormalizedValues, String) explanation,
  List<String> warnings = const [],
  List<String> assumptions = const [],
  List<EngineeringUnit> alternateUnits = const [],
  CalculationContext Function(NormalizedValues)? context,
}) {
  final fields = List<CalculatorInput>.unmodifiable(inputs);
  final notes = List<String>.unmodifiable(warnings);
  final alternatives = List<EngineeringUnit>.unmodifiable(alternateUnits);
  if (alternatives.any(
    (alternative) => alternative.dimension != unit.dimension,
  )) {
    throw ArgumentError('Output alternatives must share the result dimension.');
  }
  if (fields.any(
    (input) => input.kind != CalculatorInputKind.decimal || input.units.isEmpty,
  )) {
    throw ArgumentError('Numeric modes require decimal inputs with units.');
  }
  return CalculatorMode(
    id: id,
    label: label,
    formula: formula,
    inputs: fields,
    assumptions: assumptions,
    calculate: (raw, units) {
      final parsed = parseNumericInputs(fields, raw, units);
      if (parsed case CalculationFailure<Map<String, double>>(:final issues)) {
        return CalculationFailure(issues);
      }
      final normalized =
          (parsed as CalculationSuccess<Map<String, double>>).value;
      final solved = solve(normalized);
      if (solved case CalculationFailure<double>(:final issues)) {
        return CalculationFailure(issues);
      }
      final value = (solved as CalculationSuccess<double>).value;
      final displayed = unit.fromBase(value);
      if (displayed case CalculationFailure<double>(:final issues)) {
        return CalculationFailure(issues);
      }
      final formatted = NumberFormatting.format(
        (displayed as CalculationSuccess<double>).value,
      );
      return CalculationSuccess(
        CalculationResult(
          value: value,
          context: context?.call(normalized),
          unit: unit,
          formattedValue: formatted,
          formula: formula,
          substitution: substitution(normalized),
          explanation: explanation(normalized, formatted),
          warnings: notes,
          details: [
            for (final alternative in alternatives)
              ResultDetail('In ${alternative.symbol}', switch (alternative
                  .fromBase(value)) {
                CalculationSuccess<double>(value: final converted) =>
                  '${NumberFormatting.format(converted)} ${alternative.symbol}',
                CalculationFailure<double>() =>
                  'Outside supported numeric range',
              }),
          ],
        ),
      );
    },
  );
}
