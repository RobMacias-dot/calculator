import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/calculators/presentation/calculator_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final id in ['series-resistance', 'parallel-resistance']) {
    test('$id adds and removes inputs without losing values or units', () {
      final vm = CalculatorViewModel(createInitialCatalog().byId(id)!);
      addTearDown(vm.dispose);
      expect(vm.inputs, hasLength(2));
      vm.removeResistor();
      expect(vm.inputs, hasLength(2));
      vm.setValue('r1', '1');
      vm.setUnit('r1', EngineeringUnit.kiloohm);
      vm.setValue('r2', '1000');
      vm.calculate();
      expect(vm.result!.value, id == 'series-resistance' ? 2000 : 500);
      vm.addResistor();
      expect(vm.result, isNull);
      expect(vm.valueFor('r1'), '1');
      expect(vm.unitFor('r1'), EngineeringUnit.kiloohm);
      expect(vm.valueFor('r3'), '');
      vm.calculate();
      expect(vm.errorFor('r3'), isNotNull);
      vm.setValue('r3', '-1');
      vm.calculate();
      expect(vm.errorFor('r3'), isNotNull);
      vm.removeResistor();
      expect(vm.issues, isEmpty);
      expect(vm.unitFor('r3'), isNull);
      vm.addResistor();
      expect(vm.valueFor('r3'), '');
      vm.setValue('r3', '1000');
      vm.calculate();
      expect(
        vm.result!.value,
        closeTo(id == 'series-resistance' ? 3000 : 1000 / 3, 1e-9),
      );
      vm.reset();
      expect(vm.inputs, hasLength(2));
      expect(vm.valueFor('r1'), '');
      expect(vm.unitFor('r1'), EngineeringUnit.ohm);
      expect(vm.status, CalculationStatus.idle);
    });
  }
  test(
    'resistor lists have no small count cap and expose immutable fields',
    () {
      final vm = CalculatorViewModel(
        createInitialCatalog().byId('series-resistance')!,
      );
      addTearDown(vm.dispose);
      for (var i = 0; i < 38; i++) {
        vm.addResistor();
      }
      expect(vm.inputs, hasLength(40));
      expect(() => vm.inputs.clear(), throwsUnsupportedError);
      for (final input in vm.inputs) {
        vm.setValue(input.id, '10');
      }
      vm.calculate();
      expect(vm.result!.value, 400);
    },
  );
  test(
    'ordinary forms ignore resistor actions and mode changes reset cleanly',
    () {
      final vm = CalculatorViewModel(createInitialCatalog().byId('dc-power')!);
      addTearDown(vm.dispose);
      vm.addResistor();
      vm.removeResistor();
      expect(vm.hasResistorList, isFalse);
      expect(vm.inputs.map((field) => field.id), ['voltage', 'current']);
      vm.setValue('voltage', '12');
      vm.setValue('current', '2');
      vm.calculate();
      vm.selectMode(vm.definition.modes.last);
      expect(vm.result, isNull);
      expect(vm.inputs.map((field) => field.id), ['power', 'voltage']);
      expect(vm.valueFor('voltage'), '');
    },
  );
}
