import 'dart:math' as math;

import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculation_result.dart';
import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/fluids.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/mathematics.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/thermal.dart';
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';

import '../support/catalog_audit_samples.dart';
import 'checks.dart';
import 'numerical_checks.dart';
import 'phase4_cases.dart';

// These are model boundaries, not a second registry or inferred constraints.
const _positive = {
  'ohms-law/current': ['resistance'],
  'parallel-resistance/parallel': ['r1', 'r2'],
  'mechanical-power/power': ['time'],
  'volumetric-flow/flow': ['area'],
  'pipe-flow/flow': ['diameter'],
  'hydrostatic-pressure/pressure': ['density'],
  'bernoulli-basic/pressure2': ['density'],
  'sensible-heat/heat': ['specificHeat'],
  'thermal-efficiency/efficiency': ['heat'],
  'linear-expansion/expansion': ['length'],
  'pythagorean/c': ['a', 'b'],
  'reynolds-number/reynolds': ['density', 'length', 'viscosity'],
  'ideal-gas-law/pressure': ['amount', 'temperature', 'volume'],
  'ideal-gas-law/volume': ['amount', 'temperature', 'pressure'],
  'ideal-gas-law/amount': ['volume', 'temperature', 'pressure'],
  'ideal-gas-law/temperature': ['amount', 'volume', 'pressure'],
};
const _nonnegative = {
  'ohms-law/voltage': ['resistance'],
  'newtons-second-law/force': ['mass'],
  'electrical-energy/energy': ['power', 'time'],
  'series-resistance/series': ['r1', 'r2'],
  'voltage-divider/output': ['r1', 'r2'],
  'torque/torque': ['force', 'radius'],
  'mechanical-work/work': ['distance'],
  'kinetic-energy/energy': ['mass', 'speed'],
  'momentum/momentum': ['mass'],
  'hydrostatic-pressure/pressure': ['depth'],
  'bernoulli-basic/pressure2': ['speed1', 'speed2'],
  'sensible-heat/heat': ['mass'],
  'thermal-efficiency/efficiency': ['work'],
  'reynolds-number/reynolds': ['speed'],
};

