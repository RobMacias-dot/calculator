import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/newton_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/newtons_second_law.dart';

import 'checks.dart';

Map<String, void Function()> newtonCases() => {
  'Newton 1 kg * 9.80665 = 9.80665 N': () => checkClose(
    successValue(NewtonsSecondLaw.force(mass: 1, acceleration: 9.80665)),
    9.80665,
  ),
  'Newton converts 1000 g without changing acceleration': () {
    checkClose(successValue(EngineeringUnit.gram.toBase(1000)), 1);
    checkClose(
      successValue(
        createNewtonDefinition().modes.single.calculate(
          {'mass': '1000', 'acceleration': '9.80665'},
          {'mass': EngineeringUnit.gram},
        ),
      ).value!,
      9.80665,
    );
  },
  'Newton zero mass and signed acceleration': () {
    checkEqual(
      successValue(NewtonsSecondLaw.force(mass: 0, acceleration: -9.80665)),
      0.0,
    );
    checkEqual(
      successValue(NewtonsSecondLaw.force(mass: 3, acceleration: 0)),
      0.0,
    );
    checkClose(
      successValue(NewtonsSecondLaw.force(mass: 2, acceleration: -9.80665)),
      -19.6133,
    );
  },
  'Newton rejects negative mass': () => checkFailure(
    NewtonsSecondLaw.force(mass: -1, acceleration: 2),
    CalculationError.outOfDomain,
  ),
  for (final invalid in [double.nan, double.infinity, double.negativeInfinity])
    'Newton rejects nonfinite $invalid': () {
      checkFailure(
        NewtonsSecondLaw.force(mass: invalid, acceleration: 2),
        CalculationError.nonFinite,
      );
      checkFailure(
        NewtonsSecondLaw.force(mass: 1, acceleration: invalid),
        CalculationError.nonFinite,
      );
    },
  'Newton reports unsupported numeric range': () {
    checkFailure(
      NewtonsSecondLaw.force(mass: 1e308, acceleration: 10),
      CalculationError.numericRange,
    );
    checkFailure(
      NewtonsSecondLaw.force(mass: 1e-300, acceleration: 1e-300),
      CalculationError.numericRange,
    );
  },
};
