import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculation_result.dart';
import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/electrical.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/mechanical.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/fluids.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/thermal.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/mathematics.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/ipv4_address.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/network_representations.dart';

import 'checks.dart';

// Hand-worked reference values; expected results never call production solvers.
// Maps describe input fixtures only, not a runtime equation language.
typedef NumericSample = ({
  String id,
  String mode,
  Map<String, String> values,
  double expected,
  Map<String, String> invalid,
  Map<String, String> zero,
});

final numericSamples = <NumericSample>[
  (
    id: 'dc-power',
    mode: 'power',
    values: {'voltage': '12', 'current': '2'},
    expected: 24,
    invalid: {},
    zero: {'current': '0'},
  ),
  (
    id: 'dc-power',
    mode: 'voltage',
    values: {'power': '24', 'current': '2'},
    expected: 12,
    invalid: {'current': '0'},
    zero: {'power': '0'},
  ),
  (
    id: 'dc-power',
    mode: 'current',
    values: {'power': '24', 'voltage': '12'},
    expected: 2,
    invalid: {'voltage': '0'},
    zero: {'power': '0'},
  ),
  (
    id: 'electrical-energy',
    mode: 'energy',
    values: {'power': '2000', 'time': '10800'},
    expected: 21600000,
    invalid: {'time': '-1'},
    zero: {'time': '0'},
  ),
  (
    id: 'series-resistance',
    mode: 'series',
    values: {'r1': '10', 'r2': '20'},
    expected: 30,
    invalid: {'r1': '-1'},
    zero: {'r1': '0', 'r2': '0'},
  ),
  (
    id: 'parallel-resistance',
    mode: 'parallel',
    values: {'r1': '10', 'r2': '20'},
    expected: 6.666666666666667,
    invalid: {'r2': '0'},
    zero: {},
  ),
  (
    id: 'voltage-divider',
    mode: 'output',
    values: {'voltage': '12', 'r1': '1000', 'r2': '2000'},
    expected: 8,
    invalid: {'r1': '0', 'r2': '0'},
    zero: {'r2': '0'},
  ),
  (
    id: 'torque',
    mode: 'torque',
    values: {'force': '20', 'radius': '0.5'},
    expected: 10,
    invalid: {'radius': '-1'},
    zero: {'force': '0'},
  ),
  (
    id: 'mechanical-work',
    mode: 'work',
    values: {'force': '10', 'distance': '3'},
    expected: 30,
    invalid: {'distance': '-1'},
    zero: {'distance': '0'},
  ),
  (
    id: 'mechanical-power',
    mode: 'power',
    values: {'work': '600', 'time': '3'},
    expected: 200,
    invalid: {'time': '0'},
    zero: {'work': '0'},
  ),
  (
    id: 'kinetic-energy',
    mode: 'energy',
    values: {'mass': '2', 'speed': '3'},
    expected: 9,
    invalid: {'mass': '-1'},
    zero: {'speed': '0'},
  ),
  (
    id: 'momentum',
    mode: 'momentum',
    values: {'mass': '2', 'velocity': '-3'},
    expected: -6,
    invalid: {'mass': '-1'},
    zero: {'mass': '0'},
  ),
  (
    id: 'volumetric-flow',
    mode: 'flow',
    values: {'area': '0.02', 'velocity': '3'},
    expected: 0.06,
    invalid: {'area': '0'},
    zero: {'velocity': '0'},
  ),
  // π × 0.1²/4 × 2 = π/200; independently tabulated decimal reference.
  (
    id: 'pipe-flow',
    mode: 'flow',
    values: {'diameter': '0.1', 'velocity': '2'},
    expected: 0.015707963267948967,
    invalid: {'diameter': '0'},
    zero: {'velocity': '0'},
  ),
  (
    id: 'hydrostatic-pressure',
    mode: 'pressure',
    values: {'density': '1000', 'depth': '2'},
    expected: 19613.3,
    invalid: {'density': '0'},
    zero: {'depth': '0'},
  ),
  // 100000 + 500(4−16) + 9806.65(3−1) = 113613.3 Pa.
  (
    id: 'bernoulli-basic',
    mode: 'pressure2',
    values: {
      'pressure1': '100000',
      'density': '1000',
      'speed1': '2',
      'speed2': '4',
      'height1': '3',
      'height2': '1',
    },
    expected: 113613.3,
    invalid: {'density': '-1'},
    zero: {
      'pressure1': '0',
      'speed1': '0',
      'speed2': '0',
      'height1': '0',
      'height2': '0',
    },
  ),
  (
    id: 'sensible-heat',
    mode: 'heat',
    values: {'mass': '2', 'specificHeat': '4186', 'temperatureChange': '10'},
    expected: 83720,
    invalid: {'specificHeat': '0'},
    zero: {'temperatureChange': '0'},
  ),
  (
    id: 'thermal-efficiency',
    mode: 'efficiency',
    values: {'work': '400', 'heat': '1000'},
    expected: 0.4,
    invalid: {'work': '1001'},
    zero: {'work': '0'},
  ),
  (
    id: 'temperature-converter',
    mode: 'temperature',
    values: {'temperature': '0'},
    expected: 273.15,
    invalid: {'temperature': '-273.16'},
    zero: {'temperature': '-273.15'},
  ),
  (
    id: 'linear-expansion',
    mode: 'expansion',
    values: {
      'coefficient': '0.000012',
      'length': '2',
      'temperatureChange': '50',
    },
    expected: 0.0012,
    invalid: {'length': '0'},
    zero: {'temperatureChange': '0'},
  ),
  (
    id: 'percentage',
    mode: 'of',
    values: {'percent': '15', 'value': '200'},
    expected: 30,
    invalid: {},
    zero: {'percent': '0'},
  ),
  (
    id: 'percentage',
    mode: 'change',
    values: {'initial': '80', 'finalValue': '100'},
    expected: 0.25,
    invalid: {'initial': '0'},
    zero: {'finalValue': '80'},
  ),
  (
    id: 'percentage',
    mode: 'ratio',
    values: {'part': '30', 'whole': '200'},
    expected: 0.15,
    invalid: {'whole': '0'},
    zero: {'part': '0'},
  ),
  (
    id: 'pythagorean',
    mode: 'c',
    values: {'a': '3', 'b': '4'},
    expected: 5,
    invalid: {'a': '0'},
    zero: {},
  ),
  (
    id: 'pythagorean',
    mode: 'a',
    values: {'c': '5', 'b': '4'},
    expected: 3,
    invalid: {'c': '4'},
    zero: {},
  ),
  (
    id: 'pythagorean',
    mode: 'b',
    values: {'c': '5', 'a': '3'},
    expected: 4,
    invalid: {'c': '2'},
    zero: {},
  ),
  (
    id: 'vector-magnitude',
    mode: '2d',
    values: {'x': '3', 'y': '-4'},
    expected: 5,
    invalid: {},
    zero: {'x': '0', 'y': '0'},
  ),
  (
    id: 'vector-magnitude',
    mode: '3d',
    values: {'x': '2', 'y': '3', 'z': '6'},
    expected: 7,
    invalid: {},
    zero: {'x': '0', 'y': '0', 'z': '0'},
  ),
];

