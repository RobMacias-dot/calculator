import '../../../../core/formatting/number_formatting.dart';
import '../calculator_category.dart';
import '../calculation_context.dart';
import '../calculator_definition.dart';
import '../numeric_mode.dart';
import '../engines/fluids.dart';

CalculatorDefinition createFlowDefinition() {
  final area = CalculatorInput(
    id: 'area',
    label: 'Cross-sectional area',
    units: [EngineeringUnit.squareMetre, EngineeringUnit.squareCentimetre],
  );
  final velocity = CalculatorInput(
    id: 'velocity',
    label: 'Signed velocity',
    units: [EngineeringUnit.velocity],
  );
  final mode0 = numericMode(
    id: 'flow',
    label: 'Volume flow',
    formula: 'Q = A × v',
    inputs: [area, velocity],
    unit: EngineeringUnit.cubicMetrePerSecond,
    solve: (v) =>
        VolumetricFlow.area(area: v[area.id]!, velocity: v[velocity.id]!),
    substitution: (v) =>
        'Q = ${NumberFormatting.operand(v[area.id]!)} m² × ${NumberFormatting.operand(v[velocity.id]!)} m/s',
    explanation: (v, result) =>
        'The signed volume crossing the section each second is $result m³.',
    alternateUnits: [
      EngineeringUnit.litrePerSecond,
      EngineeringUnit.litrePerMinute,
    ],
  );
  return CalculatorDefinition(
    id: 'volumetric-flow',
    name: 'Volumetric Flow Rate',
    description: 'Find volume flow from area and mean velocity.',
    category: CalculatorCategory.fluids,
    formula: mode0.formula,
    explanation: 'Find volume flow from area and mean velocity.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Velocity is the mean component normal to the cross-section; its sign gives flow direction.',
    ],
    keywords: ['flow', 'discharge', 'area', 'litres'],
  );
}

CalculatorDefinition createPipeFlowDefinition() {
  final diameter = CalculatorInput(
    id: 'diameter',
    label: 'Internal diameter',
    units: [
      EngineeringUnit.metre,
      EngineeringUnit.centimetre,
      EngineeringUnit.millimetre,
    ],
  );
  final velocity = CalculatorInput(
    id: 'velocity',
    label: 'Signed velocity',
    units: [EngineeringUnit.velocity],
  );
  final mode0 = numericMode(
    id: 'flow',
    label: 'Volume flow',
    formula: 'Q = (πD² / 4) × v',
    inputs: [diameter, velocity],
    unit: EngineeringUnit.cubicMetrePerSecond,
    solve: (v) => VolumetricFlow.pipe(
      diameter: v[diameter.id]!,
      velocity: v[velocity.id]!,
    ),
    substitution: (v) =>
        'Q = π × (${NumberFormatting.operand(v[diameter.id]!)} m)² / 4 × ${NumberFormatting.operand(v[velocity.id]!)} m/s',
    explanation: (v, result) =>
        'The pipe transports $result m³ per second through its circular section.',
    alternateUnits: [
      EngineeringUnit.litrePerSecond,
      EngineeringUnit.litrePerMinute,
    ],
  );
  return CalculatorDefinition(
    id: 'pipe-flow',
    name: 'Circular Pipe Flow',
    description: 'Find volume flow through a full circular pipe.',
    category: CalculatorCategory.fluids,
    formula: mode0.formula,
    explanation: 'Find volume flow through a full circular pipe.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Assumes a full circular pipe and mean axial velocity, not centreline velocity.',
      'Uses the internal diameter to obtain flow area. It does not predict velocity from pressure drop or include pipe friction; signed velocity sets flow direction.',
    ],
    keywords: ['pipe', 'diameter', 'discharge', 'velocity'],
  );
}

CalculatorDefinition createHydrostaticDefinition() {
  final density = CalculatorInput(
    id: 'density',
    label: 'Density',
    units: [EngineeringUnit.density],
  );
  final depth = CalculatorInput(
    id: 'depth',
    label: 'Depth below surface',
    units: [EngineeringUnit.metre, EngineeringUnit.centimetre],
  );
  final mode0 = numericMode(
    id: 'pressure',
    label: 'Pressure increase',
    formula: 'P = ρ × g × h',
    inputs: [density, depth],
    unit: EngineeringUnit.pascal,
    solve: (v) => HydrostaticPressure.calculate(
      density: v[density.id]!,
      depth: v[depth.id]!,
    ),
    substitution: (v) =>
        'P = ${NumberFormatting.operand(v[density.id]!)} kg/m³ × 9.80665 m/s² × ${NumberFormatting.operand(v[depth.id]!)} m',
    explanation: (v, result) =>
        'Pressure is $result Pa above the surface pressure. Add surface pressure separately for absolute pressure.',
    alternateUnits: [EngineeringUnit.kilopascal, EngineeringUnit.bar],
  );
  return CalculatorDefinition(
    id: 'hydrostatic-pressure',
    name: 'Hydrostatic Pressure',
    description: 'Find pressure increase below a liquid surface.',
    category: CalculatorCategory.fluids,
    formula: mode0.formula,
    explanation: 'Find pressure increase below a liquid surface.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Static fluid with constant density; g = 9.80665 m/s² (standard gravity). Reports pressure relative to the surface.',
      'Depth is measured downward from the surface. Surface pressure is not included; the result alone is not absolute pressure.',
    ],
    keywords: ['hydrostatic', 'depth', 'pressure', 'liquid'],
  );
}

