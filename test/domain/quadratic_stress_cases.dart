import 'dart:math' as math;

import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/mathematics.dart';

import 'checks.dart';
import 'numerical_checks.dart';

final _coefficientScales = [
  -8.0,
  -.1,
  math.pow(2.0, -500).toDouble(),
  .1,
  1.0,
  3.0,
  1e-100,
  1e100,
  math.pow(2.0, 500).toDouble(),
];

Map<String, void Function()> quadraticStressCases() => {
  'quadratic exact dyadic discriminant signs survive product cancellation': () {
    for (final k in [
      -math.pow(2.0, 500).toDouble(),
      math.pow(2.0, -500).toDouble(),
      1.0,
      math.pow(2.0, 500).toDouble(),
    ]) {
      final d = math.pow(2.0, -27).toDouble();
      final positive = valueOf(
        QuadraticEquation.solve(a: (1 + d) * k, b: 2 * k, c: (1 - d) * k),
        'D=4*2^-54 scale=$k',
      );
      checkEqual(positive.kind, QuadraticRootKind.twoReal);
      near(
        positive.firstReal,
        -1,
        relative: 8 * binary64Epsilon,
        context: 'positive discriminant first k=$k',
      );
      near(
        positive.secondReal,
        (-1 + d) / (1 + d),
        relative: 8 * binary64Epsilon,
        context: 'positive discriminant second k=$k',
      );
      final e = math.pow(2.0, -26).toDouble();
      // (1+e)(1-e+e²)=1+e³ exactly for the represented dyadic inputs.
      final negative = valueOf(
        QuadraticEquation.solve(
          a: (1 + e) * k,
          b: 2 * k,
          c: (1 - e + e * e) * k,
        ),
        'D=-4*2^-78 scale=$k',
      );
      checkEqual(negative.kind, QuadraticRootKind.complex);
      near(
        negative.firstReal,
        -1 / (1 + e),
        relative: 8 * binary64Epsilon,
        context: 'negative discriminant real k=$k',
      );
      near(
        negative.imaginaryMagnitude,
        math.sqrt(e * e * e) / (1 + e),
        relative: 8 * binary64Epsilon,
        context: 'negative discriminant imaginary k=$k',
      );
    }
  },
  'quadratic repeated roots and coefficient-encoding limits': () {
    for (final r in [-1024.0, -5.0, -.125, 0.0, .125, 5.0, 1024.0]) {
      for (final k in _coefficientScales) {
        final roots = valueOf(
          QuadraticEquation.solve(a: k, b: -2 * r * k, c: r * r * k),
          'repeated construction r=$r k=$k',
        );
        final exactScale =
            k == 1 || k == math.pow(2.0, -500) || k == math.pow(2.0, 500);
        if (exactScale || r.abs() != 5) {
          // Powers of two preserve every coefficient in these families.
          checkEqual(roots.kind, QuadraticRootKind.repeated);
          checkEqual(roots.firstReal, r);
        } else {
          // Decimal k can perturb b²=4ac in the *encoded* coefficients.
          // Multiple roots have square-root sensitivity to such perturbation;
          // demanding the same branch after inexact scaling is invalid.
          final bound = 8 * math.sqrt(binary64Epsilon) * r.abs();
          near(
            roots.firstReal,
            r,
            relative: 0,
            absolute: bound,
            context: 'encoded repeated first r=$r k=$k',
          );
          near(
            roots.secondReal,
            r,
            relative: 0,
            absolute: bound,
            context: 'encoded repeated second r=$r k=$k',
          );
          near(
            roots.imaginaryMagnitude,
            0,
            relative: 0,
            absolute: bound,
            context: 'encoded repeated imaginary r=$r k=$k',
          );
        }
      }
    }
  },
  'quadratic distinct root families and global coefficient scaling': () {
    for (final pair in [
      (-3.0, 2.0),
      (1.0, 2.0),
      (-7.0, -.5),
      (1e-8, 1e8),
      (1.0, 1 + 1 / 4096),
      (-2.0, 0.0),
    ]) {
      final left = pair.$1, right = pair.$2;
      final b = -(left + right), c = left * right;
      for (final k in _coefficientScales) {
        final context = 'roots=($left,$right) scale=$k';
        final roots = valueOf(
          QuadraticEquation.solve(a: k, b: b * k, c: c * k),
          context,
        );
        checkEqual(roots.kind, QuadraticRootKind.twoReal);
        for (final item in [
          (roots.firstReal, left),
          (roots.secondReal, right),
        ]) {
          final r = item.$2;
          // First-order coefficient/operation error divided by |p'(r)|.
          // The closest pair here remains far above sqrt(epsilon) separation.
          final conditionBudget =
              32 *
              binary64Epsilon *
              (r * r + (b * r).abs() + c.abs()) /
              (right - left).abs();
          near(
            item.$1,
            r,
            relative: 8 * binary64Epsilon,
            absolute: conditionBudget,
            context: context,
          );
          final residual = item.$1 * item.$1 + b * item.$1 + c;
          final weight = item.$1 * item.$1 + (b * item.$1).abs() + c.abs();
          near(
            residual,
            0,
            relative: 0,
            absolute: 32 * binary64Epsilon * weight,
            context: '$context residual',
          );
        }
      }
    }
  },
  'quadratic complex conjugate families survive global scaling': () {
    for (final real in [-5.0, 0.0, 3.0]) {
      for (final imaginary in [.25, 2.0, 10.0]) {
        for (final k in _coefficientScales) {
          final roots = valueOf(
            QuadraticEquation.solve(
              a: k,
              b: -2 * real * k,
              c: (real * real + imaginary * imaginary) * k,
            ),
            'complex real=$real imag=$imaginary k=$k',
          );
          checkEqual(roots.kind, QuadraticRootKind.complex);
          checkEqual(roots.firstReal, roots.secondReal);
          near(
            roots.firstReal,
            real,
            relative: 16 * binary64Epsilon,
            context: 'complex real=$real k=$k',
          );
          // c-u² cancellation has condition up to (25+.0625)/.0625 here.
          near(
            roots.imaginaryMagnitude,
            imaginary,
            relative: 0,
            absolute:
                16 *
                binary64Epsilon *
                (real * real + imaginary * imaginary) /
                imaginary,
            context: 'complex imag=$imaginary k=$k',
          );
        }
      }
    }
    checkFailure(
      QuadraticEquation.solve(a: 1e-308, b: 1e308, c: 1),
      CalculationError.numericRange,
    );
  },
};
