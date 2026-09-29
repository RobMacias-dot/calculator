abstract final class NumberFormatting {
  static const maxDecimals = 6;
  static const scientificLowerBound = 0.000001;
  static const scientificUpperBound = 1000000000;
  static const relativeTolerance = 1e-10;
  static const absoluteTolerance = 1e-12;

  /// Substituted operands must describe the actual normalized inputs, especially
  /// when nearly equal values are subtracted. Keep the compact form only when
  /// it round-trips; this does not change rounding of ordinary results.
  static String operand(double value) {
    final compact = format(value);
    if (!value.isFinite || double.parse(compact) == value) return compact;
    return value.toString();
  }

  /// Never feeds back into calculations. Nonfinite values are not valid results.
  static String format(double value) {
    if (!value.isFinite) return 'Not representable';
    if (value == 0) return '0';
    final magnitude = value.abs();
    if (magnitude < scientificLowerBound || magnitude >= scientificUpperBound) {
      final parts = value.toStringAsExponential(maxDecimals).split('e');
      return '${_trim(parts.first)}e${int.parse(parts.last)}';
    }
    return _trim(value.toStringAsFixed(maxDecimals));
  }

  static String _trim(String value) => value.contains('.')
      ? value.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : value;
}
