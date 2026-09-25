import '../../../../core/formatting/number_formatting.dart';
import '../calculator_category.dart';
import '../calculator_definition.dart';
import '../calculation_context.dart';
import '../numeric_mode.dart';
import '../engines/mathematics.dart';

CalculatorDefinition createPercentageDefinition() {
  final percent = CalculatorInput(
    id: 'percent',
    label: 'Percentage X',
    units: [EngineeringUnit.percent],
  );
  final value = CalculatorInput(
    id: 'value',
    label: 'Value Y',
    units: [EngineeringUnit.dimensionless],
  );
  final initial = CalculatorInput(
    id: 'initial',
    label: 'Initial value',
    units: [EngineeringUnit.dimensionless],
  );
  final finalValue = CalculatorInput(
    id: 'finalValue',
    label: 'Final value',
    units: [EngineeringUnit.dimensionless],
  );
  final part = CalculatorInput(
    id: 'part',
    label: 'Part X',
    units: [EngineeringUnit.dimensionless],
  );
  final whole = CalculatorInput(
    id: 'whole',
    label: 'Whole Y',
    units: [EngineeringUnit.dimensionless],
  );
  final mode0 = numericMode(
    id: 'of',
    label: 'X% of Y',
    formula: 'Result = (X / 100) × Y',
    inputs: [percent, value],
    unit: EngineeringUnit.dimensionless,
    solve: (v) =>
        Percentages.ofValue(percent: v[percent.id]!, value: v[value.id]!),
    substitution: (v) =>
        'Result = ${NumberFormatting.format(v[percent.id]!)} × ${NumberFormatting.format(v[value.id]!)}',
    explanation: (v, result) =>
        'The selected fraction of the original quantity is $result.',
    alternateUnits: [],
  );
  final mode1 = numericMode(
    id: 'change',
    label: 'Percentage change',
    formula: 'Change = (final − initial) / initial × 100',
    inputs: [initial, finalValue],
    unit: EngineeringUnit.percent,
    solve: (v) => Percentages.change(
      initial: v[initial.id]!,
      finalValue: v[finalValue.id]!,
    ),
    substitution: (v) =>
        'Change = (${NumberFormatting.format(v[finalValue.id]!)} − ${NumberFormatting.format(v[initial.id]!)}) / ${NumberFormatting.format(v[initial.id]!)} × 100%',
    explanation: (v, result) =>
        'The relative change is $result% using the signed initial value as the reference.',
    alternateUnits: [],
  );
  final mode2 = numericMode(
    id: 'ratio',
    label: 'X is what % of Y',
    formula: 'Percentage = X / Y × 100',
    inputs: [part, whole],
    unit: EngineeringUnit.percent,
    solve: (v) => Percentages.ratio(part: v[part.id]!, whole: v[whole.id]!),
    substitution: (v) =>
        'Percentage = ${NumberFormatting.format(v[part.id]!)} / ${NumberFormatting.format(v[whole.id]!)} × 100%',
    explanation: (v, result) =>
        'The part represents $result% of the specified whole.',
    alternateUnits: [],
  );
  return CalculatorDefinition(
    id: 'percentage',
    name: 'Percentage Calculator',
    description: 'Calculate a share, relative change or percentage.',
    category: CalculatorCategory.mathematics,
    formula: mode0.formula,
    explanation: 'Calculate a share, relative change or percentage.',
    inputs: mode0.inputs,
    modes: [mode0, mode1, mode2],
    assumptions: [
      'Percentage change divides by the signed initial value, which must be nonzero.',
    ],
    keywords: ['percent', 'percentage', 'change', 'ratio'],
  );
}