CalculationOutcome<CalculationResult> calculateNew(
  String id,
  String mode,
  Map<String, String> values, [
  Map<String, EngineeringUnit> units = const {},
]) => createInitialCatalog()
    .byId(id)!
    .modes
    .singleWhere((item) => item.id == mode)
    .calculate(values, units);

Map<String, void Function()> phase4Cases() => {
  for (final sample in numericSamples)
    '${sample.id}/${sample.mode}: independent canonical value and complete report':
        () {
          final result = successValue(
            calculateNew(sample.id, sample.mode, sample.values),
          );
          checkClose(result.value!, sample.expected);
          if (sample.id == 'vector-magnitude' && sample.mode == '2d') {
            checkEqual(result.substitution, '|v| = √((3)² + (-4)²)');
          }
          checkEqual(
            result.formula.isNotEmpty &&
                result.substitution.isNotEmpty &&
                result.explanation.isNotEmpty,
            true,
          );
        },
  for (final sample in numericSamples.where(
    (sample) => sample.invalid.isNotEmpty,
  ))
    '${sample.id}/${sample.mode}: invalid physical domain is inline': () {
      final result = calculateNew(sample.id, sample.mode, {
        ...sample.values,
        ...sample.invalid,
      });
      checkEqual(result is CalculationFailure<CalculationResult>, true);
      final issues = (result as CalculationFailure<CalculationResult>).issues;
      checkEqual(
        issues.any((issue) => sample.invalid.containsKey(issue.fieldId)),
        true,
      );
    },
  for (final sample in numericSamples.where((sample) => sample.zero.isNotEmpty))
    '${sample.id}/${sample.mode}: valid zero remains representable': () =>
        checkClose(
          successValue(
            calculateNew(sample.id, sample.mode, {
              ...sample.values,
              ...sample.zero,
            }),
          ).value!,
          0,
        ),
  for (final sample in numericSamples)
    '${sample.id}/${sample.mode}: all numeric fields reject nonfinite and missing input':
        () {
          for (final field in sample.values.keys) {
            for (final bad in ['NaN', 'Infinity', '1e999', '']) {
              final result = calculateNew(sample.id, sample.mode, {
                ...sample.values,
                field: bad,
              });
              checkEqual(result is CalculationFailure<CalculationResult>, true);
              checkEqual(
                (result as CalculationFailure<CalculationResult>).issues.any(
                  (issue) => issue.fieldId == field,
                ),
                true,
              );
            }
          }
        },
  ..._unitCases(),
  ..._engineCases(),
  ..._networkCases(),
  ..._quadraticCases(),
};

