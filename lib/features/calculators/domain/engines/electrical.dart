import 'dart:math' as math;

import '../calculation_outcome.dart';
import 'input_checks.dart';

abstract final class DcPower {
  /// Signed DC power follows the passive sign convention.
  static CalculationOutcome<double> power({
    required double voltage,
    required double current,
  }) {
    final issues = finiteInputIssues({'voltage': voltage, 'current': current});
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return checkedResult(
      voltage * current,
      zeroExpected: voltage == 0 || current == 0,
    );
  }

  static CalculationOutcome<double> voltage({
    required double power,
    required double current,
  }) {
    final issues = physicalInputIssues(
      {'power': power, 'current': current},
      nonZero: {'current'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return checkedResult(power / current, zeroExpected: power == 0);
  }

  static CalculationOutcome<double> current({
    required double power,
    required double voltage,
  }) {
    final issues = physicalInputIssues(
      {'power': power, 'voltage': voltage},
      nonZero: {'voltage'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return checkedResult(power / voltage, zeroExpected: power == 0);
  }
}

abstract final class ElectricalEnergy {
  static CalculationOutcome<double> calculate({
    required double power,
    required double time,
  }) {
    final issues = physicalInputIssues(
      {'power': power, 'time': time},
      nonNegative: {'power', 'time'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return checkedResult(power * time, zeroExpected: power == 0 || time == 0);
  }
}

abstract final class ResistanceNetwork {
  static CalculationOutcome<double> series(List<double> resistances) {
    final issues = _issues(resistances, positive: false);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return checkedResult(
      resistances.fold(0.0, (sum, value) => sum + value),
      zeroExpected: resistances.every((r) => r == 0),
    );
  }

  static CalculationOutcome<double> parallel(List<double> resistances) {
    final issues = _issues(resistances, positive: true);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    // Scale conductances to avoid overflowing 1/R for very small resistors.
    final smallest = resistances.reduce(math.min);
    final sum = resistances.fold(0.0, (sum, r) => sum + smallest / r);
    return checkedResult(smallest / sum, zeroExpected: false);
  }

  static List<CalculationIssue> _issues(
    List<double> values, {
    required bool positive,
  }) {
    if (values.length < 2) {
      return [
        const CalculationIssue(
          CalculationError.invalidInput,
          'Enter at least two resistors.',
        ),
      ];
    }
    return physicalInputIssues(
      {for (var i = 0; i < values.length; i++) 'r${i + 1}': values[i]},
      positive: positive
          ? {for (var i = 0; i < values.length; i++) 'r${i + 1}'}
          : {},
      nonNegative: !positive
          ? {for (var i = 0; i < values.length; i++) 'r${i + 1}'}
          : {},
    );
  }
}

abstract final class VoltageDivider {
  static CalculationOutcome<double> calculate({
    required double voltage,
    required double r1,
    required double r2,
  }) {
    final issues = physicalInputIssues(
      {'voltage': voltage, 'r1': r1, 'r2': r2},
      nonNegative: {'r1', 'r2'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (r1 == 0 && r2 == 0) {
      return calculationFailure(
        CalculationError.divisionByZero,
        'At least one resistance must be greater than zero.',
        fieldId: 'r2',
      );
    }
    final scale = math.max(r1, r2);
    return checkedResult(
      voltage * ((r2 / scale) / (r1 / scale + r2 / scale)),
      zeroExpected: voltage == 0 || r2 == 0,
    );
  }
}