CalculatorDefinition createPythagoreanDefinition() {
  final a = CalculatorInput(
    id: 'a',
    label: 'Leg a',
    units: [EngineeringUnit.metre, EngineeringUnit.centimetre],
  );
  final b = CalculatorInput(
    id: 'b',
    label: 'Leg b',
    units: [EngineeringUnit.metre, EngineeringUnit.centimetre],
  );
  final c = CalculatorInput(
    id: 'c',
    label: 'Hypotenuse c',
    units: [EngineeringUnit.metre, EngineeringUnit.centimetre],
  );
  final mode0 = numericMode(
    id: 'c',
    label: 'Hypotenuse (c)',
    formula: 'c = √(a² + b²)',
    inputs: [a, b],
    unit: EngineeringUnit.metre,
    solve: (v) => Pythagoras.hypotenuse(a: v[a.id]!, b: v[b.id]!),
    substitution: (v) =>
        'c = √((${NumberFormatting.format(v[a.id]!)} m)² + (${NumberFormatting.format(v[b.id]!)} m)²)',
    explanation: (v, result) =>
        'The side opposite the right angle is $result m long.',
    alternateUnits: [],
  );
  final mode1 = numericMode(
    id: 'a',
    label: 'Leg (a)',
    formula: 'a = √(c² − b²)',
    inputs: [c, b],
    unit: EngineeringUnit.metre,
    solve: (v) =>
        Pythagoras.leg(c: v[c.id]!, knownLeg: v[b.id]!, fieldId: b.id),
    substitution: (v) =>
        'a = √((${NumberFormatting.format(v[c.id]!)} m)² − (${NumberFormatting.format(v[b.id]!)} m)²)',
    explanation: (v, result) =>
        'The missing perpendicular leg is $result m long.',
    alternateUnits: [],
  );
  final mode2 = numericMode(
    id: 'b',
    label: 'Leg (b)',
    formula: 'b = √(c² − a²)',
    inputs: [c, a],
    unit: EngineeringUnit.metre,
    solve: (v) =>
        Pythagoras.leg(c: v[c.id]!, knownLeg: v[a.id]!, fieldId: a.id),
    substitution: (v) =>
        'b = √((${NumberFormatting.format(v[c.id]!)} m)² − (${NumberFormatting.format(v[a.id]!)} m)²)',
    explanation: (v, result) =>
        'The missing perpendicular leg is $result m long.',
    alternateUnits: [],
  );
  return CalculatorDefinition(
    id: 'pythagorean',
    name: 'Pythagorean Theorem',
    description: 'Solve a side of a right triangle.',
    category: CalculatorCategory.mathematics,
    formula: mode0.formula,
    explanation: 'Solve a side of a right triangle.',
    inputs: mode0.inputs,
    modes: [mode0, mode1, mode2],
    assumptions: [
      'A nondegenerate right triangle with strictly positive side lengths; c is the hypotenuse.',
    ],
    keywords: ['pythagoras', 'triangle', 'hypotenuse', 'geometry'],
  );
}

CalculatorDefinition createVectorDefinition() {
  final x = CalculatorInput(
    id: 'x',
    label: 'Component x',
    units: [EngineeringUnit.dimensionless],
  );
  final y = CalculatorInput(
    id: 'y',
    label: 'Component y',
    units: [EngineeringUnit.dimensionless],
  );
  final z = CalculatorInput(
    id: 'z',
    label: 'Component z',
    units: [EngineeringUnit.dimensionless],
  );
  final mode0 = numericMode(
    id: '2d',
    label: '2D vector',
    context: (v) => VectorContext([
      CalculatedInput(x, v[x.id]!, EngineeringUnit.dimensionless),
      CalculatedInput(y, v[y.id]!, EngineeringUnit.dimensionless),
    ]),
    formula: '|v| = √(x² + y²)',
    inputs: [x, y],
    unit: EngineeringUnit.dimensionless,
    solve: (v) => VectorMagnitude.calculate(x: v[x.id]!, y: v[y.id]!),
    substitution: (v) =>
        '|v| = √((${NumberFormatting.format(v[x.id]!)})² + (${NumberFormatting.format(v[y.id]!)})²)',
    explanation: (v, result) =>
        'The vector has length $result, independent of the signs of its components.',
    alternateUnits: [],
  );
  final mode1 = numericMode(
    id: '3d',
    label: '3D vector',
    context: (v) => VectorContext([
      CalculatedInput(x, v[x.id]!, EngineeringUnit.dimensionless),
      CalculatedInput(y, v[y.id]!, EngineeringUnit.dimensionless),
      CalculatedInput(z, v[z.id]!, EngineeringUnit.dimensionless),
    ]),
    formula: '|v| = √(x² + y² + z²)',
    inputs: [x, y, z],
    unit: EngineeringUnit.dimensionless,
    solve: (v) =>
        VectorMagnitude.calculate(x: v[x.id]!, y: v[y.id]!, z: v[z.id]!),
    substitution: (v) =>
        '|v| = √((${NumberFormatting.format(v[x.id]!)})² + (${NumberFormatting.format(v[y.id]!)})² + (${NumberFormatting.format(v[z.id]!)})²)',
    explanation: (v, result) =>
        'The vector has length $result in the same units as its three components.',
    alternateUnits: [],
  );
  return CalculatorDefinition(
    id: 'vector-magnitude',
    supportsVisualLearning: true,
    name: 'Vector Magnitude',
    description: 'Find the Euclidean length of a 2D or 3D vector.',
    category: CalculatorCategory.mathematics,
    formula: mode0.formula,
    explanation: 'Find the Euclidean length of a 2D or 3D vector.',
    inputs: mode0.inputs,
    modes: [mode0, mode1],
    assumptions: [
      'Components use a common unit and orthogonal axes. The magnitude has the same unit as the components.',
    ],
    keywords: ['vector', 'magnitude', 'norm', '2d', '3d'],
  );
}