Map<String, void Function()> _unitCases() => {
  for (final sample
      in <
        ({
          String id,
          String mode,
          Map<String, String> values,
          Map<String, EngineeringUnit> units,
          double expected,
        })
      >[
        (
          id: 'dc-power',
          mode: 'power',
          values: {'voltage': '0.012', 'current': '2000'},
          units: {
            'voltage': EngineeringUnit.kilovolt,
            'current': EngineeringUnit.milliampere,
          },
          expected: 24,
        ),
        (
          id: 'electrical-energy',
          mode: 'energy',
          values: {'power': '2', 'time': '3'},
          units: {
            'power': EngineeringUnit.kilowatt,
            'time': EngineeringUnit.hour,
          },
          expected: 21600000,
        ),
        (
          id: 'series-resistance',
          mode: 'series',
          values: {'r1': '1', 'r2': '0.002', 'r3': '1000'},
          units: {'r1': EngineeringUnit.kiloohm, 'r2': EngineeringUnit.megaohm},
          expected: 4000,
        ),
        (
          id: 'parallel-resistance',
          mode: 'parallel',
          values: {'r1': '1', 'r2': '0.001', 'r3': '1000'},
          units: {'r1': EngineeringUnit.kiloohm, 'r2': EngineeringUnit.megaohm},
          expected: 333.3333333333333,
        ),
        (
          id: 'voltage-divider',
          mode: 'output',
          values: {'voltage': '0.012', 'r1': '1', 'r2': '0.002'},
          units: {
            'voltage': EngineeringUnit.kilovolt,
            'r1': EngineeringUnit.kiloohm,
            'r2': EngineeringUnit.megaohm,
          },
          expected: 8,
        ),
        (
          id: 'torque',
          mode: 'torque',
          values: {'force': '20', 'radius': '50'},
          units: {'radius': EngineeringUnit.centimetre},
          expected: 10,
        ),
        (
          id: 'mechanical-work',
          mode: 'work',
          values: {'force': '10', 'distance': '300'},
          units: {'distance': EngineeringUnit.centimetre},
          expected: 30,
        ),
        (
          id: 'mechanical-power',
          mode: 'power',
          values: {'work': '12', 'time': '1'},
          units: {
            'work': EngineeringUnit.kilojoule,
            'time': EngineeringUnit.minute,
          },
          expected: 200,
        ),
        (
          id: 'kinetic-energy',
          mode: 'energy',
          values: {'mass': '2000', 'speed': '3'},
          units: {'mass': EngineeringUnit.gram},
          expected: 9,
        ),
        (
          id: 'momentum',
          mode: 'momentum',
          values: {'mass': '2000', 'velocity': '-3'},
          units: {'mass': EngineeringUnit.gram},
          expected: -6,
        ),
        (
          id: 'volumetric-flow',
          mode: 'flow',
          values: {'area': '200', 'velocity': '3'},
          units: {'area': EngineeringUnit.squareCentimetre},
          expected: 0.06,
        ),
        (
          id: 'pipe-flow',
          mode: 'flow',
          values: {'diameter': '100', 'velocity': '2'},
          units: {'diameter': EngineeringUnit.millimetre},
          expected: 0.015707963267948967,
        ),
        (
          id: 'hydrostatic-pressure',
          mode: 'pressure',
          values: {'density': '1000', 'depth': '200'},
          units: {'depth': EngineeringUnit.centimetre},
          expected: 19613.3,
        ),
        (
          id: 'bernoulli-basic',
          mode: 'pressure2',
          values: {
            'pressure1': '100',
            'density': '1000',
            'speed1': '2',
            'speed2': '4',
            'height1': '3',
            'height2': '1',
          },
          units: {'pressure1': EngineeringUnit.kilopascal},
          expected: 113613.3,
        ),
        (
          id: 'sensible-heat',
          mode: 'heat',
          values: {
            'mass': '2000',
            'specificHeat': '4.186',
            'temperatureChange': '10',
          },
          units: {
            'mass': EngineeringUnit.gram,
            'specificHeat': EngineeringUnit.kilojouleSpecificHeat,
            'temperatureChange': EngineeringUnit.celsiusDifference,
          },
          expected: 83720,
        ),
        (
          id: 'thermal-efficiency',
          mode: 'efficiency',
          values: {'work': '0.4', 'heat': '1'},
          units: {
            'work': EngineeringUnit.kilojoule,
            'heat': EngineeringUnit.kilojoule,
          },
          expected: 0.4,
        ),
        (
          id: 'temperature-converter',
          mode: 'temperature',
          values: {'temperature': '32'},
          units: {'temperature': EngineeringUnit.fahrenheit},
          expected: 273.15,
        ),
        (
          id: 'linear-expansion',
          mode: 'expansion',
          values: {
            'coefficient': '0.000012',
            'length': '200',
            'temperatureChange': '50',
          },
          units: {
            'coefficient': EngineeringUnit.perCelsius,
            'length': EngineeringUnit.centimetre,
            'temperatureChange': EngineeringUnit.celsiusDifference,
          },
          expected: 0.0012,
        ),
        (
          id: 'pythagorean',
          mode: 'c',
          values: {'a': '300', 'b': '400'},
          units: {
            'a': EngineeringUnit.centimetre,
            'b': EngineeringUnit.centimetre,
          },
          expected: 5,
        ),
      ])
    '${sample.id}: alternative input units normalize before calculation': () =>
        checkClose(
          successValue(
            calculateNew(sample.id, sample.mode, sample.values, sample.units),
          ).value!,
          sample.expected,
        ),
  'energy, flow and efficiency display independently verified alternate units':
      () {
        final energy = successValue(
          calculateNew('electrical-energy', 'energy', {
            'power': '2000',
            'time': '10800',
          }),
        );
        checkEqual(
          energy.details.map((d) => d.value).join('|'),
          '6000 Wh|6 kWh',
        );
        final flow = successValue(
          calculateNew('volumetric-flow', 'flow', {
            'area': '0.02',
            'velocity': '3',
          }),
        );
        checkEqual(
          flow.details.map((d) => d.value).join('|'),
          '60 L/s|3600 L/min',
        );
        final efficiency = successValue(
          calculateNew('thermal-efficiency', 'efficiency', {
            'work': '400',
            'heat': '1000',
          }),
        );
        checkEqual(efficiency.details.single.value, '40 %');
        checkEqual(
          successValue(
            calculateNew('percentage', 'change', {
              'initial': '80',
              'finalValue': '100',
            }),
          ).formattedValue,
          '25',
        );
      },
  'absolute zero and temperature differences use separate dimensions': () {
    for (final sample in [
      (EngineeringUnit.kelvin, '0'),
      (EngineeringUnit.celsius, '-273.15'),
      (EngineeringUnit.fahrenheit, '-459.67'),
    ]) {
      checkClose(
        successValue(
          calculateNew(
            'temperature-converter',
            'temperature',
            {'temperature': sample.$2},
            {'temperature': sample.$1},
          ),
        ).value!,
        0,
      );
    }
    checkClose(successValue(EngineeringUnit.celsiusDifference.toBase(1)), 1);
    checkClose(successValue(EngineeringUnit.celsius.toBase(1)), 274.15);
    checkFailure(
      calculateNew(
        'sensible-heat',
        'heat',
        {'mass': '1', 'specificHeat': '1', 'temperatureChange': '1'},
        {'temperatureChange': EngineeringUnit.celsius},
      ),
      CalculationError.incompatibleUnit,
    );
    final boiling = successValue(
      calculateNew('temperature-converter', 'temperature', {
        'temperature': '100',
      }),
    );
    checkEqual(boiling.details.map((d) => d.value).join('|'), '100 °C|212 °F');
  },
};

