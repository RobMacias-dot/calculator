import '../../../../core/formatting/number_formatting.dart';
import '../calculator_category.dart';
import '../calculator_definition.dart';
import '../calculation_context.dart';
import '../engines/reynolds_number.dart';
import '../numeric_mode.dart';

CalculatorDefinition createReynoldsDefinition() {
  final density = CalculatorInput(
    id: ReynoldsInput.density.name,
    label: 'Density',
    units: [EngineeringUnit.density],
    minimum: 0,
    minimumExclusive: true,
  );
  final speed = CalculatorInput(
    id: ReynoldsInput.speed.name,
    label: 'Speed',
    units: [EngineeringUnit.velocity],
    minimum: 0,
  );
  final length = CalculatorInput(
    id: ReynoldsInput.length.name,
    label: 'Characteristic length',
    units: [
      EngineeringUnit.metre,
      EngineeringUnit.centimetre,
      EngineeringUnit.millimetre,
    ],
    minimum: 0,
    minimumExclusive: true,
  );
  final viscosity = CalculatorInput(
    id: ReynoldsInput.viscosity.name,
    label: 'Dynamic viscosity',
    units: [
      EngineeringUnit.dynamicViscosity,
      EngineeringUnit.millipascalSecond,
    ],
    minimum: 0,
    minimumExclusive: true,
  );
  String f(NormalizedValues values, CalculatorInput input) =>
      NumberFormatting.format(values[input.id]!);
  final mode = numericMode(
    id: 'reynolds',
    label: 'Reynolds number (Re)',
    context: (v) => ReynoldsContext(
      CalculatedInput(speed, v[speed.id]!, EngineeringUnit.velocity),
    ),
    formula: 'Re = ρ × v × L / μ',
    inputs: [density, speed, length, viscosity],
    unit: EngineeringUnit.dimensionless,
    solve: (values) => ReynoldsNumber.calculate(
      density: values[density.id]!,
      speed: values[speed.id]!,
      length: values[length.id]!,
      viscosity: values[viscosity.id]!,
    ),
    substitution: (values) =>
        'Re = (${f(values, density)} kg/m³ × ${f(values, speed)} m/s × ${f(values, length)} m) / ${f(values, viscosity)} Pa·s',
    explanation: (_, result) =>
        'The Reynolds number is $result, a dimensionless ratio of inertial to viscous effects.',
    warnings: [
      'Flow-regime thresholds depend on geometry and conditions. This result does not apply a universal laminar/turbulent classification.',
    ],
  );
  return CalculatorDefinition(
    id: 'reynolds-number',
    supportsVisualLearning: true,
    name: 'Reynolds Number',
    description: 'Explore the balance of inertial and viscous forces.',
    category: CalculatorCategory.fluids,
    formula: mode.formula,
    explanation: 'Uses density, speed, characteristic length and dynamic viscosity in SI units.',
    inputs: mode.inputs,
    modes: [mode],
    keywords: ['fluid', 'viscosity', 'density', 'flow'],
  );
}
