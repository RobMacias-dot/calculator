import 'foundation_cases.dart';
import 'ohm_cases.dart';
import 'newton_cases.dart';
import 'reynolds_cases.dart';
import 'ideal_gas_cases.dart';
import 'ipv4_cases.dart';
import 'phase4_cases.dart';
import 'content_consistency_cases.dart';
import 'metamorphic_cases.dart';
import 'quadratic_stress_cases.dart';
import 'equivalence_cases.dart';
import 'boundary_cases.dart';

Map<String, void Function()> allCalculationCases() => {
  ...foundationCases(),
  ...ohmCases(),
  ...newtonCases(),
  ...reynoldsCases(),
  ...idealGasCases(),
  ...ipv4Cases(),
  ...phase4Cases(),
  ...contentConsistencyCases(),
  ...metamorphicCases(),
  ...quadraticStressCases(),
  ...equivalenceCases(),
  ...boundaryCases(),
};
