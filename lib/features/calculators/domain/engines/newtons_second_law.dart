import '../calculation_outcome.dart';

enum NewtonInput { mass, acceleration }

abstract final class NewtonsSecondLaw {
  /// Mass in kg; signed acceleration in m/s²; returns force in N.
  static CalculationOutcome<double> force({
    required double mass,
    required double acceleration,
  }) {
    final issues = finiteInputIssues({
      NewtonInput.mass.name: mass,
      NewtonInput.acceleration.name: acceleration,
    });
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (mass < 0) {
      return calculationFailure(
        CalculationError.outOfDomain,
        'Mass must be zero or greater.',
        fieldId: NewtonInput.mass.name,
      );
    }
    return checkedResult(
      mass * acceleration,
      zeroExpected: mass == 0 || acceleration == 0,
    );
  }
}
