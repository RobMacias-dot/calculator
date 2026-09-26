import '../../../../core/formatting/number_formatting.dart';
import '../calculator_category.dart';
import '../calculation_context.dart';
import '../calculator_definition.dart';
import '../engines/ideal_gas_law.dart';
import '../numeric_mode.dart';

CalculatorDefinition createIdealGasDefinition() {
  final pressure = CalculatorInput(
    id: GasVariable.pressure.name,
    label: 'Absolute pressure',
    units: [
      EngineeringUnit.pascal,
      EngineeringUnit.kilopascal,
      EngineeringUnit.bar,
      EngineeringUnit.atmosphere,
    ],
    minimum: 0,
    minimumExclusive: true,
  );
  final volume = CalculatorInput(
    id: GasVariable.volume.name,
    label: 'Volume',
    units: [EngineeringUnit.cubicMetre, EngineeringUnit.litre],
    minimum: 0,
    minimumExclusive: true,
  );
  final amount = CalculatorInput(
    id: GasVariable.amount.name,
    label: 'Amount of substance',
    units: [EngineeringUnit.mole],
    minimum: 0,
    minimumExclusive: true,
  );
  final temperature = CalculatorInput(
    id: GasVariable.temperature.name,
    label: 'Absolute temperature',
    units: [EngineeringUnit.kelvin, EngineeringUnit.celsius],
    minimum: 0,
    minimumExclusive: true,
  );
  String f(NormalizedValues values, CalculatorInput input) =>
      NumberFormatting.format(values[input.id]!);
  IdealGasContext context(GasVariable solved, NormalizedValues values) =>
      IdealGasContext(solved, [
        for (final field in [pressure, volume, amount, temperature])
          if (field.id != solved.name)
            CalculatedInput(field, values[field.id]!, field.units.first),
      ]);
  const rText = '${IdealGasLaw.gasConstant} Pa·m³/(mol·K)';
  const warnings = [
    'Ideal gas approximation. Use absolute pressure, not gauge pressure. Real gases may deviate from this model.',
  ];
  final modes = [
    numericMode(
      id: GasVariable.pressure.name,
      context: (v) => context(GasVariable.pressure, v),
      label: 'Pressure (P)',
      formula: 'P = n × R × T / V',
      inputs: [amount, temperature, volume],
      unit: EngineeringUnit.pascal,
      solve: (v) => IdealGasLaw.pressure(
        amount: v[amount.id]!,
        temperature: v[temperature.id]!,
        volume: v[volume.id]!,
      ),
      substitution: (v) =>
          'P = (${f(v, amount)} mol × $rText × ${f(v, temperature)} K) / ${f(v, volume)} m³',
      explanation: (v, result) =>
          '${f(v, amount)} mol at ${f(v, temperature)} K in ${f(v, volume)} m³ has an ideal absolute pressure of $result Pa.',
      warnings: warnings,
    ),
    numericMode(
      id: GasVariable.volume.name,
      context: (v) => context(GasVariable.volume, v),
      label: 'Volume (V)',
      formula: 'V = n × R × T / P',
      inputs: [amount, temperature, pressure],
      unit: EngineeringUnit.cubicMetre,
      solve: (v) => IdealGasLaw.volume(
        amount: v[amount.id]!,
        temperature: v[temperature.id]!,
        pressure: v[pressure.id]!,
      ),
      substitution: (v) =>
          'V = (${f(v, amount)} mol × $rText × ${f(v, temperature)} K) / ${f(v, pressure)} Pa',
      explanation: (v, result) =>
          '${f(v, amount)} mol at ${f(v, temperature)} K and ${f(v, pressure)} Pa occupies an ideal volume of $result m³.',
      warnings: warnings,
    ),
    numericMode(
      id: GasVariable.amount.name,
      context: (v) => context(GasVariable.amount, v),
      label: 'Amount (n)',
      formula: 'n = P × V / (R × T)',
      inputs: [pressure, volume, temperature],
      unit: EngineeringUnit.mole,
      solve: (v) => IdealGasLaw.amount(
        pressure: v[pressure.id]!,
        volume: v[volume.id]!,
        temperature: v[temperature.id]!,
      ),
      substitution: (v) =>
          'n = (${f(v, pressure)} Pa × ${f(v, volume)} m³) / ($rText × ${f(v, temperature)} K)',
      explanation: (v, result) =>
          '${f(v, volume)} m³ at ${f(v, pressure)} Pa and ${f(v, temperature)} K contains $result mol in the ideal gas model.',
      warnings: warnings,
    ),
    numericMode(
      id: GasVariable.temperature.name,
      context: (v) => context(GasVariable.temperature, v),
      label: 'Temperature (T)',
      formula: 'T = P × V / (n × R)',
      inputs: [pressure, volume, amount],
      unit: EngineeringUnit.kelvin,
      solve: (v) => IdealGasLaw.temperature(
        pressure: v[pressure.id]!,
        volume: v[volume.id]!,
        amount: v[amount.id]!,
      ),
      substitution: (v) =>
          'T = (${f(v, pressure)} Pa × ${f(v, volume)} m³) / (${f(v, amount)} mol × $rText)',
      explanation: (v, result) =>
          '${f(v, amount)} mol at ${f(v, pressure)} Pa in ${f(v, volume)} m³ has an ideal absolute temperature of $result K.',
      warnings: warnings,
    ),
  ];
  return CalculatorDefinition(
    id: 'ideal-gas-law',
    supportsPlayground: true,
    supportsVisualLearning: true,
    name: 'Ideal Gas Law',
    description: 'Solve absolute pressure, volume, amount or temperature.',
    category: CalculatorCategory.thermodynamics,
    formula: modes.first.formula,
    explanation: 'PV = nRT. Use a positive amount of gas, volume, absolute pressure and absolute temperature.',
    inputs: modes.first.inputs,
    modes: modes,
    keywords: ['pressure', 'volume', 'temperature', 'moles', 'gas'],
  );
}
