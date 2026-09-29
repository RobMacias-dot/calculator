import 'dart:math' as math;

import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/electrical.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/fluids.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/mathematics.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/mechanical.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/newtons_second_law.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/reynolds_number.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/thermal.dart';

import 'checks.dart';
import 'numerical_checks.dart';

Map<String, void Function()> metamorphicCases() => {
  'Ohm and DC all-mode inverse relations across signed scales': () {
    // Products/divisions without cancellation: 8 epsilon covers conversion,
    // two solves and decimal round-trip, far tighter than the old 1e-10 policy.
    for (final s in engineeringScales) {
      for (final r in engineeringScales) {
        for (final sign in [-1.0, 1.0]) {
          final v = sign * 3 * s;
          final i = modeValue('ohms-law', 'current', {
            'voltage': v,
            'resistance': r,
          });
          near(
            modeValue('ohms-law', 'voltage', {'current': i, 'resistance': r}),
            v,
            relative: 8 * binary64Epsilon,
            context: 'Ohm V=$v R=$r',
          );
          near(
            modeValue('ohms-law', 'resistance', {'voltage': v, 'current': i}),
            r,
            relative: 8 * binary64Epsilon,
            context: 'Ohm R V=$v I=$i',
          );
          for (final current in [2 * r, -2 * r]) {
            final p = modeValue('dc-power', 'power', {
              'voltage': v,
              'current': current,
            });
            near(
              modeValue('dc-power', 'voltage', {
                'power': p,
                'current': current,
              }),
              v,
              relative: 8 * binary64Epsilon,
              context: 'DC V=$v I=$current',
            );
            near(
              modeValue('dc-power', 'current', {'power': p, 'voltage': v}),
              current,
              relative: 8 * binary64Epsilon,
              context: 'DC I V=$v I=$current',
            );
          }
        }
      }
    }
  },
  'ideal gas four modes describe the same positive state': () {
    // A handful of multiplies/divides in each direction; no subtraction.
    for (final n in engineeringScales) {
      for (final volume in engineeringScales) {
        for (final t in [1.0, 300.0, 1e6]) {
          final p = modeValue('ideal-gas-law', 'pressure', {
            'amount': n,
            'volume': volume,
            'temperature': t,
          });
          final context = 'gas n=$n V=$volume T=$t P=$p';
          near(
            modeValue('ideal-gas-law', 'volume', {
              'amount': n,
              'pressure': p,
              'temperature': t,
            }),
            volume,
            relative: 16 * binary64Epsilon,
            context: context,
          );
          near(
            modeValue('ideal-gas-law', 'amount', {
              'volume': volume,
              'pressure': p,
              'temperature': t,
            }),
            n,
            relative: 16 * binary64Epsilon,
            context: context,
          );
          near(
            modeValue('ideal-gas-law', 'temperature', {
              'amount': n,
              'volume': volume,
              'pressure': p,
            }),
            t,
            relative: 16 * binary64Epsilon,
            context: context,
          );
        }
      }
    }
  },
  'percentage share ratio and change are inverse-compatible': () {
    for (final scale in engineeringScales) {
      for (final sign in [-1.0, 1.0]) {
        final whole = sign * 8 * scale;
        final share = modeValue('percentage', 'of', {
          'percent': 25,
          'value': whole,
        });
        near(
          modeValue('percentage', 'ratio', {'part': share, 'whole': whole}),
          .25,
          relative: 8 * binary64Epsilon,
          context: 'share/ratio whole=$whole',
        );
        near(
          modeValue('percentage', 'change', {
            'initial': whole,
            'finalValue': whole + share,
          }),
          .25,
          relative: 16 * binary64Epsilon,
          context: 'share/change whole=$whole',
        );
      }
    }
  },
  'Pythagorean mode recovery uses a conditioning-aware bound': () {
    for (final s in engineeringScales) {
      for (final ratio in [1.0, 1 / 256, 1 / 1048576]) {
        final a = s, b = s * ratio;
        final c = modeValue('pythagorean', 'c', {'a': a, 'b': b});
        for (final item in [('a', a, 'b', b), ('b', b, 'a', a)]) {
          final recovered = modeValue('pythagorean', item.$1, {
            'c': c,
            item.$3: item.$4,
          });
          // dc/db inversion amplifies rounded c by c/b. The error budget is
          // proportional to epsilon*c²/missingSide, not a global loose epsilon.
          near(
            recovered,
            item.$2,
            relative: 8 * binary64Epsilon,
            absolute: 8 * binary64Epsilon * c * c / item.$2,
            context: 'triangle a=$a b=$b c=$c recover ${item.$1}',
          );
        }
      }
    }
    // A much thinner triangle loses its small side in the rounded hypotenuse.
    // Inversion then has equal c/knownLeg and MUST reject, not invent a leg.
    final c = modeValue('pythagorean', 'c', {
      'a': 1,
      'b': math.pow(2.0, -30).toDouble(),
    });
    checkEqual(c, 1.0);
    checkFailure(
      Pythagoras.leg(c: c, knownLeg: 1, fieldId: 'a'),
      CalculationError.outOfDomain,
    );
  },
  'divider percentage efficiency and resistor scale invariants': () {
    for (final k in engineeringScales) {
      near(
        valueOf(
          VoltageDivider.calculate(voltage: -12, r1: 2 * k, r2: 3 * k),
          'divider k=$k',
        ),
        -7.2,
        relative: 8 * binary64Epsilon,
        context: 'divider k=$k',
      );
      near(
        valueOf(
          ThermalEfficiency.calculate(work: 3 * k, heat: 8 * k),
          'efficiency k=$k',
        ),
        .375,
        relative: 4 * binary64Epsilon,
        context: 'efficiency k=$k',
      );
      for (final sign in [-1.0, 1.0]) {
        near(
          valueOf(
            Percentages.ratio(part: -3 * k * sign, whole: 4 * k * sign),
            'ratio k=$k sign=$sign',
          ),
          -.75,
          relative: 4 * binary64Epsilon,
          context: 'ratio k=$k sign=$sign',
        );
      }
      near(
        valueOf(ResistanceNetwork.series([k, 2 * k, 3 * k]), 'series k=$k'),
        6 * k,
        relative: 8 * binary64Epsilon,
        context: 'series k=$k',
      );
      near(
        valueOf(
          ResistanceNetwork.parallel([2 * k, 3 * k, 6 * k]),
          'parallel k=$k',
        ),
        k,
        relative: 8 * binary64Epsilon,
        context: 'parallel k=$k',
      );
    }
  },
  'vector sign scale permutation and 2D-to-3D zero-extension': () {
    for (final k in engineeringScales) {
      final positive = modeValue('vector-magnitude', '3d', {
        'x': 2 * k,
        'y': -3 * k,
        'z': 6 * k,
      });
      final negative = modeValue('vector-magnitude', '3d', {
        'x': -2 * k,
        'y': 3 * k,
        'z': -6 * k,
      });
      checkEqual(positive, negative);
      near(
        positive,
        7 * k,
        relative: 8 * binary64Epsilon,
        context: 'vector scale=$k',
      );
      near(
        modeValue('vector-magnitude', '3d', {
          'x': 6 * k,
          'y': 2 * k,
          'z': -3 * k,
        }),
        positive,
        relative: 8 * binary64Epsilon,
        context: 'vector permute=$k',
      );
      checkEqual(
        modeValue('vector-magnitude', '2d', {'x': 3 * k, 'y': -4 * k}),
        modeValue('vector-magnitude', '3d', {'x': 3 * k, 'y': -4 * k, 'z': 0}),
      );
    }
  },
  'Reynolds numerator and viscosity scale relationships': () {
    for (final k in engineeringScales) {
      for (final input in ['density', 'speed', 'length', 'viscosity']) {
        final v = {
          'density': 1000.0,
          'speed': 2.0,
          'length': .05,
          'viscosity': .001,
        };
        v[input] = v[input]! * k;
        final actual = valueOf(
          ReynoldsNumber.calculate(
            density: v['density']!,
            speed: v['speed']!,
            length: v['length']!,
            viscosity: v['viscosity']!,
          ),
          'Re $v',
        );
        near(
          actual,
          input == 'viscosity' ? 1e5 / k : 1e5 * k,
          relative: 16 * binary64Epsilon,
          context: 'Re $input scale=$k',
        );
      }
    }
  },
  'mechanical electrical flow and thermal homogeneity': () {
    for (final k in engineeringScales) {
      final cases = <(String, CalculationOutcome<double>, double)>[
        ('Newton', NewtonsSecondLaw.force(mass: 2 * k, acceleration: 3), 6 * k),
        ('torque magnitude', Torque.calculate(force: 2, radius: 3 * k), 6 * k),
        ('work', MechanicalWork.calculate(force: -2 * k, distance: 3), -6 * k),
        (
          'mechanical power inverse time',
          MechanicalPower.calculate(work: 6, time: 2 * k),
          3 / k,
        ),
        (
          'kinetic square speed',
          KineticEnergy.calculate(mass: 2, speed: 3 * k),
          9 * k * k,
        ),
        ('momentum', Momentum.calculate(mass: 2, velocity: -3 * k), -6 * k),
        ('area flow', VolumetricFlow.area(area: .02 * k, velocity: 3), .06 * k),
        (
          'pipe square diameter',
          VolumetricFlow.pipe(diameter: .1 * k, velocity: 2),
          .015707963267948967 * k * k,
        ),
        (
          'hydrostatic depth',
          HydrostaticPressure.calculate(density: 1000, depth: 2 * k),
          19613.3 * k,
        ),
        (
          'sensible heat',
          SensibleHeat.calculate(
            mass: 2 * k,
            specificHeat: 1000,
            temperatureChange: 3,
          ),
          6000 * k,
        ),
        (
          'expansion length at small fixed strain',
          LinearExpansion.calculate(
            coefficient: 1e-6,
            length: 2 * k,
            temperatureChange: 10,
          ),
          2e-5 * k,
        ),
        (
          'electrical energy',
          ElectricalEnergy.calculate(power: 2 * k, time: 3),
          6 * k,
        ),
      ];
      for (final c in cases) {
        near(
          valueOf(c.$2, '${c.$1} k=$k'),
          c.$3,
          relative: 16 * binary64Epsilon,
          context: '${c.$1} k=$k',
        );
      }
    }
  },
  'signed scalar quantities retain their legitimate odd symmetry': () {
    for (final k in engineeringScales) {
      final pairs = [
        (
          'Newton',
          NewtonsSecondLaw.force(mass: 2, acceleration: k),
          NewtonsSecondLaw.force(mass: 2, acceleration: -k),
        ),
        (
          'work',
          MechanicalWork.calculate(force: k, distance: 3),
          MechanicalWork.calculate(force: -k, distance: 3),
        ),
        (
          'power',
          MechanicalPower.calculate(work: k, time: 3),
          MechanicalPower.calculate(work: -k, time: 3),
        ),
        (
          'momentum',
          Momentum.calculate(mass: 2, velocity: k),
          Momentum.calculate(mass: 2, velocity: -k),
        ),
        (
          'area',
          VolumetricFlow.area(area: .02, velocity: k),
          VolumetricFlow.area(area: .02, velocity: -k),
        ),
        (
          'pipe',
          VolumetricFlow.pipe(diameter: .1, velocity: k),
          VolumetricFlow.pipe(diameter: .1, velocity: -k),
        ),
        (
          'heat',
          SensibleHeat.calculate(
            mass: 2,
            specificHeat: 1000,
            temperatureChange: k,
          ),
          SensibleHeat.calculate(
            mass: 2,
            specificHeat: 1000,
            temperatureChange: -k,
          ),
        ),
        (
          'expansion',
          LinearExpansion.calculate(
            coefficient: 1e-18,
            length: 2,
            temperatureChange: k,
          ),
          LinearExpansion.calculate(
            coefficient: 1e-18,
            length: 2,
            temperatureChange: -k,
          ),
        ),
        (
          'divider',
          VoltageDivider.calculate(voltage: k, r1: 2, r2: 3),
          VoltageDivider.calculate(voltage: -k, r1: 2, r2: 3),
        ),
      ];
      for (final pair in pairs) {
        final positive = valueOf(pair.$2, '${pair.$1} +$k');
        final negative = valueOf(pair.$3, '${pair.$1} -$k');
        checkEqual(
          positive,
          -negative,
        ); // Multiplication/division sign is exact.
      }
    }
    checkFailure(
      Torque.calculate(force: -1, radius: 1),
      CalculationError.outOfDomain,
    );
    checkFailure(
      KineticEnergy.calculate(mass: 1, speed: -1),
      CalculationError.outOfDomain,
    );
  },
  'Bernoulli reference shifts and reversed stations': () {
    for (final offset in [-1000.0, 0.0, 1000.0]) {
      final p2 = valueOf(
        Bernoulli.pressure2(
          pressure1: 100000,
          density: 1000,
          speed1: 2,
          speed2: 4,
          height1: 3 + offset,
          height2: 1 + offset,
        ),
        'Bernoulli z-offset=$offset',
      );
      near(
        p2,
        113613.3,
        relative: 16 * binary64Epsilon,
        context: 'Bernoulli elevation reference=$offset',
      );
      near(
        valueOf(
          Bernoulli.pressure2(
            pressure1: p2,
            density: 1000,
            speed1: 4,
            speed2: 2,
            height1: 1 + offset,
            height2: 3 + offset,
          ),
          'Bernoulli reverse',
        ),
        100000,
        relative: 16 * binary64Epsilon,
        context: 'Bernoulli reverse offset=$offset',
      );
      final shifted = valueOf(
        Bernoulli.pressure2(
          pressure1: 100000 + offset,
          density: 1000,
          speed1: 2,
          speed2: 4,
          height1: 3,
          height2: 1,
        ),
        'Bernoulli pressure offset',
      );
      near(
        shifted,
        p2 + offset,
        relative: 16 * binary64Epsilon,
        context: 'Bernoulli pressure reference=$offset',
      );
    }
  },
  'near-equal differences retain sign and the exact substituted operands': () {
    for (final exponent in [8, 20, 40, 52]) {
      final d = math.pow(2.0, -exponent).toDouble();
      final change = modeValue('percentage', 'change', {
        'initial': 1,
        'finalValue': 1 + d,
      });
      checkEqual(change, d); // Sterbenz subtraction of nearby dyadic doubles.
      final leg = modeValue('pythagorean', 'a', {'c': 1 + d, 'b': 1});
      near(
        leg,
        math.sqrt(2 * d + d * d),
        relative: 8 * binary64Epsilon,
        context: 'near triangle separation=2^-$exponent',
      );
      final p = valueOf(
        Bernoulli.pressure2(
          pressure1: 0,
          density: 2,
          speed1: 1 + d,
          speed2: 1,
          height1: 0,
          height2: 0,
        ),
        'near Bernoulli velocity=$d',
      );
      near(
        p,
        2 * d + d * d,
        relative: 8 * binary64Epsilon,
        context: 'near Bernoulli velocity=$d',
      );
      final reverse = valueOf(
        Bernoulli.pressure2(
          pressure1: 0,
          density: 2,
          speed1: 1,
          speed2: 1 + d,
          height1: 0,
          height2: 0,
        ),
        'near reverse',
      );
      checkEqual(p, -reverse);
    }
  },
  'Bernoulli retains a small pressure between exactly cancelling heads': () {
    for (final p in [
      math.pow(2.0, -54).toDouble(),
      -math.pow(2.0, -54).toDouble(),
      1e-20,
    ]) {
      for (final reverse in [false, true]) {
        final r = valueOf(
          Bernoulli.pressure2(
            pressure1: p,
            density: 2,
            speed1: reverse ? 0 : 1,
            speed2: reverse ? 1 : 0,
            height1: reverse ? .5 : 0,
            height2: reverse ? 0 : .5,
            gravity: 1,
          ),
          'Bernoulli exact heads P1=$p reverse=$reverse',
        );
        checkEqual(r, p);
      }
    }
  },
};
