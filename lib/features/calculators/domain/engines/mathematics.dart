import 'dart:math' as math;

import '../calculation_outcome.dart';
import 'input_checks.dart';

abstract final class Percentages {
  static CalculationOutcome<double> ofValue({
    required double percent,
    required double value,
  }) {
    final issues = finiteInputIssues({'percent': percent, 'value': value});
    if (issues.isNotEmpty) return CalculationFailure(issues);
    // Percent input is already normalized to a dimensionless fraction.
    return checkedResult(
      percent * value,
      zeroExpected: percent == 0 || value == 0,
    );
  }

  static CalculationOutcome<double> change({
    required double initial,
    required double finalValue,
  }) {
    final issues = physicalInputIssues(
      {'initial': initial, 'finalValue': finalValue},
      nonZero: {'initial'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return checkedResult(
      (finalValue - initial) / initial,
      zeroExpected: finalValue == initial,
    );
  }

  static CalculationOutcome<double> ratio({
    required double part,
    required double whole,
  }) {
    final issues = physicalInputIssues(
      {'part': part, 'whole': whole},
      nonZero: {'whole'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return checkedResult(part / whole, zeroExpected: part == 0);
  }
}

abstract final class VectorMagnitude {
  static CalculationOutcome<double> calculate({
    required double x,
    required double y,
    double z = 0,
  }) {
    final issues = finiteInputIssues({'x': x, 'y': y, 'z': z});
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final scale = math.max(x.abs(), math.max(y.abs(), z.abs()));
    if (scale == 0) return const CalculationSuccess(0);
    final sx = x / scale, sy = y / scale, sz = z / scale;
    return checkedResult(
      scale * math.sqrt(sx * sx + sy * sy + sz * sz),
      zeroExpected: false,
    );
  }
}

abstract final class Pythagoras {
  static CalculationOutcome<double> hypotenuse({
    required double a,
    required double b,
  }) {
    final issues = physicalInputIssues({'a': a, 'b': b}, positive: {'a', 'b'});
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return VectorMagnitude.calculate(x: a, y: b);
  }

  static CalculationOutcome<double> leg({
    required double c,
    required double knownLeg,
    required String fieldId,
  }) {
    final issues = physicalInputIssues(
      {'c': c, fieldId: knownLeg},
      positive: {'c', fieldId},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (c <= knownLeg) {
      return calculationFailure(
        CalculationError.outOfDomain,
        'The hypotenuse must be longer than the known leg.',
        fieldId: 'c',
      );
    }
    return checkedResult(
      c * math.sqrt(((c - knownLeg) / c) * (1 + knownLeg / c)),
      zeroExpected: false,
    );
  }
}

enum QuadraticRootKind { twoReal, repeated, complex }

/// Just the roots of a real-coefficient quadratic; no complex arithmetic API.
class QuadraticRoots {
  const QuadraticRoots(
    this.kind,
    this.firstReal,
    this.secondReal,
    this.imaginaryMagnitude,
  );
  final QuadraticRootKind kind;
  final double firstReal;
  final double secondReal;
  final double imaginaryMagnitude;
}

abstract final class QuadraticEquation {
  static CalculationOutcome<QuadraticRoots> solve({
    required double a,
    required double b,
    required double c,
  }) {
    final issues = physicalInputIssues(
      {'a': a, 'b': b, 'c': c},
      nonZero: {'a'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final scale = math.max(a.abs(), math.max(b.abs(), c.abs()));
    final aa = a / scale, bb = b / scale, cc = c / scale;
    if (aa == 0 || (bb == 0 && b != 0) || (cc == 0 && c != 0)) return _range();
    final square = bb * bb;
    final product = 4 * aa * cc;
    if ((square == 0 && bb != 0) || (product == 0 && cc != 0)) return _range();
    final discriminant = square - product;
    if (discriminant < 0) {
      final real = -bb / (2 * aa);
      final imaginary = math.sqrt(-discriminant) / (2 * aa.abs());
      if (!real.isFinite ||
          !imaginary.isFinite ||
          imaginary == 0 ||
          (real == 0 && b != 0)) {
        return _range();
      }
      return CalculationSuccess(
        QuadraticRoots(QuadraticRootKind.complex, real, real, imaginary),
      );
    }
    if (discriminant == 0) {
      final root = -bb / (2 * aa);
      if (!root.isFinite || (root == 0 && b != 0)) return _range();
      return CalculationSuccess(
        QuadraticRoots(QuadraticRootKind.repeated, root, root, 0),
      );
    }
    // q avoids catastrophic subtraction when |b| is much larger than sqrt(D).
    final q = -0.5 * (bb + (bb < 0 ? -1 : 1) * math.sqrt(discriminant));
    final first = q / aa;
    final second = cc / q;
    if (!first.isFinite ||
        !second.isFinite ||
        first == 0 ||
        (second == 0 && c != 0)) {
      return _range();
    }
    return CalculationSuccess(
      QuadraticRoots(
        QuadraticRootKind.twoReal,
        math.min(first, second),
        math.max(first, second),
        0,
      ),
    );
  }

  static CalculationFailure<QuadraticRoots> _range() => calculationFailure(
    CalculationError.numericRange,
    'These coefficients exceed the supported numeric range. Rescale the equation or use less extreme coefficients.',
  );
}
