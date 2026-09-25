import '../calculation_outcome.dart';

enum ReynoldsInput { density, speed, length, viscosity }

abstract final class ReynoldsNumber {
  /// SI: kg/m³, m/s, m, Pa·s. Returns a dimensionless number, not a flow regime.
  static CalculationOutcome<double> calculate({
    required double density,
    required double speed,
    required double length,
    required double viscosity,
  }) {
    final values = {
      ReynoldsInput.density.name: density,
      ReynoldsInput.speed.name: speed,
      ReynoldsInput.length.name: length,
      ReynoldsInput.viscosity.name: viscosity,
    };
    final issues = finiteInputIssues(values);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    for (final input in [
      ReynoldsInput.density,
      ReynoldsInput.length,
      ReynoldsInput.viscosity,
    ]) {
      if (values[input.name]! <= 0) {
        issues.add(
          CalculationIssue(
            input == ReynoldsInput.viscosity && viscosity == 0
                ? CalculationError.divisionByZero
                : CalculationError.outOfDomain,
            'This quantity must be greater than zero.',
            fieldId: input.name,
          ),
        );
      }
    }
    if (speed < 0) {
      issues.add(
        CalculationIssue(
          CalculationError.outOfDomain,
          'Speed must be zero or greater. Use the magnitude of velocity.',
          fieldId: ReynoldsInput.speed.name,
        ),
      );
    }
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (speed == 0) return const CalculationSuccess(0);
    return checkedResult(
      density * speed * length / viscosity,
      zeroExpected: false,
    );
  }
}
