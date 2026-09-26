import '../../../../core/formatting/number_formatting.dart';
import '../calculator_category.dart';
import '../calculation_context.dart';
import '../calculator_definition.dart';
import '../numeric_mode.dart';
import '../engines/mechanical.dart';

CalculatorDefinition createTorqueDefinition() {
  final force = CalculatorInput(
    id: 'force',
    label: 'Force',
    units: [EngineeringUnit.newton],
  );
  final radius = CalculatorInput(
    id: 'radius',
    label: 'Lever arm',
    units: [
      EngineeringUnit.metre,
      EngineeringUnit.centimetre,
      EngineeringUnit.millimetre,
    ],
  );
  final mode0 = numericMode(
    id: 'torque',
    context: (v) => TorqueContext(
      CalculatedInput(force, v[force.id]!, EngineeringUnit.newton),
      CalculatedInput(radius, v[radius.id]!, EngineeringUnit.metre),
    ),
    label: 'Torque (τ)',
    formula: 'τ = F × r',
    inputs: [force, radius],
    unit: EngineeringUnit.newtonMetre,
    solve: (v) => Torque.calculate(force: v[force.id]!, radius: v[radius.id]!),
    substitution: (v) =>
        'τ = ${NumberFormatting.format(v[force.id]!)} N × ${NumberFormatting.format(v[radius.id]!)} m',
    explanation: (v, result) =>
        'This force produces a turning moment of $result N·m about the pivot.',
    alternateUnits: [],
  );
  return CalculatorDefinition(
    id: 'torque',
    name: 'Torque',
    supportsVisualLearning: true,
    description: 'Find turning moment from perpendicular force.',
    category: CalculatorCategory.mechanical,
    formula: mode0.formula,
    explanation: 'Find turning moment from perpendicular force.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Assumes force is perpendicular to the lever arm. Reports the torque magnitude.',
    ],
    keywords: ['lever', 'moment', 'rotation'],
  );
}

CalculatorDefinition createWorkDefinition() {
  final force = CalculatorInput(
    id: 'force',
    label: 'Force',
    units: [EngineeringUnit.newton],
  );
  final distance = CalculatorInput(
    id: 'distance',
    label: 'Displacement magnitude',
    units: [EngineeringUnit.metre, EngineeringUnit.centimetre],
  );
  final mode0 = numericMode(
    id: 'work',
    label: 'Work (W)',
    formula: 'W = F × d',
    inputs: [force, distance],
    unit: EngineeringUnit.joule,
    solve: (v) => MechanicalWork.calculate(
      force: v[force.id]!,
      distance: v[distance.id]!,
    ),
    substitution: (v) =>
        'W = ${NumberFormatting.format(v[force.id]!)} N × ${NumberFormatting.format(v[distance.id]!)} m',
    explanation: (v, result) =>
        'The force transfers $result J over this displacement; negative work removes mechanical energy.',
    alternateUnits: [],
  );
  return CalculatorDefinition(
    id: 'mechanical-work',
    name: 'Work',
    description: 'Calculate work along a displacement.',
    category: CalculatorCategory.mechanical,
    formula: mode0.formula,
    explanation: 'Calculate work along a displacement.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Assumes a constant force parallel to displacement. Negative force means opposition to motion.',
    ],
    keywords: ['work', 'force', 'displacement'],
  );
}

CalculatorDefinition createMechanicalPowerDefinition() {
  final work = CalculatorInput(
    id: 'work',
    label: 'Work',
    units: [EngineeringUnit.joule, EngineeringUnit.kilojoule],
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
    id: 'power',
    label: 'Average power',
    formula: 'P = W / t',
    inputs: [work, time],
    unit: EngineeringUnit.watt,
    solve: (v) =>
        MechanicalPower.calculate(work: v[work.id]!, time: v[time.id]!),
    substitution: (v) =>
        'P = ${NumberFormatting.format(v[work.id]!)} J / ${NumberFormatting.format(v[time.id]!)} s',
    explanation: (v, result) =>
        'Work is transferred at an average rate of $result W during this interval.',
    alternateUnits: [EngineeringUnit.kilowatt],
  );
  return CalculatorDefinition(
    id: 'mechanical-power',
    name: 'Mechanical Power',
    description: 'Calculate the average rate of doing work.',
    category: CalculatorCategory.mechanical,
    formula: mode0.formula,
    explanation: 'Calculate the average rate of doing work.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Reports average power over a strictly positive time interval.',
    ],
    keywords: ['power', 'work', 'time'],
  );
}

CalculatorDefinition createKineticEnergyDefinition() {
  final mass = CalculatorInput(
    id: 'mass',
    label: 'Mass',
    units: [EngineeringUnit.kilogram, EngineeringUnit.gram],
  );
  final speed = CalculatorInput(
    id: 'speed',
    label: 'Speed',
    units: [EngineeringUnit.velocity],
  );
  final mode0 = numericMode(
    id: 'energy',
    label: 'Kinetic energy',
    formula: 'KE = ½ m v²',
    inputs: [mass, speed],
    unit: EngineeringUnit.joule,
    solve: (v) =>
        KineticEnergy.calculate(mass: v[mass.id]!, speed: v[speed.id]!),
    substitution: (v) =>
        'KE = ½ × ${NumberFormatting.format(v[mass.id]!)} kg × (${NumberFormatting.format(v[speed.id]!)} m/s)²',
    explanation: (v, result) =>
        'A ${NumberFormatting.format(v[mass.id]!)} kg object moving at ${NumberFormatting.format(v[speed.id]!)} m/s has $result J of kinetic energy.',
    alternateUnits: [],
  );
  return CalculatorDefinition(
    id: 'kinetic-energy',
    name: 'Kinetic Energy',
    description: 'Relate mass and speed to translational energy.',
    category: CalculatorCategory.mechanical,
    formula: mode0.formula,
    explanation: 'Relate mass and speed to translational energy.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Classical translational motion; assumes speeds much smaller than the speed of light.',
    ],
    keywords: ['kinetic', 'mass', 'speed', 'energy'],
  );
}

CalculatorDefinition createMomentumDefinition() {
  final mass = CalculatorInput(
    id: 'mass',
    label: 'Mass',
    units: [EngineeringUnit.kilogram, EngineeringUnit.gram],
  );
  final velocity = CalculatorInput(
    id: 'velocity',
    label: 'Signed velocity',
    units: [EngineeringUnit.velocity],
  );
  final mode0 = numericMode(
    id: 'momentum',
    label: 'Momentum (p)',
    formula: 'p = m × v',
    inputs: [mass, velocity],
    unit: EngineeringUnit.momentum,
    solve: (v) =>
        Momentum.calculate(mass: v[mass.id]!, velocity: v[velocity.id]!),
    substitution: (v) =>
        'p = ${NumberFormatting.format(v[mass.id]!)} kg × ${NumberFormatting.format(v[velocity.id]!)} m/s',
    explanation: (v, result) =>
        'The object has $result kg·m/s of momentum. Its sign follows the selected positive axis.',
    alternateUnits: [],
  );
  return CalculatorDefinition(
    id: 'momentum',
    name: 'Momentum',
    description: 'Calculate linear momentum along an axis.',
    category: CalculatorCategory.mechanical,
    formula: mode0.formula,
    explanation: 'Calculate linear momentum along an axis.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Classical motion along one chosen axis; velocity may be positive or negative.',
    ],
    keywords: ['momentum', 'mass', 'velocity'],
  );
}
