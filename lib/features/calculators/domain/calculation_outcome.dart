enum CalculationError {
  missingInput,
  invalidInput,
  divisionByZero,
  outOfDomain,
  nonFinite,
  numericRange,
  incompatibleUnit,
}

class CalculationIssue {
  const CalculationIssue(this.code, this.message, {this.fieldId});
  final CalculationError code;
  final String message;
  final String? fieldId;
}

sealed class CalculationOutcome<T> {
  const CalculationOutcome();
}

final class CalculationSuccess<T> extends CalculationOutcome<T> {
  const CalculationSuccess(this.value);
  final T value;
}

final class CalculationFailure<T> extends CalculationOutcome<T> {
  CalculationFailure(Iterable<CalculationIssue> issues)
    : issues = List.unmodifiable(issues);
  final List<CalculationIssue> issues;
}

CalculationFailure<T> calculationFailure<T>(
  CalculationError code,
  String message, {
  String? fieldId,
}) => CalculationFailure([CalculationIssue(code, message, fieldId: fieldId)]);

/// Exact zero checks are intentional: a small nonzero denominator is valid.
/// Tolerances are for comparisons/tests, never a substitute for domain bounds.
CalculationOutcome<double> checkedResult(
  double value, {
  required bool zeroExpected,
}) {
  if (!value.isFinite || (value == 0 && !zeroExpected)) {
    return calculationFailure(
      CalculationError.numericRange,
      'The result is outside the supported numeric range. Use less extreme values.',
    );
  }
  return CalculationSuccess(value == 0 ? 0 : value);
}

List<CalculationIssue> finiteInputIssues(Map<String, double> values) => [
  for (final entry in values.entries)
    if (!entry.value.isFinite)
      CalculationIssue(
        CalculationError.nonFinite,
        'Enter a finite number.',
        fieldId: entry.key,
      ),
];
