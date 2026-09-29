import '../../../../core/formatting/number_formatting.dart';
import '../calculator_category.dart';
import '../calculator_definition.dart';
import '../calculation_context.dart';
import '../numeric_mode.dart';
import '../engines/electrical.dart';

CalculatorDefinition createDcPowerDefinition() {
  final voltage = CalculatorInput(
    id: 'voltage',
    label: 'Voltage',
    units: [
      EngineeringUnit.volt,
      EngineeringUnit.kilovolt,
      EngineeringUnit.millivolt,
    ],
  );
  final current = CalculatorInput(
    id: 'current',
    label: 'Current',
    units: [EngineeringUnit.ampere, EngineeringUnit.milliampere],
  );
  final power = CalculatorInput(
    id: 'power',
    label: 'Power',
    units: [EngineeringUnit.watt, EngineeringUnit.kilowatt],
  );
  final mode0 = numericMode(
    id: 'power',
    label: 'Power (P)',
    formula: 'P = V × I',
    inputs: [voltage, current],
    unit: EngineeringUnit.watt,
    solve: (v) =>
        DcPower.power(voltage: v[voltage.id]!, current: v[current.id]!),
    substitution: (v) =>
        'P = ${NumberFormatting.operand(v[voltage.id]!)} V × ${NumberFormatting.operand(v[current.id]!)} A',
    explanation: (v, result) =>
        'The circuit transfers energy at a rate of $result W. A negative sign denotes delivered power.',
    alternateUnits: [EngineeringUnit.kilowatt],
  );
  final mode1 = numericMode(
    id: 'voltage',
    label: 'Voltage (V)',
    formula: 'V = P / I',
    inputs: [power, current],
    unit: EngineeringUnit.volt,
    solve: (v) => DcPower.voltage(power: v[power.id]!, current: v[current.id]!),
    substitution: (v) =>
        'V = ${NumberFormatting.operand(v[power.id]!)} W / ${NumberFormatting.operand(v[current.id]!)} A',
    explanation: (v, result) =>
        'A potential difference of $result V supports the specified DC power and current.',
    alternateUnits: [],
  );
  final mode2 = numericMode(
    id: 'current',
    label: 'Current (I)',
    formula: 'I = P / V',
    inputs: [power, voltage],
    unit: EngineeringUnit.ampere,
    solve: (v) => DcPower.current(power: v[power.id]!, voltage: v[voltage.id]!),
    substitution: (v) =>
        'I = ${NumberFormatting.operand(v[power.id]!)} W / ${NumberFormatting.operand(v[voltage.id]!)} V',
    explanation: (v, result) =>
        'A current of $result A transfers the specified power at this voltage.',
    alternateUnits: [],
  );
  return CalculatorDefinition(
    id: 'dc-power',
    name: 'Electrical Power DC',
    description: 'Relate DC voltage, current and power.',
    category: CalculatorCategory.electrical,
    formula: mode0.formula,
    explanation: 'Relate DC voltage, current and power.',
    inputs: mode0.inputs,
    modes: [mode0, mode1, mode2],
    assumptions: [
      'Constant DC values; positive power means absorption under the passive sign convention.',
      'Current is referenced into the positive-voltage terminal. AC phase, power factor and time-varying waveforms are outside this DC model.',
    ],
    keywords: ['dc', 'watts', 'voltage', 'current'],
  );
}

CalculatorDefinition createElectricalEnergyDefinition() {
  final power = CalculatorInput(
    id: 'power',
    label: 'Power',
    units: [EngineeringUnit.watt, EngineeringUnit.kilowatt],
  );
  final time = CalculatorInput(
    id: 'time',
    label: 'Time',
    units: [
      EngineeringUnit.second,
      EngineeringUnit.minute,
      EngineeringUnit.hour,
    ],
  );
  final mode0 = numericMode(
    id: 'energy',
    label: 'Energy (E)',
    formula: 'E = P × t',
    inputs: [power, time],
    unit: EngineeringUnit.joule,
    solve: (v) =>
        ElectricalEnergy.calculate(power: v[power.id]!, time: v[time.id]!),
    substitution: (v) =>
        'E = ${NumberFormatting.operand(v[power.id]!)} W × ${NumberFormatting.operand(v[time.id]!)} s',
    explanation: (v, result) =>
        'The device uses $result J during this interval. Wh and kWh describe the same energy, not power.',
    alternateUnits: [EngineeringUnit.wattHour, EngineeringUnit.kilowattHour],
  );
  return CalculatorDefinition(
    id: 'electrical-energy',
    name: 'Electrical Energy',
    description: 'Convert constant power and duration into energy.',
    category: CalculatorCategory.electrical,
    formula: mode0.formula,
    explanation: 'Convert constant power and duration into energy.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Assumes constant, nonnegative power over the time interval.',
      'The result is energy, not power. Time-varying consumption and electricity tariffs are not calculated.',
    ],
    keywords: ['electricity', 'consumption', 'kwh', 'duration'],
  );
}

CalculatorDefinition createVoltageDividerDefinition() {
  final voltage = CalculatorInput(
    id: 'voltage',
    label: 'Voltage',
    units: [
      EngineeringUnit.volt,
      EngineeringUnit.kilovolt,
      EngineeringUnit.millivolt,
    ],
  );
  final r1 = CalculatorInput(
    id: 'r1',
    label: 'R1',
    units: [
      EngineeringUnit.ohm,
      EngineeringUnit.kiloohm,
      EngineeringUnit.megaohm,
    ],
  );
  final r2 = CalculatorInput(
    id: 'r2',
    label: 'R2',
    units: [
      EngineeringUnit.ohm,
      EngineeringUnit.kiloohm,
      EngineeringUnit.megaohm,
    ],
  );
  final mode0 = numericMode(
    id: 'output',
    label: 'Output voltage',
    context: (v) => DividerContext(
      CalculatedInput(voltage, v[voltage.id]!, EngineeringUnit.volt),
      CalculatedInput(r1, v[r1.id]!, EngineeringUnit.ohm),
      CalculatedInput(r2, v[r2.id]!, EngineeringUnit.ohm),
    ),
    formula: 'Vout = Vin × R2 / (R1 + R2)',
    inputs: [voltage, r1, r2],
    unit: EngineeringUnit.volt,
    solve: (v) => VoltageDivider.calculate(
      voltage: v[voltage.id]!,
      r1: v[r1.id]!,
      r2: v[r2.id]!,
    ),
    substitution: (v) =>
        'Vout = ${NumberFormatting.operand(v[voltage.id]!)} V × ${NumberFormatting.operand(v[r2.id]!)} Ω / (${NumberFormatting.operand(v[r1.id]!)} Ω + ${NumberFormatting.operand(v[r2.id]!)} Ω)',
    explanation: (v, result) =>
        'The unloaded output is $result V. Connecting a load changes the equivalent lower resistance.',
    alternateUnits: [],
  );
  return CalculatorDefinition(
    id: 'voltage-divider',
    supportsPlayground: true,
    supportsVisualLearning: true,
    name: 'Voltage Divider',
    description: 'Find the output across the lower resistor R2.',
    category: CalculatorCategory.electrical,
    formula: mode0.formula,
    explanation: 'Find the output across the lower resistor R2.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Assumes an unloaded, ideal two-resistor divider; output is measured across R2.',
      'The resistor ratio sets the ideal output. A connected load, source resistance and resistor tolerances can change it; these effects are not included.',
    ],
    keywords: ['divider', 'resistors', 'voltage', 'output'],
  );
}
