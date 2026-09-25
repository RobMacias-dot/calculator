import '../calculation_outcome.dart';
import 'input_checks.dart';

abstract final class Torque {
  static CalculationOutcome<double> calculate({
    required double force,
    required double radius,
  }) {
    final issues = physicalInputIssues(
      {'force': force, 'radius': radius},
      nonNegative: {'force', 'radius'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return checkedResult(
      force * radius,
      zeroExpected: force == 0 || radius == 0,
    );
  }
}

abstract final class MechanicalWork {
  static CalculationOutcome<double> calculate({
    required double force,
    required double distance,
  }) {
    final issues = physicalInputIssues(
      {'force': force, 'distance': distance},
      nonNegative: {'distance'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return checkedResult(
      force * distance,
      zeroExpected: force == 0 || distance == 0,
    );
  }
}

abstract final class MechanicalPower {
  static CalculationOutcome<double> calculate({
    required double work,
    required double time,
  }) {
    final issues = physicalInputIssues(
      {'work': work, 'time': time},
      positive: {'time'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return checkedResult(work / time, zeroExpected: work == 0);
  }
}

abstract final class KineticEnergy {
  static CalculationOutcome<double> calculate({
    required double mass,
    required double speed,
  }) {
    final issues = physicalInputIssues(
      {'mass': mass, 'speed': speed},
      nonNegative: {'mass', 'speed'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (mass == 0 || speed == 0) return const CalculationSuccess(0);
    return checkedResult((mass * speed) * (speed / 2), zeroExpected: false);
  }
}

abstract final class Momentum {
  static CalculationOutcome<double> calculate({
    required double mass,
    required double velocity,
  }) {
    final issues = physicalInputIssues(
      {'mass': mass, 'velocity': velocity},
      nonNegative: {'mass'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return checkedResult(
      mass * velocity,
      zeroExpected: mass == 0 || velocity == 0,
    );
  }
}
