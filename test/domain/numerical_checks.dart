import 'dart:math' as math;

import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';

import 'phase4_cases.dart';

const binary64Epsilon = 2.220446049250313e-16;
const engineeringScales = [1e-12, 1e-9, 1e-6, 1e-3, 1.0, 1e3, 1e6, 1e9, 1e12];

// No default relative tolerance: each property must state its error budget.
void near(
  double actual,
  double expected, {
  required double relative,
  double absolute = 0,
  required String context,
}) {
  final bound = absolute + relative * math.max(actual.abs(), expected.abs());
  if (!actual.isFinite ||
      !expected.isFinite ||
      (actual - expected).abs() > bound) {
    throw StateError(
      '$context: expected $expected, received $actual; bound=$bound',
    );
  }
}

T valueOf<T>(CalculationOutcome<T> outcome, String context) =>
    switch (outcome) {
      CalculationSuccess<T>(:final value) => value,
      CalculationFailure<T>(:final issues) => throw StateError(
        '$context: ${issues.map((i) => '${i.code}: ${i.message}').join('; ')}',
      ),
    };

double modeValue(String id, String mode, Map<String, double> values) {
  final context = '$id/$mode $values';
  final result = valueOf(
    calculateNew(id, mode, values.map((k, v) => MapEntry(k, v.toString()))),
    context,
  );
  final value = result.value;
  if (value == null || !value.isFinite) {
    throw StateError('$context: nonfinite/missing numeric result');
  }
  return value;
}
