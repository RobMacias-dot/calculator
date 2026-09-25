import 'foundation_cases.dart';
import 'ohm_cases.dart';
import 'newton_cases.dart';
import 'reynolds_cases.dart';
import 'ideal_gas_cases.dart';
import 'ipv4_cases.dart';
import 'phase4_cases.dart';

Map<String, void Function()> allCalculationCases() => {
  ...foundationCases(),
  ...ohmCases(),
  ...newtonCases(),
  ...reynoldsCases(),
  ...idealGasCases(),
  ...ipv4Cases(),
  ...phase4Cases(),
};
