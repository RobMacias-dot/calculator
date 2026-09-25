import '../calculation_outcome.dart';

/// Shared domain checks only; each solver still owns its explicit formula.
List<CalculationIssue> physicalInputIssues(
  Map<String, double> values, {
  Set<String> nonNegative = const {},
  Set<String> positive = const {},
  Set<String> nonZero = const {},
}) {
  final issues = finiteInputIssues(values);
  for (final entry in values.entries) {
    if (!entry.value.isFinite) continue;
    final id = entry.key;
    if ((positive.contains(id) && entry.value <= 0) ||
        (nonNegative.contains(id) && entry.value < 0) ||
        (nonZero.contains(id) && entry.value == 0)) {
      issues.add(
        CalculationIssue(
          entry.value == 0
              ? CalculationError.divisionByZero
              : CalculationError.outOfDomain,
          positive.contains(id)
              ? 'This quantity must be greater than zero.'
              : nonZero.contains(id)
              ? 'This quantity must be nonzero.'
              : 'This quantity must be zero or greater.',
          fieldId: id,
        ),
      );
    }
  }
  return issues;
}
