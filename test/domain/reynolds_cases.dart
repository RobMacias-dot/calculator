import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/reynolds_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/reynolds_number.dart';

import 'checks.dart';

Map<String, void Function()> reynoldsCases() => {
  'Reynolds water example = 100000': () => checkClose(
    successValue(
      ReynoldsNumber.calculate(
        density: 1000,
        speed: 2,
        length: 0.05,
        viscosity: 0.001,
      ),
    ),
    100000,
  ),
  'Reynolds independent air example = 67679.55801104972': () => checkClose(
    successValue(
      ReynoldsNumber.calculate(
        density: 1.225,
        speed: 10,
        length: 0.1,
        viscosity: 0.0000181,
      ),
    ),
    67679.55801104972,
  ),
  'Reynolds zero speed = zero even at extreme finite scales': () => checkEqual(
    successValue(
      ReynoldsNumber.calculate(
        density: 1e308,
        speed: 0,
        length: 1e308,
        viscosity: 1e-308,
      ),
    ),
    0.0,
  ),
  'Reynolds rejects nonpositive density, length or viscosity and negative speed':
      () {
        for (final value in [0.0, -1.0]) {
          checkFailure(
            ReynoldsNumber.calculate(
              density: value,
              speed: 1,
              length: 1,
              viscosity: 1,
            ),
            CalculationError.outOfDomain,
          );
          checkFailure(
            ReynoldsNumber.calculate(
              density: 1,
              speed: 1,
              length: value,
              viscosity: 1,
            ),
            CalculationError.outOfDomain,
          );
          checkFailure(
            ReynoldsNumber.calculate(
              density: 1,
              speed: 1,
              length: 1,
              viscosity: value,
            ),
            value == 0
                ? CalculationError.divisionByZero
                : CalculationError.outOfDomain,
          );
        }
        checkFailure(
          ReynoldsNumber.calculate(
            density: 1,
            speed: -1,
            length: 1,
            viscosity: 1,
          ),
          CalculationError.outOfDomain,
        );
      },
  for (final value in [double.nan, double.infinity, double.negativeInfinity])
    'Reynolds nonfinite $value rejected in every input': () {
      for (final result in [
        ReynoldsNumber.calculate(
          density: value,
          speed: 1,
          length: 1,
          viscosity: 1,
        ),
        ReynoldsNumber.calculate(
          density: 1,
          speed: value,
          length: 1,
          viscosity: 1,
        ),
        ReynoldsNumber.calculate(
          density: 1,
          speed: 1,
          length: value,
          viscosity: 1,
        ),
        ReynoldsNumber.calculate(
          density: 1,
          speed: 1,
          length: 1,
          viscosity: value,
        ),
      ]) {
        checkFailure(result, CalculationError.nonFinite);
      }
    },
  'Reynolds conversion of cm, mm and mPa s': () {
    checkClose(successValue(EngineeringUnit.centimetre.toBase(5)), 0.05);
    checkClose(successValue(EngineeringUnit.millimetre.toBase(50)), 0.05);
    checkClose(
      successValue(EngineeringUnit.millipascalSecond.toBase(1)),
      0.001,
    );
    final result = successValue(
      createReynoldsDefinition().modes.single.calculate(
        {'density': '1000', 'speed': '2', 'length': '50', 'viscosity': '1'},
        {
          'length': EngineeringUnit.millimetre,
          'viscosity': EngineeringUnit.millipascalSecond,
        },
      ),
    );
    checkClose(result.value!, 100000);
    checkEqual(result.warnings.length, 1);
  },
  'Reynolds range errors are explicit': () {
    checkFailure(
      ReynoldsNumber.calculate(
        density: 1e308,
        speed: 1e308,
        length: 1,
        viscosity: 1,
      ),
      CalculationError.numericRange,
    );
    checkFailure(
      ReynoldsNumber.calculate(
        density: 1e-300,
        speed: 1e-300,
        length: 1,
        viscosity: 1,
      ),
      CalculationError.numericRange,
    );
  },
};
