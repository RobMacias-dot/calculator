import 'dart:math' as math;

import 'package:engineering_toolkit/core/formatting/number_formatting.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';

/// Tiny dependency-free assertions so the SAME formula cases run on Dart/Flutter.
void checkEqual(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('Expected $expected; received $actual.');
  }
}

void checkClose(double actual, double expected) {
  final tolerance = math.max(
    NumberFormatting.absoluteTolerance,
    expected.abs() * NumberFormatting.relativeTolerance,
  );
  if (!actual.isFinite || (actual - expected).abs() > tolerance) {
    throw StateError('Expected $expected ± $tolerance; received $actual.');
  }
}

T successValue<T>(CalculationOutcome<T> outcome) => switch (outcome) {
  CalculationSuccess<T>(:final value) => value,
  CalculationFailure<T>(:final issues) => throw StateError(
    'Unexpected failure: ${issues.map((issue) => issue.message).join(', ')}',
  ),
};

void checkFailure<T>(CalculationOutcome<T> outcome, CalculationError code) {
  if (outcome is! CalculationFailure<T> ||
      !outcome.issues.any((issue) => issue.code == code)) {
    throw StateError('Expected $code; received $outcome.');
  }
}
