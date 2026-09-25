import 'package:engineering_toolkit/features/calculators/domain/calculator_registry.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/ohm_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/newton_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/reynolds_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/ideal_gas_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/ipv4_definition.dart';

/// Frozen fixture preserves the 207 Phase 1–3 checks, including an empty category
/// and exact five-entry search expectations. Production has ONE expanded registry.
CalculatorRegistry createPhase3Catalog() => CalculatorRegistry([
  createOhmDefinition(),
  createNewtonDefinition(),
  createReynoldsDefinition(),
  createIdealGasDefinition(),
  createIpv4Definition(),
]);