Map<String, void Function()> _engineCases() => {
  'every new numeric engine guards direct nonfinite callers': () {
    for (final bad in [double.nan, double.infinity, double.negativeInfinity]) {
      final outcomes = [
        DcPower.power(voltage: bad, current: 2),
        DcPower.voltage(power: 1, current: bad),
        DcPower.current(power: bad, voltage: 1),
        ElectricalEnergy.calculate(power: 1, time: bad),
        ResistanceNetwork.series([1, bad]),
        ResistanceNetwork.parallel([bad, 1]),
        VoltageDivider.calculate(voltage: 1, r1: bad, r2: 1),
        Torque.calculate(force: bad, radius: 1),
        MechanicalWork.calculate(force: 1, distance: bad),
        MechanicalPower.calculate(work: bad, time: 1),
        KineticEnergy.calculate(mass: 1, speed: bad),
        Momentum.calculate(mass: bad, velocity: 1),
        VolumetricFlow.area(area: bad, velocity: 1),
        VolumetricFlow.pipe(diameter: 1, velocity: bad),
        HydrostaticPressure.calculate(density: 1, depth: 1, gravity: bad),
        Bernoulli.pressure2(
          pressure1: 1,
          density: 1,
          speed1: 1,
          speed2: 1,
          height1: bad,
          height2: 1,
        ),
        SensibleHeat.calculate(
          mass: 1,
          specificHeat: bad,
          temperatureChange: 1,
        ),
        ThermalEfficiency.calculate(work: bad, heat: 1),
        AbsoluteTemperature.kelvin(bad),
        LinearExpansion.calculate(
          coefficient: bad,
          length: 1,
          temperatureChange: 1,
        ),
        Percentages.ofValue(percent: bad, value: 1),
        Percentages.change(initial: 1, finalValue: bad),
        Percentages.ratio(part: 1, whole: bad),
        Pythagoras.hypotenuse(a: 1, b: bad),
        Pythagoras.leg(c: 2, knownLeg: bad, fieldId: 'a'),
        VectorMagnitude.calculate(x: 1, y: 1, z: bad),
      ];
      for (final outcome in outcomes) {
        checkFailure(outcome, CalculationError.nonFinite);
      }
      checkFailure(
        QuadraticEquation.solve(a: 1, b: bad, c: 1),
        CalculationError.nonFinite,
      );
    }
  },
  'resistance lists enforce minimum, allow arbitrary length and stable conductances':
      () {
        checkFailure(
          ResistanceNetwork.series([1]),
          CalculationError.invalidInput,
        );
        checkFailure(
          ResistanceNetwork.parallel([]),
          CalculationError.invalidInput,
        );
        checkClose(
          successValue(ResistanceNetwork.series(List.filled(100, 10))),
          1000,
        );
        checkClose(
          successValue(ResistanceNetwork.parallel(List.filled(100, 100))),
          1,
        );
        checkEqual(
          successValue(ResistanceNetwork.parallel([1e-308, 1e-308])),
          5e-309,
        );
        checkFailure(
          ResistanceNetwork.series([1e308, 1e308]),
          CalculationError.numericRange,
        );
        checkFailure(
          ResistanceNetwork.parallel([5e-324, 5e-324]),
          CalculationError.numericRange,
        );
        checkClose(
          successValue(
            VoltageDivider.calculate(voltage: 12, r1: 1e308, r2: 1e308),
          ),
          6,
        );
      },
  'signed work, cooling, flow and coefficient conventions': () {
    checkClose(
      successValue(MechanicalWork.calculate(force: -10, distance: 3)),
      -30,
    );
    checkClose(
      successValue(
        SensibleHeat.calculate(
          mass: 2,
          specificHeat: 1000,
          temperatureChange: -5,
        ),
      ),
      -10000,
    );
    checkClose(successValue(VolumetricFlow.area(area: 2, velocity: -3)), -6);
    checkClose(
      successValue(
        LinearExpansion.calculate(
          coefficient: -0.00001,
          length: 2,
          temperatureChange: 10,
        ),
      ),
      -0.0002,
    );
    checkFailure(
      LinearExpansion.calculate(
        coefficient: 1,
        length: 1,
        temperatureChange: -1,
      ),
      CalculationError.outOfDomain,
    );
    checkFailure(
      ThermalEfficiency.calculate(work: 0, heat: 0),
      CalculationError.divisionByZero,
    );
    checkClose(successValue(ThermalEfficiency.calculate(work: 1, heat: 1)), 1);
    checkClose(
      successValue(
        HydrostaticPressure.calculate(density: 1000, depth: 2, gravity: 10),
      ),
      20000,
    );
  },
  'norm and right triangle avoid squared overflow': () {
    checkClose(
      successValue(VectorMagnitude.calculate(x: 3e200, y: 4e200)),
      5e200,
    );
    checkClose(successValue(Pythagoras.hypotenuse(a: 3e200, b: 4e200)), 5e200);
    checkClose(
      successValue(Pythagoras.leg(c: 5e200, knownLeg: 4e200, fieldId: 'b')),
      3e200,
    );
    checkEqual(
      successValue(VectorMagnitude.calculate(x: 3e-200, y: 4e-200)),
      5e-200,
    );
    checkFailure(
      VectorMagnitude.calculate(x: 1.7e308, y: 1.7e308),
      CalculationError.numericRange,
    );
  },
  'new physical engines reject unrepresentable results instead of displaying infinity':
      () {
        for (final result in [
          DcPower.power(voltage: 1e308, current: 10),
          ElectricalEnergy.calculate(power: 1e308, time: 10),
          Torque.calculate(force: 1e308, radius: 10),
          MechanicalWork.calculate(force: 1e308, distance: 10),
          MechanicalPower.calculate(work: 1e308, time: 1e-308),
          KineticEnergy.calculate(mass: 1e308, speed: 10),
          Momentum.calculate(mass: 1e308, velocity: 10),
          VolumetricFlow.area(area: 1e308, velocity: 10),
          VolumetricFlow.pipe(diameter: 1e308, velocity: 1),
          HydrostaticPressure.calculate(density: 1e308, depth: 10),
          SensibleHeat.calculate(
            mass: 1e308,
            specificHeat: 10,
            temperatureChange: 1,
          ),
        ]) {
          checkFailure(result, CalculationError.numericRange);
        }
      },
};

