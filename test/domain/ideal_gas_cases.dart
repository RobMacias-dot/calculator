import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/ideal_gas_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/ideal_gas_law.dart';

import 'checks.dart';

Map<String, void Function()> idealGasCases() => {
  'Gas pressure of 1 mol at 300 K in 0.025 m3': () => checkClose(
    successValue(
      IdealGasLaw.pressure(amount: 1, temperature: 300, volume: 0.025),
    ),
    99773.55141783887,
  ),
  'Gas volume at 100000 Pa, 300 K and 1 mol': () => checkClose(
    successValue(
      IdealGasLaw.volume(amount: 1, temperature: 300, pressure: 100000),
    ),
    0.02494338785445972,
  ),
  'Gas amount at 100000 Pa and 300 K': () => checkClose(
    successValue(
      IdealGasLaw.amount(
        pressure: 100000,
        volume: 0.02494338785445972,
        temperature: 300,
      ),
    ),
    1,
  ),
  'Gas temperature at 100000 Pa and 1 mol': () => checkClose(
    successValue(
      IdealGasLaw.temperature(
        pressure: 100000,
        volume: 0.02494338785445972,
        amount: 1,
      ),
    ),
    300,
  ),
  for (final sample in [
    (EngineeringUnit.pascal, 1.0, 1.0),
    (EngineeringUnit.kilopascal, 1.0, 1000.0),
    (EngineeringUnit.bar, 1.0, 100000.0),
    (EngineeringUnit.atmosphere, 1.0, 101325.0),
    (EngineeringUnit.litre, 25.0, 0.025),
    (EngineeringUnit.celsius, 0.0, 273.15),
    (EngineeringUnit.celsius, -273.15, 0.0),
    (EngineeringUnit.celsius, 26.85, 300.0),
  ])
    'Gas conversion ${sample.$1.name} ${sample.$2}': () =>
        checkClose(successValue(sample.$1.toBase(sample.$2)), sample.$3),
  'Gas Celsius and litres pipeline matches SI calculation': () {
    final result = successValue(
      createIdealGasDefinition().modes.first.calculate(
        {'amount': '1', 'temperature': '26.85', 'volume': '25'},
        {
          'temperature': EngineeringUnit.celsius,
          'volume': EngineeringUnit.litre,
        },
      ),
    );
    checkClose(result.value!, 99773.55141783887);
    checkEqual(result.substitution.contains('300 K'), true);
    checkEqual(result.substitution.contains('0.025 m³'), true);
  },
  'Gas rejects absolute zero and subzero Kelvin after conversion': () {
    for (final temperature in ['-273.15', '-300']) {
      checkFailure(
        createIdealGasDefinition().modes.first.calculate(
          {'amount': '1', 'temperature': temperature, 'volume': '25'},
          {
            'temperature': EngineeringUnit.celsius,
            'volume': EngineeringUnit.litre,
          },
        ),
        CalculationError.outOfDomain,
      );
    }
  },
  'Gas every supplied quantity must be positive in every mode': () {
    final definition = createIdealGasDefinition();
    for (final mode in definition.modes) {
      for (final input in mode.inputs) {
        for (final invalid in ['0', '-1']) {
          final values = {for (final field in mode.inputs) field.id: '1'};
          values[input.id] = invalid;
          final result = mode.calculate(values, {});
          checkEqual(result is CalculationFailure, true);
        }
      }
    }
  },
  'Gas division by zero uses typed errors': () {
    checkFailure(
      IdealGasLaw.pressure(amount: 1, temperature: 300, volume: 0),
      CalculationError.divisionByZero,
    );
    checkFailure(
      IdealGasLaw.volume(amount: 1, temperature: 300, pressure: 0),
      CalculationError.divisionByZero,
    );
    checkFailure(
      IdealGasLaw.amount(pressure: 1, volume: 1, temperature: 0),
      CalculationError.divisionByZero,
    );
    checkFailure(
      IdealGasLaw.temperature(pressure: 1, volume: 1, amount: 0),
      CalculationError.divisionByZero,
    );
  },
  for (final value in [double.nan, double.infinity, double.negativeInfinity])
    'Gas nonfinite $value rejected by all pure solvers': () {
      for (final result in [
        IdealGasLaw.pressure(amount: value, temperature: 1, volume: 1),
        IdealGasLaw.pressure(amount: 1, temperature: value, volume: 1),
        IdealGasLaw.pressure(amount: 1, temperature: 1, volume: value),
        IdealGasLaw.volume(amount: value, temperature: 1, pressure: 1),
        IdealGasLaw.volume(amount: 1, temperature: value, pressure: 1),
        IdealGasLaw.volume(amount: 1, temperature: 1, pressure: value),
        IdealGasLaw.amount(pressure: value, volume: 1, temperature: 1),
        IdealGasLaw.amount(pressure: 1, volume: value, temperature: 1),
        IdealGasLaw.amount(pressure: 1, volume: 1, temperature: value),
        IdealGasLaw.temperature(pressure: value, volume: 1, amount: 1),
        IdealGasLaw.temperature(pressure: 1, volume: value, amount: 1),
        IdealGasLaw.temperature(pressure: 1, volume: 1, amount: value),
      ]) {
        checkFailure(result, CalculationError.nonFinite);
      }
    },
  'Gas rejects unsupported result magnitude': () {
    checkFailure(
      IdealGasLaw.pressure(amount: 1e308, temperature: 1e308, volume: 1),
      CalculationError.numericRange,
    );
    checkFailure(
      IdealGasLaw.volume(amount: 1e308, temperature: 1e308, pressure: 1),
      CalculationError.numericRange,
    );
    checkFailure(
      IdealGasLaw.amount(pressure: 1e308, volume: 1e308, temperature: 1),
      CalculationError.numericRange,
    );
    checkFailure(
      IdealGasLaw.temperature(pressure: 1e-300, volume: 1e-300, amount: 1),
      CalculationError.numericRange,
    );
  },
};
