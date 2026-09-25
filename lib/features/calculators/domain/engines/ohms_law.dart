import '../calculation_outcome.dart';

enum OhmVariable { voltage, current, resistance }

/// Inputs/outputs are SI (V, A, Ω). Passive, nonnegative resistance convention.
abstract final class OhmsLaw {
  static CalculationOutcome<double> current({
    required double voltage,
    required double resistance,
  }) {
    final issues = finiteInputIssues({
      OhmVariable.voltage.name: voltage,
      OhmVariable.resistance.name: resistance,
    });
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (resistance <= 0) {
      return calculationFailure(
        resistance == 0
            ? CalculationError.divisionByZero
            : CalculationError.outOfDomain,
        'Resistance must be greater than zero to calculate current.',
        fieldId: OhmVariable.resistance.name,
      );
    }
    return checkedResult(voltage / resistance, zeroExpected: voltage == 0);
  }

  static CalculationOutcome<double> voltage({
    required double current,
    required double resistance,
  }) {
    final issues = finiteInputIssues({
      OhmVariable.current.name: current,
      OhmVariable.resistance.name: resistance,
    });
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (resistance < 0) {
      return calculationFailure(
        CalculationError.outOfDomain,
        'Passive resistance cannot be negative.',
        fieldId: OhmVariable.resistance.name,
      );
    }
    return checkedResult(
      current * resistance,
      zeroExpected: current == 0 || resistance == 0,
    );
  }

  static CalculationOutcome<double> resistance({
    required double voltage,
    required double current,
  }) {
    final issues = finiteInputIssues({
      OhmVariable.voltage.name: voltage,
      OhmVariable.current.name: current,
    });
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (current == 0) {
      return calculationFailure(
        CalculationError.divisionByZero,
        'Current must be nonzero to calculate resistance.',
        fieldId: OhmVariable.current.name,
      );
    }
    if (voltage != 0 && voltage.isNegative != current.isNegative) {
      return calculationFailure(
        CalculationError.outOfDomain,
        'For a passive resistor, voltage and current must have the same sign.',
        fieldId: OhmVariable.voltage.name,
      );
    }
    return checkedResult(voltage / current, zeroExpected: voltage == 0);
  }
}
