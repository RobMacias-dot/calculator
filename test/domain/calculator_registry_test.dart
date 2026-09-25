import 'package:engineering_toolkit/features/calculators/domain/calculator_category.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculator_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculator_registry.dart';

import '../support/phase3_catalog.dart';

import 'package:engineering_toolkit/features/calculators/domain/calculator_mode.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/numeric_mode.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculation_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all five registered calculators execute without router changes', () {
    final registry = createPhase3Catalog();
    expect(registry.all.every((definition) => definition.isAvailable), isTrue);
    expect(registry.search('circuit').single.id, 'ohms-law');
    expect(registry.search('moles').single.id, 'ideal-gas-law');
    expect(registry.search('broadcast').single.id, 'ipv4-subnet');
  });
  test('unit metadata rejects mixed dimensions and mode ids reject duplicate inputs', () {
    expect(
      () => CalculatorInput(
        id: 'x',
        label: 'X',
        units: [EngineeringUnit.volt, EngineeringUnit.ohm],
      ),
      throwsArgumentError,
    );
    final input = CalculatorInput(id: 'x', label: 'X');
    expect(
      () => CalculatorMode(
        id: 'example',
        label: 'Example',
        formula: '',
        inputs: [input, input],
        calculate: (_, _) =>
            calculationFailure(CalculationError.invalidInput, 'Invalid'),
      ),
      throwsArgumentError,
    );
  });
  test('numeric callbacks capture immutable metadata and warnings', () {
    final fields = [
      CalculatorInput(id: 'x', label: 'X', units: [EngineeringUnit.volt]),
    ];
    final notes = ['Original note'];
    final mode = numericMode(
      id: 'example',
      label: 'Example',
      formula: 'x',
      inputs: fields,
      unit: EngineeringUnit.volt,
      solve: (values) => CalculationSuccess(values['x']!),
      substitution: (_) => 'x = 1',
      explanation: (_, _) => 'Example',
      warnings: notes,
    );
    fields.clear();
    notes.clear();
    final outcome = mode.calculate({'x': '1'}, {});
    expect(outcome, isA<CalculationSuccess<CalculationResult>>());
    expect((outcome as CalculationSuccess<CalculationResult>).value.warnings, [
      'Original note',
    ]);
    expect(mode.inputs, hasLength(1));
  });
  test(
    'catalog has five stable entries and six fields including empty math',
    () {
      final registry = createPhase3Catalog();
      expect(registry.all, hasLength(5));
      expect(CalculatorCategory.values, hasLength(6));
      expect(
        registry.byId('ohms-law')?.category,
        CalculatorCategory.electrical,
      );
      expect(registry.inCategory(CalculatorCategory.mathematics), isEmpty);
      expect(registry.byId('not-found'), isNull);
      expect(CalculatorCategory.fromId('not-found'), isNull);
    },
  );

  test('registry rejects duplicate ids at composition time', () {
    final definition = createPhase3Catalog().all.first;
    expect(
      () => CalculatorRegistry([definition, definition]),
      throwsArgumentError,
    );
  });

  test('registry copies its source and exposes immutable collections', () {
    final source = createPhase3Catalog().all.toList();
    final registry = CalculatorRegistry(source);
    source.clear();
    expect(registry.all, hasLength(5));
    expect(() => registry.all.clear(), throwsUnsupportedError);
    expect(() => registry.all.first.inputs.clear(), throwsUnsupportedError);
    expect(
      () => registry.all.first.inputs.first.units.clear(),
      throwsUnsupportedError,
    );
  });

  test(
    'search trims whitespace and matches name, description and category',
    () {
      final registry = createPhase3Catalog();
      expect(registry.search('  REYNOLDS ').single.id, 'reynolds-number');
      expect(registry.search('resistance').single.id, 'ohms-law');
      expect(registry.search('NETWORKING').single.id, 'ipv4-subnet');
      expect(registry.search('  '), hasLength(5));
      expect(registry.search('unavailable'), isEmpty);
    },
  );

  test('input metadata rejects nonfinite and empty bounds', () {
    for (final bounds in [
      (double.nan, 1.0),
      (0.0, double.infinity),
      (2.0, 1.0),
    ]) {
      expect(
        () => CalculatorInput(
          id: 'value',
          label: 'Value',
          minimum: bounds.$1,
          maximum: bounds.$2,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => CalculatorInput(
        id: 'value',
        label: 'Value',
        minimum: 0,
        maximum: 0,
        minimumExclusive: true,
      ),
      throwsArgumentError,
    );
    expect(() => CalculatorInput(id: '', label: 'Value'), throwsArgumentError);
  });

  test('definitions reject unstable ids and duplicated input ids', () {
    CalculatorDefinition definition(String id, List<CalculatorInput> inputs) =>
        CalculatorDefinition(
          id: id,
          name: 'Example',
          description: 'Example',
          category: CalculatorCategory.mathematics,
          formula: 'x',
          explanation: 'Example',
          inputs: inputs,
        );
    expect(() => definition('Invalid ID', []), throwsArgumentError);
    final input = CalculatorInput(id: 'x', label: 'X');
    expect(() => definition('example', [input, input]), throwsArgumentError);
  });

  test('CIDR is integer metadata and resistance excludes zero', () {
    final registry = createPhase3Catalog();
    final cidr = registry.byId('ipv4-subnet')!.inputs.last;
    expect(cidr.kind, CalculatorInputKind.integer);
    expect(cidr.minimum, 0);
    expect(cidr.maximum, 32);
    final resistance = registry.byId('ohms-law')!.inputs.last;
    expect(resistance.minimum, 0);
    expect(resistance.minimumExclusive, isTrue);
  });
}
