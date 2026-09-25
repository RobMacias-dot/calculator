import '../../../../core/formatting/number_formatting.dart';
import '../calculator_category.dart';
import '../calculator_definition.dart';
import '../engines/ohms_law.dart';
import '../numeric_mode.dart';

CalculatorDefinition createOhmDefinition() {
  final voltage = CalculatorInput(
    id: OhmVariable.voltage.name,
    label: 'Voltage',
    units: [
      EngineeringUnit.volt,
      EngineeringUnit.millivolt,
      EngineeringUnit.kilovolt,
    ],
  );
  final current = CalculatorInput(
    id: OhmVariable.current.name,
    label: 'Current',
    units: [
      EngineeringUnit.ampere,
      EngineeringUnit.milliampere,
      EngineeringUnit.kiloampere,
    ],
  );
  final resistance = CalculatorInput(
    id: OhmVariable.resistance.name,
    label: 'Resistance',
    units: [
      EngineeringUnit.ohm,
      EngineeringUnit.milliohm,
      EngineeringUnit.kiloohm,
      EngineeringUnit.megaohm,
    ],
    minimum: 0,
    minimumExclusive: true,
  );
  String v(NormalizedValues values) =>
      NumberFormatting.format(values[voltage.id]!);
  final nonnegativeResistance = CalculatorInput(
    id: resistance.id,
    label: resistance.label,
    units: resistance.units,
    minimum: 0,
  );
  String i(NormalizedValues values) =>
      NumberFormatting.format(values[current.id]!);
  String r(NormalizedValues values) =>
      NumberFormatting.format(values[resistance.id]!);

  final modes = [
    numericMode(
      id: OhmVariable.current.name,
      label: 'Current (I)',
      formula: 'I = V / R',
      inputs: [voltage, resistance],
      unit: EngineeringUnit.ampere,
      solve: (values) => OhmsLaw.current(
        voltage: values[voltage.id]!,
        resistance: values[resistance.id]!,
      ),
      substitution: (values) => 'I = ${v(values)} V / ${r(values)} Ω',
      explanation: (values, result) =>
          'A ${v(values)} V potential difference across a ${r(values)} Ω resistance produces a current of $result A.',
    ),
    numericMode(
      id: OhmVariable.voltage.name,
      label: 'Voltage (V)',
      formula: 'V = I × R',
      inputs: [current, nonnegativeResistance],
      unit: EngineeringUnit.volt,
      solve: (values) => OhmsLaw.voltage(
        current: values[current.id]!,
        resistance: values[resistance.id]!,
      ),
      substitution: (values) => 'V = ${i(values)} A × ${r(values)} Ω',
      explanation: (values, result) =>
          'A current of ${i(values)} A through ${r(values)} Ω produces a potential difference of $result V.',
    ),
    numericMode(
      id: OhmVariable.resistance.name,
      label: 'Resistance (R)',
      formula: 'R = V / I',
      inputs: [voltage, current],
      unit: EngineeringUnit.ohm,
      solve: (values) => OhmsLaw.resistance(
        voltage: values[voltage.id]!,
        current: values[current.id]!,
      ),
      substitution: (values) => 'R = ${v(values)} V / ${i(values)} A',
      explanation: (values, result) =>
          'A ${v(values)} V potential difference driving ${i(values)} A corresponds to a resistance of $result Ω.',
    ),
  ];
  return CalculatorDefinition(
    id: 'ohms-law',
    name: 'Ohm’s Law',
    description: 'Solve voltage, current or resistance from two known values.',
    category: CalculatorCategory.electrical,
    formula: modes.first.formula,
    explanation: 'Relates voltage, current and resistance in an ohmic conductor. Uses a passive resistor convention; signed voltage and current describe polarity.',
    inputs: modes.first.inputs,
    modes: modes,
    keywords: ['ohm', 'voltage', 'current', 'resistance', 'circuit'],
  );
}
