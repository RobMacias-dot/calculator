import 'engineering_unit.dart';
import 'calculation_context.dart';

/// Flutter-independent display report, assembled only AFTER the pure solver.
/// Numeric engines return unrounded values; structured engines need not supply one.
class CalculationResult {
  CalculationResult({
    this.value,
    this.unit,
    this.resultLabel,
    this.context,
    required this.formattedValue,
    required this.formula,
    required this.substitution,
    required this.explanation,
    List<String> warnings = const [],
    List<ResultDetail> details = const [],
  }) : warnings = List.unmodifiable(warnings),
       details = List.unmodifiable(details);

  final double? value;
  final EngineeringUnit? unit;
  final String? resultLabel;
  final CalculationContext? context;
  final String formattedValue;
  final String formula;
  final String substitution;
  final String explanation;
  final List<String> warnings;
  final List<ResultDetail> details;
}

class ResultDetail {
  const ResultDetail(this.label, this.value);
  final String label;
  final String value;
}