Map<String, void Function()> _networkCases() => {
  'binary decimal IPv4 uses exact integer octets in both directions': () {
    const expected = '11000000.10101000.00000001.00001010';
    final address = successValue(Ipv4Address.parse('192.168.1.10'));
    checkEqual(Ipv4Representations.binary(address), expected);
    checkEqual(
      successValue(Ipv4Representations.decimal(expected)),
      '192.168.1.10',
    );
    for (final ip in ['0.0.0.0', '255.255.255.255']) {
      checkEqual(
        successValue(
          Ipv4Representations.decimal(
            Ipv4Representations.binary(successValue(Ipv4Address.parse(ip))),
          ),
        ),
        ip,
      );
    }
    for (final invalid in [
      '',
      '1.1.1.1',
      '22222222.00000000.00000000.00000000',
      '00000000.00000000.00000000',
    ]) {
      checkFailure(
        Ipv4Representations.decimal(invalid),
        CalculationError.invalidInput,
      );
    }
    checkEqual(
      successValue(
        calculateNew('ipv4-representation', 'binary', {
          'address': '192.168.1.10',
        }),
      ).formattedValue,
      expected,
    );
    checkEqual(
      successValue(
        calculateNew('ipv4-representation', 'decimal', {'binary': expected}),
      ).formattedValue,
      '192.168.1.10',
    );
  },
  'all 33 CIDR masks round trip with exact endpoints': () {
    for (var prefix = 0; prefix <= 32; prefix++) {
      final mask = successValue(Ipv4Representations.mask(prefix));
      checkEqual(
        successValue(
          Ipv4Representations.prefix(successValue(Ipv4Address.parse(mask))),
        ),
        prefix,
      );
    }
    checkEqual(successValue(Ipv4Representations.mask(0)), '0.0.0.0');
    checkEqual(successValue(Ipv4Representations.mask(32)), '255.255.255.255');
    checkEqual(
      successValue(
        calculateNew('subnet-mask', 'prefix', {'address': '255.255.255.0'}),
      ).formattedValue,
      '/24',
    );
    checkEqual(
      successValue(calculateNew('subnet-mask', 'mask', {'prefix': '24'}))
          .formattedValue,
      '255.255.255.0',
    );
    checkFailure(Ipv4Representations.mask(33), CalculationError.outOfDomain);
    checkFailure(Ipv4Representations.mask(-1), CalculationError.outOfDomain);
  },
  'mask and wildcard reject noncontiguous masks and malformed IPv4': () {
    for (final mask in ['255.0.255.0', '254.255.255.0', '0.0.0.1']) {
      final address = successValue(Ipv4Address.parse(mask));
      checkFailure(
        Ipv4Representations.prefix(address),
        CalculationError.outOfDomain,
      );
      checkFailure(
        Ipv4Representations.wildcard(address),
        CalculationError.outOfDomain,
      );
    }
    for (final id in ['ipv4-representation', 'subnet-mask', 'wildcard-mask']) {
      final mode = createInitialCatalog().byId(id)!.modes.first;
      checkEqual(
        mode.calculate({'address': '999.1.1.1'}, {})
            is CalculationFailure<CalculationResult>,
        true,
      );
    }
    checkEqual(
      successValue(
        calculateNew('wildcard-mask', 'wildcard', {'address': '255.255.255.0'}),
      ).formattedValue,
      '0.0.0.255',
    );
    checkEqual(
      successValue(
        calculateNew('wildcard-mask', 'wildcard', {'address': '0.0.0.0'}),
      ).formattedValue,
      '255.255.255.255',
    );
    checkEqual(
      successValue(
        calculateNew('wildcard-mask', 'wildcard', {
          'address': '255.255.255.255',
        }),
      ).formattedValue,
      '0.0.0.0',
    );
  },
};

