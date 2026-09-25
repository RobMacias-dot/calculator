import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/calculators/presentation/calculator_view_model.dart';

const visualSamples = [
  (
    id: 'voltage-divider',
    values: {'voltage': '12', 'r1': '1000', 'r2': '2000'},
  ),
  (id: 'vector-magnitude', values: {'x': '3', 'y': '-4'}),
  (
    id: 'reynolds-number',
    values: {
      'density': '1000',
      'speed': '2',
      'length': '.05',
      'viscosity': '.001',
    },
  ),
  (id: 'ipv4-subnet', values: {'address': '192.168.1.10', 'prefix': '24'}),
];

CalculatorViewModel visualVm(
  String id,
  Map<String, String> values, {
  String? mode,
}) {
  final vm = CalculatorViewModel(createInitialCatalog().byId(id)!);
  if (mode != null) {
    vm.selectMode(vm.definition.modes.singleWhere((item) => item.id == mode));
  }
  for (final entry in values.entries) {
    vm.setValue(entry.key, entry.value);
  }
  vm.calculate();
  return vm;
}
