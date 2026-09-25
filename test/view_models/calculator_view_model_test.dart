import 'package:engineering_toolkit/features/calculators/domain/calculator_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/ohm_definition.dart';
import 'package:engineering_toolkit/features/calculators/presentation/calculator_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CalculatorViewModel vm;
  setUp(() => vm = CalculatorViewModel(createOhmDefinition()));
  tearDown(() => vm.dispose());

  test('initial state is empty, defaults to current with SI units', () {
    expect(vm.status, CalculationStatus.idle);
    expect(vm.valueFor('voltage'), '');
    expect(vm.unitFor('voltage'), EngineeringUnit.volt);
    expect(vm.result, isNull);
  });
  test('calculates only on request and invalidates stale results', () {
    vm.setValue('voltage', '12');
    vm.setValue('resistance', '6');
    expect(vm.result, isNull);
    vm.calculate();
    expect(vm.status, CalculationStatus.success);
    expect(vm.result!.value, closeTo(2, 1e-12));
    vm.setValue('voltage', '24');
    expect(vm.result, isNull);
    expect(vm.status, CalculationStatus.idle);
  });
  test('reports all parse errors inline and domain errors by field', () {
    vm.setValue('voltage', 'oops');
    vm.calculate();
    expect(vm.status, CalculationStatus.invalid);
    expect(vm.errorFor('voltage'), isNotNull);
    expect(vm.errorFor('resistance'), isNotNull);
    vm.setValue('voltage', '12');
    vm.setValue('resistance', '0');
    vm.calculate();
    expect(vm.errorFor('resistance'), contains('greater than zero'));
    expect(vm.result, isNull);
  });
  test('unit change preserves entered value but clears old result', () {
    vm.setValue('voltage', '12000');
    vm.setValue('resistance', '6');
    vm.calculate();
    vm.setUnit('voltage', EngineeringUnit.millivolt);
    expect(vm.result, isNull);
    expect(vm.valueFor('voltage'), '12000');
    vm.calculate();
    expect(vm.result!.value, closeTo(2, 1e-12));
  });
  test('mode change and reset clear values, errors and units', () {
    vm.setValue('voltage', 'bad');
    vm.calculate();
    vm.selectMode(vm.definition.modes[1]);
    expect(vm.mode.id, 'voltage');
    expect(vm.issues, isEmpty);
    vm.setValue('current', '2');
    vm.setValue('resistance', '10');
    vm.calculate();
    expect(vm.result!.value, 20);
    vm.reset();
    expect(vm.mode.id, 'current');
    expect(vm.result, isNull);
    expect(vm.valueFor('voltage'), '');
    expect(vm.unitFor('voltage'), EngineeringUnit.volt);
    expect(vm.status, CalculationStatus.idle);
  });
  test('unsupported unit and field cannot alter state', () {
    vm.setUnit('voltage', EngineeringUnit.kilogram);
    vm.setValue('unknown', '12');
    expect(vm.unitFor('voltage'), EngineeringUnit.volt);
    expect(vm.valueFor('unknown'), '');
  });
  test('range failures are visible as a general error', () {
    vm.setValue('voltage', '1e308');
    vm.setValue('resistance', '1e-308');
    vm.calculate();
    expect(vm.status, CalculationStatus.invalid);
    expect(vm.generalIssues, hasLength(1));
  });
}
