import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/ideal_gas_law.dart';
import 'package:engineering_toolkit/features/calculators/presentation/calculator_view_model.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/catalog_audit_samples.dart';

void main() {
  test(
    'visual input labels retain the operands used by the current report',
    () {
      final catalog = createInitialCatalog();
      final divider = CalculatorViewModel(catalog.byId('voltage-divider')!);
      final gas = CalculatorViewModel(catalog.byId('ideal-gas-law')!);
      addTearDown(divider.dispose);
      addTearDown(gas.dispose);
      <String, String>{
        'voltage': '1.0000001',
        'r1': '1',
        'r2': '1',
      }.forEach(divider.setValue);
      divider.calculate();
      final circuit = mapVisualModel(divider.result!)!;
      expect(circuit.summary, contains('Input 1.0000001 V'));
      expect(
        circuit.summary,
        contains('Output ${divider.result!.formattedValue}'),
      );
      <String, String>{
        'amount': '1.0000001',
        'temperature': '300',
        'volume': '0.025',
      }.forEach(gas.setValue);
      gas.calculate();
      final chamber =
          mapVisualModel(gas.result!)! as IdealGasVisualizationModel;
      expect(chamber.label(GasVariable.amount), '1.0000001 mol');
      expect(chamber.summary, contains('amount 1.0000001 mol'));
      expect(
        chamber.label(GasVariable.pressure),
        '${gas.result!.formattedValue} Pa',
      );
      expect(
        chamber.summary,
        contains('pressure ${gas.result!.formattedValue} Pa'),
      );
    },
  );
  test('all catalog modes invalidate, normalize units, recover and reset', () {
    final catalog = createInitialCatalog();
    final visited = <String>{};
    for (final definition in catalog.all) {
      final vm = CalculatorViewModel(definition);
      addTearDown(vm.dispose);
      for (final mode in definition.modes) {
        final key = '${definition.id}/${mode.id}';
        visited.add(key);
        final raw = catalogAuditInputs[key]!;
        vm.selectMode(mode);
        expect(vm.result, isNull, reason: key);
        raw.forEach(vm.setValue);
        vm.calculate();
        expect(vm.status, CalculationStatus.success, reason: key);
        final original = vm.result!;
        expect(original.formula, mode.formula, reason: key);
        if (definition.supportsVisualLearning) {
          expect(mapVisualModel(original)!.report, same(original), reason: key);
        }
        for (final input in vm.inputs) {
          vm.setValue(input.id, '');
          expect(vm.result, isNull, reason: key);
          vm.calculate();
          expect(vm.status, CalculationStatus.invalid, reason: key);
          expect(vm.errorFor(input.id), isNotNull, reason: key);
          vm.setValue(input.id, raw[input.id]!);
          vm.calculate();
          expect(
            vm.result!.formattedValue,
            original.formattedValue,
            reason: key,
          );
          for (final unit in input.units.skip(1)) {
            final base = (input.units.first.toBase(
              double.parse(raw[input.id]!),
            ) as CalculationSuccess<double>).value;
            final converted =
                (unit.fromBase(base) as CalculationSuccess<double>).value;
            vm.setUnit(input.id, unit);
            expect(vm.valueFor(input.id), raw[input.id], reason: key);
            expect(vm.result, isNull, reason: key);
            vm.setValue(input.id, converted.toString());
            vm.calculate();
            expect(
              vm.result!.value,
              closeTo(original.value!, original.value!.abs() * 1e-10 + 1e-12),
              reason: '$key ${unit.symbol}',
            );
            vm.setUnit(input.id, input.units.first);
            vm.setValue(input.id, raw[input.id]!);
            vm.calculate();
          }
        }
        if (definition.modes.length > 1) {
          final other = definition.modes.firstWhere((m) => m != mode);
          vm.selectMode(other);
          expect(vm.result, isNull, reason: key);
          expect(vm.issues, isEmpty, reason: key);
          expect(
            vm.inputs.every((i) => vm.valueFor(i.id).isEmpty),
            true,
            reason: key,
          );
          vm.selectMode(mode);
          raw.forEach(vm.setValue);
          vm.calculate();
          expect(vm.result!.substitution, original.substitution, reason: key);
        }
        vm.reset();
        expect(vm.mode, same(definition.modes.first), reason: key);
        expect(vm.result, isNull, reason: key);
        expect(vm.issues, isEmpty, reason: key);
        for (final input in vm.inputs) {
          expect(vm.valueFor(input.id), isEmpty, reason: key);
          expect(vm.unitFor(input.id), input.units.firstOrNull, reason: key);
        }
      }
    }
    expect(visited, catalogAuditInputs.keys.toSet());
  });
}
