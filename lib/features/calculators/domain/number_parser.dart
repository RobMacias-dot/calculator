import 'calculation_outcome.dart';

abstract final class NumberParser {
  static final _decimal = RegExp(
    r'^[+-]?(?:[0-9]+(?:[.,][0-9]*)?|[.,][0-9]+)(?:[eE][+-]?[0-9]+)?$',
  );

  /// A single comma is a decimal separator; grouping separators are unsupported.
  static CalculationOutcome<double> parse(
    String raw, {
    required String fieldId,
  }) {
    final text = raw.trim();
    if (text.isEmpty) {
      return calculationFailure(
        CalculationError.missingInput,
        'Enter a value.',
        fieldId: fieldId,
      );
    }
    if (!_decimal.hasMatch(text)) {
      final parsed = double.tryParse(text);
      return calculationFailure(
        parsed != null && !parsed.isFinite
            ? CalculationError.nonFinite
            : CalculationError.invalidInput,
        'Enter a finite decimal number, such as 12.5 or 1e3.',
        fieldId: fieldId,
      );
    }
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null || !value.isFinite) {
      return calculationFailure(
        CalculationError.nonFinite,
        'This number is too large. Enter a finite value.',
        fieldId: fieldId,
      );
    }
    final mantissa = text.split(RegExp('[eE]')).first;
    if (value == 0 && RegExp('[1-9]').hasMatch(mantissa)) {
      return calculationFailure(
        CalculationError.numericRange,
        'This number is too small to represent.',
        fieldId: fieldId,
      );
    }
    return CalculationSuccess(value);
  }
}
