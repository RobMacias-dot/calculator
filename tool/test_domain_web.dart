import '../test/domain/all_calculation_cases.dart';

/// Compile with dart2js and run under Node to check web number semantics without
/// a browser/CanvasKit bootstrap. Successful execution exits without errors.
void main() {
  for (final entry in allCalculationCases().entries) {
    try {
      entry.value();
    } catch (error) {
      throw StateError('${entry.key}: $error');
    }
  }
}