CalculatorDefinition createBernoulliDefinition() {
  final pressure1 = CalculatorInput(
    id: 'pressure1',
    label: 'Upstream pressure P1',
    units: [
      EngineeringUnit.pascal,
      EngineeringUnit.kilopascal,
      EngineeringUnit.bar,
    ],
  );
  final density = CalculatorInput(
    id: 'density',
    label: 'Density',
    units: [EngineeringUnit.density],
  );
  final speed1 = CalculatorInput(
    id: 'speed1',
    label: 'Upstream speed v1',
    units: [EngineeringUnit.velocity],
  );
  final speed2 = CalculatorInput(
    id: 'speed2',
    label: 'Downstream speed v2',
    units: [EngineeringUnit.velocity],
  );
  final height1 = CalculatorInput(
    id: 'height1',
    label: 'Upstream elevation z1',
    units: [EngineeringUnit.metre],
  );
  final height2 = CalculatorInput(
    id: 'height2',
    label: 'Downstream elevation z2',
    units: [EngineeringUnit.metre],
  );
  final mode0 = numericMode(
    id: 'pressure2',
    context: (v) => BernoulliContext(
      CalculatedInput(pressure1, v[pressure1.id]!, EngineeringUnit.pascal),
      CalculatedInput(density, v[density.id]!, EngineeringUnit.density),
      CalculatedInput(speed1, v[speed1.id]!, EngineeringUnit.velocity),
      CalculatedInput(speed2, v[speed2.id]!, EngineeringUnit.velocity),
      CalculatedInput(height1, v[height1.id]!, EngineeringUnit.metre),
      CalculatedInput(height2, v[height2.id]!, EngineeringUnit.metre),
    ),
    label: 'Downstream pressure P2',
    formula: 'P2 = P1 + ½ρ(v1² − v2²) + ρg(z1 − z2)',
    inputs: [pressure1, density, speed1, speed2, height1, height2],
    unit: EngineeringUnit.pascal,
    solve: (v) => Bernoulli.pressure2(
      pressure1: v[pressure1.id]!,
      density: v[density.id]!,
      speed1: v[speed1.id]!,
      speed2: v[speed2.id]!,
      height1: v[height1.id]!,
      height2: v[height2.id]!,
    ),
    substitution: (v) =>
        'P2 = ${NumberFormatting.operand(v[pressure1.id]!)} Pa + ½ × ${NumberFormatting.operand(v[density.id]!)} kg/m³ × ((${NumberFormatting.operand(v[speed1.id]!)} m/s)² − (${NumberFormatting.operand(v[speed2.id]!)} m/s)²) + ${NumberFormatting.operand(v[density.id]!)} kg/m³ × 9.80665 m/s² × (${NumberFormatting.operand(v[height1.id]!)} − ${NumberFormatting.operand(v[height2.id]!)}) m',
    explanation: (v, result) =>
        'The model predicts $result Pa in the same pressure reference as P1. It does not account for cavitation, friction or energy added by machinery.',
    alternateUnits: [EngineeringUnit.kilopascal],
  );
  return CalculatorDefinition(
    id: 'bernoulli-basic',
    supportsVisualLearning: true,
    name: 'Bernoulli — Basic',
    description: 'Solve downstream pressure P2 along a streamline.',
    category: CalculatorCategory.fluids,
    formula: mode0.formula,
    explanation: 'Solve downstream pressure P2 along a streamline.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Assumes steady, incompressible, inviscid flow along the same streamline, with no pumps, turbines or friction losses.',
      'Uses g = 9.80665 m/s². Both pressures share the same reference; signed gauge pressures are allowed.',
      'Pressure, kinetic and elevation terms exchange along the streamline. Use one elevation datum for both stations; the result does not check cavitation or whether the assumed flow can be sustained.',
    ],
    keywords: ['bernoulli', 'streamline', 'pressure', 'fluid'],
  );
}
