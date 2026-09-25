import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/ohm_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/ohms_law.dart';

import 'checks.dart';

Map<String, void Function()> ohmCases() => {
  'Ohm 12 V / 6 ohm = 2 A': () =>
      checkClose(successValue(OhmsLaw.current(voltage: 12, resistance: 6)), 2),
  'Ohm 220 V / 10 ohm = 22 A': () => checkClose(
    successValue(OhmsLaw.current(voltage: 220, resistance: 10)),
    22,
  ),
  'Ohm 2 A * 10 ohm = 20 V': () =>
      checkClose(successValue(OhmsLaw.voltage(current: 2, resistance: 10)), 20),
  'Ohm 24 V / 2 A = 12 ohm': () =>
      checkClose(successValue(OhmsLaw.resistance(voltage: 24, current: 2)), 12),
  'Ohm keeps full precision and signed polarity': () {
    checkClose(
      successValue(OhmsLaw.current(voltage: -1, resistance: 3)),
      -1 / 3,
    );
    checkClose(successValue(OhmsLaw.resistance(voltage: -24, current: -2)), 12);
  },
  'Ohm valid zero boundaries': () {
    checkEqual(successValue(OhmsLaw.current(voltage: 0, resistance: 10)), 0.0);
    checkEqual(successValue(OhmsLaw.voltage(current: 0, resistance: 10)), 0.0);
    checkEqual(successValue(OhmsLaw.voltage(current: 2, resistance: 0)), 0.0);
    checkEqual(successValue(OhmsLaw.resistance(voltage: 0, current: 2)), 0.0);
  },
  'Ohm rejects zero divisors and passive-domain violations': () {
    checkFailure(
      OhmsLaw.current(voltage: 12, resistance: 0),
      CalculationError.divisionByZero,
    );
    checkFailure(
      OhmsLaw.resistance(voltage: 12, current: 0),
      CalculationError.divisionByZero,
    );
    checkFailure(
      OhmsLaw.current(voltage: 12, resistance: -1),
      CalculationError.outOfDomain,
    );
    checkFailure(
      OhmsLaw.voltage(current: 2, resistance: -1),
      CalculationError.outOfDomain,
    );
    checkFailure(
      OhmsLaw.resistance(voltage: -12, current: 2),
      CalculationError.outOfDomain,
    );
  },
  for (final invalid in [double.nan, double.infinity, double.negativeInfinity])
    'Ohm rejects nonfinite $invalid in every argument': () {
      for (final result in [
        OhmsLaw.current(voltage: invalid, resistance: 6),
        OhmsLaw.current(voltage: 12, resistance: invalid),
        OhmsLaw.voltage(current: invalid, resistance: 6),
        OhmsLaw.voltage(current: 2, resistance: invalid),
        OhmsLaw.resistance(voltage: invalid, current: 2),
        OhmsLaw.resistance(voltage: 12, current: invalid),
      ]) {
        checkFailure(result, CalculationError.nonFinite);
      }
    },
  'Ohm reports overflow and underflow instead of silent infinity/zero': () {
    checkFailure(
      OhmsLaw.current(voltage: 1e308, resistance: 1e-308),
      CalculationError.numericRange,
    );
    checkFailure(
      OhmsLaw.current(voltage: 1e-308, resistance: 1e308),
      CalculationError.numericRange,
    );
    checkFailure(
      OhmsLaw.voltage(current: 1e308, resistance: 10),
      CalculationError.numericRange,
    );
    checkFailure(
      OhmsLaw.resistance(voltage: 1e308, current: 1e-308),
      CalculationError.numericRange,
    );
    checkClose(
      successValue(OhmsLaw.current(voltage: 1e-12, resistance: 1e-12)),
      1,
    );
  },
  'Ohm pipeline converts, solves and explains base units': () {
    final report = successValue(
      createOhmDefinition().modes.first.calculate(
        {'voltage': '12000', 'resistance': '0.006'},
        {
          'voltage': EngineeringUnit.millivolt,
          'resistance': EngineeringUnit.kiloohm,
        },
      ),
    );
    checkClose(report.value!, 2);
    checkEqual(report.formattedValue, '2');
    checkEqual(report.substitution, 'I = 12 V / 6 Ω');
    checkEqual(report.explanation.contains('2 A'), true);
  },
  'Ohm rejects incompatible units in pipeline': () => checkFailure(
    createOhmDefinition().modes.first.calculate(
      {'voltage': '12', 'resistance': '6'},
      {'voltage': EngineeringUnit.kilogram},
    ),
    CalculationError.incompatibleUnit,
  ),
};