Map<String, void Function()> boundaryCases() => {
  'strict and nonnegative model boundaries distinguish zero and its neighbors': () {
    final catalog = createInitialCatalog();
    for (final table in [_positive, _nonnegative]) {
      for (final entry in table.entries) {
        final parts = entry.key.split('/');
        final mode = catalog
            .byId(parts[0])!
            .modes
            .singleWhere((m) => m.id == parts[1]);
        final raw = {...catalogAuditInputs[entry.key]!};
        // Preserve W <= Q even when Q is the smallest positive double.
        if (parts[0] == 'thermal-efficiency') raw['work'] = '0';
        for (final field in entry.value) {
          for (final x in [
            -double.minPositive,
            0.0,
            double.minPositive,
            1e-12,
          ]) {
            final outcome = mode.calculate({...raw, field: x.toString()}, {});
            final excluded = x < 0 || (identical(table, _positive) && x == 0);
            final context = '${entry.key} $field=$x';
            if (excluded) {
              if (outcome is! CalculationFailure<CalculationResult> ||
                  !outcome.issues.any((i) => i.fieldId == field)) {
                throw StateError('$context must fail at the input boundary');
              }
            } else if (outcome is CalculationFailure<CalculationResult>) {
              if (!outcome.issues.every(
                (i) => i.code == CalculationError.numericRange,
              )) {
                throw StateError(
                  '$context is in domain: ${outcome.issues.map((i) => i.message)}',
                );
              }
            } else {
              final value = valueOf(outcome, context).value!;
              if (!value.isFinite) throw StateError('$context returned $value');
            }
          }
        }
      }
    }
  },
  'nonzero denominators accept both signs without an epsilon zero region': () {
    for (final entry in {
      'dc-power/voltage': 'current',
      'dc-power/current': 'voltage',
      'percentage/change': 'initial',
      'percentage/ratio': 'whole',
    }.entries) {
      final parts = entry.key.split('/');
      for (final x in [
        -1e-12,
        -double.minPositive,
        0.0,
        double.minPositive,
        1e-12,
      ]) {
        final outcome = calculateNew(parts[0], parts[1], {
          ...catalogAuditInputs[entry.key]!,
          entry.value: x.toString(),
        });
        if (x == 0) {
          checkFailure(outcome, CalculationError.divisionByZero);
        } else if (outcome is CalculationFailure<CalculationResult>) {
          checkFailure(outcome, CalculationError.numericRange);
        } else {
          if (!valueOf(outcome, '${entry.key} $x').value!.isFinite) {
            throw StateError(entry.key);
          }
        }
      }
    }
  },
  'efficiency absolute zero and triangle adjacency retain exact classifications':
      () {
        for (final w in [
          0.0,
          double.minPositive,
          1 - binary64Epsilon / 2,
          1.0,
        ]) {
          checkEqual(
            valueOf(
              ThermalEfficiency.calculate(work: w, heat: 1),
              'efficiency $w',
            ),
            w,
          );
        }
        for (final w in [-double.minPositive, 1 + binary64Epsilon]) {
          checkFailure(
            ThermalEfficiency.calculate(work: w, heat: 1),
            CalculationError.outOfDomain,
          );
        }
        for (final unit in [
          EngineeringUnit.celsius,
          EngineeringUnit.fahrenheit,
        ]) {
          final zero = unit == EngineeringUnit.celsius ? -273.15 : -459.67;
          final ulp = math.pow(2.0, -44).toDouble();
          for (final delta in [-ulp, 0.0, ulp]) {
            final k = valueOf(
              unit.toBase(zero + delta),
              'absolute zero $unit $delta',
            );
            final outcome = AbsoluteTemperature.kelvin(k);
            if (delta < 0) {
              checkFailure(outcome, CalculationError.outOfDomain);
            } else {
              checkEqual(valueOf(outcome, 'valid absolute zero'), k);
            }
          }
        }
        checkEqual(
          valueOf(
            AbsoluteTemperature.kelvin(double.minPositive),
            'tiny Kelvin',
          ),
          double.minPositive,
        );
        checkFailure(
          AbsoluteTemperature.kelvin(-double.minPositive),
          CalculationError.outOfDomain,
        );
        checkFailure(
          Pythagoras.leg(c: 1, knownLeg: 1, fieldId: 'a'),
          CalculationError.outOfDomain,
        );
        final leg = valueOf(
          Pythagoras.leg(c: 1 + binary64Epsilon, knownLeg: 1, fieldId: 'a'),
          'adjacent triangle',
        );
        near(
          leg,
          math.sqrt(2 * binary64Epsilon),
          relative: 4 * binary64Epsilon,
          context: 'adjacent triangle',
        );
      },
  'finite inputs outside supported intermediate ranges return typed failures':
      () {
        for (final item in [
          ('ohms-law', 'current', {'voltage': '1e308', 'resistance': '1e-308'}),
          (
            'newtons-second-law',
            'force',
            {'mass': '1e308', 'acceleration': '1e308'},
          ),
          (
            'ideal-gas-law',
            'pressure',
            {'amount': '1e308', 'temperature': '300', 'volume': '1e308'},
          ),
          ('series-resistance', 'series', {'r1': '1e308', 'r2': '1e308'}),
          ('parallel-resistance', 'parallel', {'r1': '5e-324', 'r2': '5e-324'}),
          ('kinetic-energy', 'energy', {'mass': '1e308', 'speed': '1.8'}),
          ('pipe-flow', 'flow', {'diameter': '1e308', 'velocity': '1e-308'}),
          (
            'hydrostatic-pressure',
            'pressure',
            {'density': '1e308', 'depth': '1e-308'},
          ),
          (
            'sensible-heat',
            'heat',
            {
              'mass': '1e308',
              'specificHeat': '1e308',
              'temperatureChange': '1e-308',
            },
          ),
          (
            'percentage',
            'change',
            {'initial': '1e308', 'finalValue': '-1e308'},
          ),
          (
            'linear-expansion',
            'expansion',
            {
              'coefficient': '1e308',
              'length': '1',
              'temperatureChange': '1e308',
            },
          ),
        ]) {
          checkFailure(
            calculateNew(item.$1, item.$2, item.$3),
            CalculationError.numericRange,
          );
        }
      },
  'Bernoulli rejects a nonzero underflowed head rather than succeeding with zero':
      () {
        for (final kinetic in [true, false]) {
          checkFailure(
            Bernoulli.pressure2(
              pressure1: 0,
              density: double.minPositive,
              gravity: 1,
              speed1: kinetic ? 1 : 0,
              speed2: 0,
              height1: kinetic ? 0 : .5,
              height2: 0,
            ),
            CalculationError.numericRange,
          );
        }
      },
  'quadratic cannot certify repeated roots from subnormal lost discriminant':
      () {
        checkFailure(
          QuadraticEquation.solve(
            a: 1 + binary64Epsilon,
            b: math.pow(2.0, -500).toDouble(),
            c: (1 - binary64Epsilon) * math.pow(2.0, -1002).toDouble(),
          ),
          CalculationError.numericRange,
        );
      },
  'near equal substitution text retains every encoded separation': () {
    for (final exponent in [-8, -20, -40, -52]) {
      final changed = (1 + math.pow(2.0, exponent)).toString();
      final change = valueOf(
        calculateNew('percentage', 'change', {
          'initial': '1',
          'finalValue': changed,
        }),
        'percentage $changed',
      );
      checkEqual(change.substitution.contains(changed), true);
      final triangle = valueOf(
        calculateNew('pythagorean', 'a', {'c': changed, 'b': '1'}),
        'triangle $changed',
      );
      checkEqual(triangle.substitution.contains(changed), true);
      final flow = valueOf(
        calculateNew('bernoulli-basic', 'pressure2', {
          'pressure1': '0',
          'density': '2',
          'speed1': changed,
          'speed2': '1',
          'height1': '0',
          'height2': '0',
        }),
        'Bernoulli $changed',
      );
      checkEqual(flow.substitution.contains(changed), true);
    }
  },
};
