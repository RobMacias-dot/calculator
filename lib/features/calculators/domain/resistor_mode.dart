import '../../../core/formatting/number_formatting.dart';
import 'calculation_outcome.dart';
import 'calculation_result.dart';
import 'calculator_input.dart';
import 'calculator_mode.dart';
import 'engineering_unit.dart';
import 'engines/electrical.dart';
import 'parse_numeric_inputs.dart';

/// Deliberately restricted to resistor lists, shared by series and parallel.
class ResistorMode extends CalculatorMode {
  ResistorMode({required bool parallel})
    : super(
        id: parallel ? 'parallel' : 'series',
        label: 'Total resistance',
        formula: parallel ? 'R = 1 / Σ(1/Ri)' : 'R = Σ Ri',
        inputs: [input(1), input(2)],
        calculate: (raw, units) => _calculate(raw, units, parallel),
      );

  static CalculatorInput input(int index) => CalculatorInput(
    id: 'r$index',
    label: 'Resistor $index',
    units: [
      EngineeringUnit.ohm,
      EngineeringUnit.kiloohm,
      EngineeringUnit.megaohm,
    ],
  );

  static CalculationOutcome<CalculationResult> _calculate(
    Map<String, String> raw,
    Map<String, EngineeringUnit> units,
    bool parallel,
  ) {
    final fields = [for (var i = 1; i <= raw.length; i++) input(i)];
    final parsed = parseNumericInputs(fields, raw, units);
    if (parsed case CalculationFailure<Map<String, double>>(:final issues)) {
      return CalculationFailure(issues);
    }
    final values = (parsed as CalculationSuccess<Map<String, double>>)
        .value
        .values
        .toList();
    final solved = parallel
        ? ResistanceNetwork.parallel(values)
        : ResistanceNetwork.series(values);
    if (solved case CalculationFailure<double>(:final issues)) {
      return CalculationFailure(issues);
    }
    final value = (solved as CalculationSuccess<double>).value;
    final terms = values
        .map((r) => '${NumberFormatting.operand(r)} Ω')
        .toList();
    return CalculationSuccess(
      CalculationResult(
        value: value,
        unit: EngineeringUnit.ohm,
        formattedValue: NumberFormatting.format(value),
        formula: parallel ? 'R = 1 / Σ(1/Ri)' : 'R = Σ Ri',
        substitution: parallel
            ? 'R = 1 / (${terms.map((r) => '1/($r)').join(' + ')})'
            : 'R = ${terms.join(' + ')}',
        explanation: parallel
            ? 'The equivalent resistance is smaller than every individual positive resistor because each branch adds a path for current.'
            : 'The same current passes through every resistor; their voltage drops add, so their resistances add.',
      ),
    );
  }
}
