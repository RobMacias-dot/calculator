import 'calculator_registry.dart';
import 'definitions/ohm_definition.dart';
import 'definitions/newton_definition.dart';
import 'definitions/reynolds_definition.dart';
import 'definitions/ideal_gas_definition.dart';
import 'definitions/ipv4_definition.dart';
import 'definitions/electrical_definitions.dart';
import 'definitions/mechanical_definitions.dart';
import 'definitions/fluids_definitions.dart';
import 'definitions/thermal_definitions.dart';
import 'definitions/mathematics_definitions.dart';
import 'definitions/resistance_definitions.dart';
import 'definitions/network_definitions.dart';
import 'definitions/quadratic_definition.dart';

CalculatorRegistry createInitialCatalog() => CalculatorRegistry([
  createOhmDefinition(),
  createNewtonDefinition(),
  createReynoldsDefinition(),
  createIdealGasDefinition(),
  createIpv4Definition(),
  createDcPowerDefinition(),
  createElectricalEnergyDefinition(),
  createVoltageDividerDefinition(),
  createTorqueDefinition(),
  createWorkDefinition(),
  createMechanicalPowerDefinition(),
  createKineticEnergyDefinition(),
  createMomentumDefinition(),
  createFlowDefinition(),
  createPipeFlowDefinition(),
  createHydrostaticDefinition(),
  createBernoulliDefinition(),
  createSensibleHeatDefinition(),
  createThermalEfficiencyDefinition(),
  createTemperatureDefinition(),
  createExpansionDefinition(),
  createPercentageDefinition(),
  createPythagoreanDefinition(),
  createVectorDefinition(),
  createSeriesResistanceDefinition(),
  createParallelResistanceDefinition(),
  createIpv4RepresentationDefinition(),
  createSubnetMaskDefinition(),
  createWildcardDefinition(),
  createQuadraticDefinition(),
]);
