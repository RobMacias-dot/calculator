import 'package:engineering_toolkit/features/calculators/domain/calculator_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/newton_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/reynolds_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/ideal_gas_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/ipv4_definition.dart';
import 'package:engineering_toolkit/features/calculators/presentation/calculator_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final slices = [
    (
      create: createIpv4Definition,
      values: {'address': '192.168.1.10', 'prefix': '24'},
      expected: '192.168.1.0/24',
    ),
    (
      create: createIdealGasDefinition,
      values: {'amount': '1', 'temperature': '300', 'volume': '0.025'},
      expected: '99773.551418',
    ),
    (
      create: createReynoldsDefinition,
      values: {
        'density': '1000',
        'speed': '2',
        'length': '0.05',
        'viscosity': '0.001',
      },
      expected: '100000',
    ),
    (
      create: createNewtonDefinition,
      values: {'mass': '1', 'acceleration': '9.80665'},
      expected: '9.80665',
    ),
  ];
  for (final slice in slices) {
    group(slice.create().name, () {
      late CalculatorViewModel vm;
      setUp(() => vm = CalculatorViewModel(slice.create()));
      tearDown(() => vm.dispose());
      test('initial state and successful calculation', () {
        expect(vm.status, CalculationStatus.idle);
        expect(vm.result, isNull);
        slice.values.forEach(vm.setValue);
        vm.calculate();
        expect(vm.status, CalculationStatus.success);
        expect(vm.result!.formattedValue, slice.expected);
      });
      test('invalid input produces field errors and reset clears them', () {
        vm.setValue(slice.values.keys.first, 'invalid');
        vm.calculate();
        expect(vm.status, CalculationStatus.invalid);
        expect(vm.errorFor(slice.values.keys.first), isNotNull);
        vm.reset();
        expect(vm.issues, isEmpty);
        expect(vm.status, CalculationStatus.idle);
      });
      test('reset clears a successful result and every field', () {
        slice.values.forEach(vm.setValue);
        vm.calculate();
        vm.reset();
        expect(vm.result, isNull);
        for (final id in slice.values.keys) {
          expect(vm.valueFor(id), '');
        }
      });
    });
  }
  test('Newton unit change recalculates grams and reset restores kg', () {
    final vm = CalculatorViewModel(createNewtonDefinition());
    addTearDown(vm.dispose);
    vm.setValue('mass', '1000');
    vm.setValue('acceleration', '9.80665');
    vm.setUnit('mass', EngineeringUnit.gram);
    vm.calculate();
    expect(vm.result!.value, closeTo(9.80665, 1e-10));
    vm.reset();
    expect(vm.unitFor('mass'), EngineeringUnit.kilogram);
  });
  test('Reynolds unit selection normalizes length and viscosity', () {
    final vm = CalculatorViewModel(createReynoldsDefinition());
    addTearDown(vm.dispose);
    final values = {
      'density': '1000',
      'speed': '2',
      'length': '50',
      'viscosity': '1',
    };
    values.forEach(vm.setValue);
    vm.setUnit('length', EngineeringUnit.millimetre);
    vm.setUnit('viscosity', EngineeringUnit.millipascalSecond);
    vm.calculate();
    expect(vm.result!.value, closeTo(100000, 1e-6));
    vm.setValue('viscosity', '0');
    vm.calculate();
    expect(vm.errorFor('viscosity'), isNotNull);
  });
  test('Gas unit conversion, mode change and physical validation', () {
    final vm = CalculatorViewModel(createIdealGasDefinition());
    addTearDown(vm.dispose);
    vm.setValue('amount', '1');
    vm.setValue('temperature', '26.85');
    vm.setValue('volume', '25');
    vm.setUnit('temperature', EngineeringUnit.celsius);
    vm.setUnit('volume', EngineeringUnit.litre);
    vm.calculate();
    expect(vm.result!.value, closeTo(99773.55141783887, 1e-6));
    vm.setValue('temperature', '-273.15');
    vm.calculate();
    expect(vm.errorFor('temperature'), contains('0 K'));
    vm.selectMode(vm.definition.modes.last);
    expect(vm.mode.id, 'temperature');
    expect(vm.result, isNull);
    expect(vm.issues, isEmpty);
    vm.setValue('pressure', '100000');
    vm.setValue('volume', '0.02494338785445972');
    vm.setValue('amount', '1');
    vm.calculate();
    expect(vm.result!.value, closeTo(300, 1e-9));
  });
  test('IPv4 aggregates parser errors and has no unit state', () {
    final vm = CalculatorViewModel(createIpv4Definition());
    addTearDown(vm.dispose);
    vm.setValue('address', '256.1.1.1');
    vm.setValue('prefix', '33');
    vm.calculate();
    expect(vm.errorFor('address'), isNotNull);
    expect(vm.errorFor('prefix'), isNotNull);
    expect(vm.unitFor('address'), isNull);
    vm.setUnit('address', EngineeringUnit.volt);
    expect(vm.unitFor('address'), isNull);
    vm.setValue('address', '0.0.0.0');
    vm.setValue('prefix', '0');
    vm.calculate();
    expect(
      vm.result!.details
          .firstWhere((detail) => detail.label == 'Total addresses')
          .value,
      '4294967296',
    );
  });
}
