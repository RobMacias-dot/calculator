import 'package:engineering_toolkit/core/formatting/number_formatting.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/domain/number_parser.dart';

import 'checks.dart';

Map<String, void Function()> foundationCases() => {
  'format trims zeroes and preserves meaningful precision': () {
    checkEqual(NumberFormatting.format(22), '22');
    checkEqual(NumberFormatting.format(9.80665), '9.80665');
    checkEqual(NumberFormatting.format(1.23456789), '1.234568');
    checkEqual(NumberFormatting.format(-0.0), '0');
  },
  'format uses scientific notation for extremes': () {
    checkEqual(NumberFormatting.format(1e-10), '1e-10');
    checkEqual(NumberFormatting.format(1e12), '1e12');
    checkEqual(NumberFormatting.format(-1e-10), '-1e-10');
    checkEqual(NumberFormatting.format(1e-6), '0.000001');
  },
  'format rejects nonfinite representation': () {
    for (final value in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      checkEqual(NumberFormatting.format(value), 'Not representable');
    }
  },
  for (final sample in [
    (' 12.5 ', 12.5),
    ('-0,5', -0.5),
    ('1e3', 1000.0),
    ('+.5', 0.5),
    ('0e-9999', 0.0),
  ])
    'parse decimal ${sample.$1}': () => checkClose(
      successValue(NumberParser.parse(sample.$1, fieldId: 'x')),
      sample.$2,
    ),
  for (final text in [
    '',
    'hello',
    '1,2.3',
    '1 000',
    'NaN',
    'Infinity',
    '1e9999',
    '1e-9999',
  ])
    'reject numeric input "$text"': () {
      final result = NumberParser.parse(text, fieldId: 'x');
      checkEqual(result is CalculationFailure<double>, true);
      checkEqual(
        (result as CalculationFailure<double>).issues.single.fieldId,
        'x',
      );
    },
  for (final sample in [
    (EngineeringUnit.millivolt, 12000.0, 12.0),
    (EngineeringUnit.volt, 12.0, 12.0),
    (EngineeringUnit.kilovolt, 0.012, 12.0),
    (EngineeringUnit.milliampere, 2000.0, 2.0),
    (EngineeringUnit.ampere, 2.0, 2.0),
    (EngineeringUnit.kiloampere, 0.002, 2.0),
    (EngineeringUnit.milliohm, 10000.0, 10.0),
    (EngineeringUnit.ohm, 10.0, 10.0),
    (EngineeringUnit.kiloohm, 0.01, 10.0),
    (EngineeringUnit.megaohm, 0.00001, 10.0),
  ])
    'convert ${sample.$1.symbol} to base': () =>
        checkClose(successValue(sample.$1.toBase(sample.$2)), sample.$3),
  'unit conversion rejects nonfinite, overflow and underflow': () {
    checkFailure(
      EngineeringUnit.volt.toBase(double.nan),
      CalculationError.nonFinite,
    );
    checkFailure(
      EngineeringUnit.kilovolt.toBase(1e308),
      CalculationError.numericRange,
    );
    checkFailure(
      EngineeringUnit.millivolt.toBase(5e-324),
      CalculationError.numericRange,
    );
  },
};
