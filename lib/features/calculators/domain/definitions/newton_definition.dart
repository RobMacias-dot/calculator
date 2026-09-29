import '../../../../core/formatting/number_formatting.dart';
import '../calculator_category.dart';
import '../calculation_context.dart';
import '../calculator_definition.dart';
import '../engines/newtons_second_law.dart';
import '../numeric_mode.dart';

CalculatorDefinition createNewtonDefinition() {
  final mass = CalculatorInput(
    id: NewtonInput.mass.name,
    label: 'Mass',
    units: [EngineeringUnit.kilogram, EngineeringUnit.gram],
    minimum: 0,
  );
  final acceleration = CalculatorInput(
    id: NewtonInput.acceleration.name,
    label: 'Acceleration',
    units: [EngineeringUnit.acceleration],
  );
  final mode = numericMode(
    id: 'force',
    context: (v) => NewtonContext(
      CalculatedInput(mass, v[mass.id]!, EngineeringUnit.kilogram),
      CalculatedInput(
        acceleration,
        v[acceleration.id]!,
        EngineeringUnit.acceleration,
      ),
    ),
    label: 'Force (F)',
    formula: 'F = m × a',
    inputs: [mass, acceleration],
    unit: EngineeringUnit.newton,
    solve: (values) => NewtonsSecondLaw.force(
      mass: values[mass.id]!,
      acceleration: values[acceleration.id]!,
    ),
    substitution: (values) =>
        'F = ${NumberFormatting.operand(values[mass.id]!)} kg × ${NumberFormatting.operand(values[acceleration.id]!)} m/s²',
    explanation: (values, result) =>
        'A mass of ${NumberFormatting.operand(values[mass.id]!)} kg with acceleration ${NumberFormatting.operand(values[acceleration.id]!)} m/s² has a net force of $result N. The sign indicates direction along the chosen axis.',
  );
  return CalculatorDefinition(
    id: 'newtons-second-law',
    supportsVisualLearning: true,
    name: 'Newton’s Second Law',
    description: 'Connect mass and acceleration to net force.',
    category: CalculatorCategory.mechanical,
    formula: mode.formula,
    explanation: 'Net force is the product of constant mass and acceleration in an inertial frame.',
    inputs: mode.inputs,
    modes: [mode],
    assumptions: [
      'Classical motion with constant mass in an inertial frame. The result is the net force along the chosen axis, not an individual applied force.',
      'Gravity, friction and other forces are not added separately here; their combined effect is represented by the entered acceleration.',
    ],
    keywords: ['force', 'mass', 'acceleration', 'newton'],
  );
}