Map<String, void Function()> _quadraticCases() => {
  'quadratic two real, repeated, complex and zero roots': () {
    final real = successValue(QuadraticEquation.solve(a: 1, b: -3, c: 2));
    checkEqual(real.kind, QuadraticRootKind.twoReal);
    checkClose(real.firstReal, 1);
    checkClose(real.secondReal, 2);
    final repeated = successValue(QuadraticEquation.solve(a: 1, b: 2, c: 1));
    checkEqual(repeated.kind, QuadraticRootKind.repeated);
    checkClose(repeated.firstReal, -1);
    final complex = successValue(QuadraticEquation.solve(a: 1, b: 2, c: 5));
    checkEqual(complex.kind, QuadraticRootKind.complex);
    checkClose(complex.firstReal, -1);
    checkClose(complex.imaginaryMagnitude, 2);
    final zero = successValue(QuadraticEquation.solve(a: 1, b: 0, c: 0));
    checkClose(zero.firstReal, 0);
    final oneZero = successValue(QuadraticEquation.solve(a: 1, b: -2, c: 0));
    checkClose(oneZero.firstReal, 0);
    checkClose(oneZero.secondReal, 2);
    final report = successValue(
      calculateNew('quadratic-equation', 'roots', {
        'a': '1',
        'b': '0',
        'c': '1',
      }),
    );
    checkEqual(report.formattedValue, 'x1 = 0 + 1i\nx2 = 0 − 1i');
    checkEqual(report.resultLabel, 'Roots');
    checkFailure(
      QuadraticEquation.solve(a: 0, b: 1, c: 1),
      CalculationError.divisionByZero,
    );
  },
  'quadratic normalization and q formula retain small roots': () {
    final scaled = successValue(
      QuadraticEquation.solve(a: 1e300, b: -3e300, c: 2e300),
    );
    checkClose(scaled.firstReal, 1);
    checkClose(scaled.secondReal, 2);
    final cancellation = successValue(
      QuadraticEquation.solve(a: 1, b: 1e16, c: 1),
    );
    checkClose(cancellation.firstReal, -1e16);
    checkEqual(cancellation.secondReal, -1e-16);
    checkFailure(
      QuadraticEquation.solve(a: 1e-308, b: 1e308, c: 1),
      CalculationError.numericRange,
    );
    checkFailure(
      QuadraticEquation.solve(a: 1, b: double.nan, c: 1),
      CalculationError.nonFinite,
    );
  },
};
