import 'dart:math' as math;

import '../calculation_outcome.dart';
import 'input_checks.dart';

/// Conventional standard gravity, exactly 9.80665 m/s² (NIST SP 811).
const standardGravity = 9.80665;

abstract final class VolumetricFlow {
  static CalculationOutcome<double> area({
    required double area,
    required double velocity,
  }) {
    final issues = physicalInputIssues(
      {'area': area, 'velocity': velocity},
      positive: {'area'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return checkedResult(area * velocity, zeroExpected: velocity == 0);
  }

  static CalculationOutcome<double> pipe({
    required double diameter,
    required double velocity,
  }) {
    final issues = physicalInputIssues(
      {'diameter': diameter, 'velocity': velocity},
      positive: {'diameter'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (velocity == 0) return const CalculationSuccess(0);
    return checkedResult(
      (math.pi / 4) * diameter * diameter * velocity,
      zeroExpected: false,
    );
  }
}

abstract final class HydrostaticPressure {
  static CalculationOutcome<double> calculate({
    required double density,
    required double depth,
    double gravity = standardGravity,
  }) {
    final issues = physicalInputIssues(
      {'density': density, 'depth': depth, 'gravity': gravity},
      positive: {'density', 'gravity'},
      nonNegative: {'depth'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (depth == 0) return const CalculationSuccess(0);
    return checkedResult(density * gravity * depth, zeroExpected: false);
  }
}

abstract final class Bernoulli {
  /// P2 in the SAME reference as P1 (signed gauge pressures are allowed).
  static CalculationOutcome<double> pressure2({
    required double pressure1,
    required double density,
    required double speed1,
    required double speed2,
    required double height1,
    required double height2,
    double gravity = standardGravity,
  }) {
    final issues = physicalInputIssues(
      {
        'pressure1': pressure1,
        'density': density,
        'speed1': speed1,
        'speed2': speed2,
        'height1': height1,
        'height2': height2,
        'gravity': gravity,
      },
      positive: {'density', 'gravity'},
      nonNegative: {'speed1', 'speed2'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final kinetic = (0.5 * density * (speed1 - speed2)) * (speed1 + speed2);
    final potential = density * gravity * (height1 - height2);
    return checkedResult(pressure1 + kinetic + potential, zeroExpected: true);
  }
}
