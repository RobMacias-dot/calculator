import 'package:engineering_toolkit/core/formatting/number_formatting.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/mathematics.dart';
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';

import 'checks.dart';
import 'phase4_cases.dart';

Map<String, void Function()> contentConsistencyCases() => {
  'normalized operand text round-trips across signs and magnitude ranges': () {
    for (final value in [
      0.0,
      -0.0,
      1.0000001,
      -1.0000001,
      1.4e-6,
      1.4e-20,
      1.23456789e30,
      273.15000000000003,
      double.maxFinite,
      double.minPositive,
    ]) {
      checkEqual(double.parse(NumberFormatting.operand(value)), value);
    }
    checkEqual(NumberFormatting.operand(12), '12');
    checkEqual(NumberFormatting.operand(-0.0), '0');
  },
  'near-equal triangle sides remain distinct in normalized substitution': () {
    for (final mode in ['a', 'b']) {
      final report = successValue(
        calculateNew('pythagorean', mode, {
          'c': '1.0000001',
          mode == 'a' ? 'b' : 'a': '1',
        }),
      );
      checkEqual(report.substitution.contains('(1.0000001 m)²'), true);
      checkClose(report.value!, 0.0004472136066802946);
    }
  },
  'percentage change shows the nonzero difference actually calculated': () {
    final report = successValue(
      calculateNew('percentage', 'change', {
        'initial': '1',
        'finalValue': '1.0000001',
      }),
    );
    checkEqual(report.substitution, 'Change = (1.0000001 − 1) / 1 × 100%');
    checkEqual(report.formattedValue, '0.00001');
  },
  'quadratic substitution retains coefficients that change root kind': () {
    final report = successValue(
      calculateNew('quadratic-equation', 'roots', {
        'a': '1',
        'b': '-2',
        'c': '1.0000001',
      }),
    );
    checkEqual(report.substitution, '(1)x² + (-2)x + (1.0000001) = 0');
    checkEqual(report.explanation.contains('negative'), true);
  },
  'exact repeated quadratic roots survive normalization': () {
    // Independently factored integer polynomials (x-r)^2, also sign/scaled.
    for (final r in [3.0, 5.0, 7.0, -5.0]) {
      for (final scale in [1.0, -8.0, 1048576.0]) {
        final roots = successValue(
          QuadraticEquation.solve(
            a: scale,
            b: -2 * r * scale,
            c: r * r * scale,
          ),
        );
        checkEqual(roots.kind, QuadraticRootKind.repeated);
        checkEqual(roots.firstReal, r);
      }
    }
  },
  'near repeated quadratic roots retain sign and distinct displayed roots': () {
    for (final c in [0.99999999999999, 1.00000000000001]) {
      final roots = successValue(QuadraticEquation.solve(a: 1, b: -2, c: c));
      checkEqual(
        roots.kind,
        c < 1 ? QuadraticRootKind.twoReal : QuadraticRootKind.complex,
      );
      final report = successValue(
        calculateNew('quadratic-equation', 'roots', {
          'a': '1',
          'b': '-2',
          'c': c.toString(),
        }),
      );
      if (c < 1) {
        final values = report.formattedValue
            .split('\n')
            .map((s) => double.parse(s.split(' = ').last))
            .toList();
        checkEqual(values[0] < 1 && values[1] > 1, true);
        checkEqual(values[0], roots.firstReal);
        checkEqual(values[1], roots.secondReal);
      }
    }
    // Existing ordinary result formatting is intentionally unchanged.
    checkEqual(NumberFormatting.format(1.0000001), '1');
  },
  'CIDR hint agrees with integer parser and its boundaries': () {
    final mode = createInitialCatalog().byId('subnet-mask')!.modes.last;
    checkEqual(
      mode.inputHint,
      'Enter an integer prefix from 0 to 32, without the slash.',
    );
    for (final prefix in ['0', '32']) {
      successValue(mode.calculate({'prefix': prefix}, {}));
    }
    for (final prefix in ['24.0', '24,0', '/24', '33']) {
      checkEqual(
        mode.calculate({'prefix': prefix}, {}) is CalculationFailure,
        true,
      );
    }
  },
  'efficiency explanation refers to percentage without assuming layout order':
      () {
        final report = successValue(
          calculateNew('thermal-efficiency', 'efficiency', {
            'work': '400',
            'heat': '1000',
          }),
        );
        checkEqual(report.details.single.value, '40 %');
        checkEqual(report.explanation.contains('result details'), true);
        checkEqual(report.explanation.contains('below'), false);
      },
};
