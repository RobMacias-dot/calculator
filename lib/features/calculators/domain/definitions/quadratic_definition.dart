import '../../../../core/formatting/number_formatting.dart';
import '../calculation_outcome.dart';
import '../calculation_result.dart';
import '../calculator_category.dart';
import '../calculator_definition.dart';
import '../calculator_mode.dart';
import '../engines/mathematics.dart';
import '../parse_numeric_inputs.dart';

CalculatorDefinition createQuadraticDefinition() {
  final fields = [
    for (final id in ['a', 'b', 'c'])
      CalculatorInput(
        id: id,
        label: 'Coefficient $id',
        units: [EngineeringUnit.dimensionless],
      ),
  ];
  const formula = 'ax² + bx + c = 0';
  final mode = CalculatorMode(
    id: 'roots',
    label: 'Roots',
    formula: formula,
    inputs: fields,
    calculate: (raw, units) {
      final parsed = parseNumericInputs(fields, raw, units);
      if (parsed case CalculationFailure<Map<String, double>>(:final issues)) {
        return CalculationFailure(issues);
      }
      final v = (parsed as CalculationSuccess<Map<String, double>>).value;
      final solved = QuadraticEquation.solve(
        a: v['a']!,
        b: v['b']!,
        c: v['c']!,
      );
      if (solved case CalculationFailure<QuadraticRoots>(:final issues)) {
        return CalculationFailure(issues);
      }
      final roots = (solved as CalculationSuccess<QuadraticRoots>).value;
      final first = NumberFormatting.format(roots.firstReal);
      final second = NumberFormatting.format(roots.secondReal);
      final imaginary = NumberFormatting.format(roots.imaginaryMagnitude);
      final displayed = switch (roots.kind) {
        QuadraticRootKind.twoReal => 'x1 = $first\nx2 = $second',
        QuadraticRootKind.repeated => 'x = $first (double root)',
        QuadraticRootKind.complex =>
          'x1 = $first + ${imaginary}i\nx2 = $first − ${imaginary}i',
      };
      return CalculationSuccess(
        CalculationResult(
          formattedValue: displayed,
          resultLabel: 'Roots',
          formula: formula,
          substitution:
              '(${NumberFormatting.format(v['a']!)})x² + (${NumberFormatting.format(v['b']!)})x + (${NumberFormatting.format(v['c']!)}) = 0',
          explanation: switch (roots.kind) {
            QuadraticRootKind.twoReal => 'The discriminant is positive: the parabola crosses the x-axis at two real roots.',
            QuadraticRootKind.repeated => 'The discriminant is zero: the parabola touches the x-axis at one repeated real root.',
            QuadraticRootKind.complex => 'The discriminant is negative: there are no real x-axis crossings. The two complex roots are conjugates; i² = −1.',
          },
        ),
      );
    },
  );
  return CalculatorDefinition(
    id: 'quadratic-equation',
    name: 'Quadratic Equation',
    description: 'Find two real, repeated or complex roots.',
    category: CalculatorCategory.mathematics,
    formula: formula,
    explanation: 'The discriminant determines the kind of roots.',
    inputs: fields,
    modes: [mode],
    assumptions: [
      'Real coefficients with a ≠ 0. Results use finite floating-point arithmetic.',
    ],
    keywords: ['quadratic', 'polynomial', 'roots', 'complex', 'discriminant'],
  );
}
