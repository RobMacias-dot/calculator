import 'package:engineering_toolkit/features/calculators/domain/calculation_context.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculation_result.dart';
import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/visual_learning_samples.dart';

void main() {
  test(
    'exactly eight pilots advertise capability; all successful contexts map',
    () {
      final supported = createInitialCatalog().all.where(
        (definition) => definition.supportsVisualLearning,
      );
      expect(
        supported.map((definition) => definition.id),
        unorderedEquals([
          ...visualSamples.map((sample) => sample.id),
          'ideal-gas-law',
        ]),
      );
      for (final sample in visualSamples) {
        final vm = visualVm(sample.id, sample.values);
        addTearDown(vm.dispose);
        expect(vm.result, isNotNull);
        expect(mapVisualModel(vm.result!), isNotNull);
      }
    },
  );

  test('divider retains normalized units, signed values and uses the engine result', () {
    final vm = visualVm('voltage-divider', {
      'voltage': '-12',
      'r1': '1',
      'r2': '2',
    });
    addTearDown(vm.dispose);
    vm.setUnit('r1', EngineeringUnit.kiloohm);
    vm.setUnit('r2', EngineeringUnit.kiloohm);
    vm.calculate();
    final model = mapVisualModel(vm.result!)! as DividerVisualModel;
    expect(model.inputs.r1.baseValue, 1000);
    expect(model.inputs.r2.baseValue, 2000);
    expect(model.inputs.voltage.baseValue, -12);
    expect(model.outputFraction, closeTo(2 / 3, 1e-12));
    expect(identical(model.report, vm.result), isTrue);
    // Synthetic report proves mapping consumes the result, rather than solving
    // Vout independently. The real domain reports are covered by domain cases.
    final supplied = CalculationResult(
      value: -3,
      context: vm.result!.context,
      formattedValue: '-3',
      formula: '',
      substitution: '',
      explanation: '',
    );
    expect(
      (mapVisualModel(supplied)! as DividerVisualModel).outputFraction,
      .25,
    );
  });

  for (final values in [
    {'voltage': '0', 'r1': '0', 'r2': '1'},
    {'voltage': '12', 'r1': '1e250', 'r2': '1e-40'},
  ]) {
    test('divider zero/extreme display remains safe: $values', () {
      final vm = visualVm('voltage-divider', values);
      addTearDown(vm.dispose);
      final model = mapVisualModel(vm.result!)! as DividerVisualModel;
      expect(
        model.outputFraction == null || model.outputFraction!.isFinite,
        isTrue,
      );
      expect(model.report.value, vm.result!.value);
      if (values['voltage'] == '0') expect(model.outputFraction, isNull);
    });
  }

  for (final sample in [
    (mode: '2d', values: {'x': '3', 'y': '-4'}),
    (mode: '2d', values: {'x': '0', 'y': '0'}),
    (mode: '2d', values: {'x': '1e300', 'y': '1e-200'}),
    (mode: '2d', values: {'x': '1e-300', 'y': '-2e-300'}),
    (mode: '3d', values: {'x': '-2', 'y': '3', 'z': '-6'}),
  ]) {
    test('vector geometry is finite, fitted and immutable: $sample', () {
      final vm = visualVm('vector-magnitude', sample.values, mode: sample.mode);
      addTearDown(vm.dispose);
      final model = mapVisualModel(vm.result!)! as VectorVisualModel;
      expect(model.is3d, sample.mode == '3d');
      for (final point in model.points) {
        expect(point.x.isFinite && point.y.isFinite, isTrue);
        expect(point.x.abs(), lessThanOrEqualTo(1));
        expect(point.y.abs(), lessThanOrEqualTo(1));
      }
      expect(() => model.points.clear(), throwsUnsupportedError);
      expect(() => model.inputs.components.clear(), throwsUnsupportedError);
      expect(model.report.value, vm.result!.value);
      if (sample.values['y'] == '-4') {
        expect(model.points.last, (x: .75, y: -1.0));
      }
    });
  }

  test('Reynolds illustrative scale is bounded and monotonic without classification', () {
    var previous = -1.0;
    for (final speed in ['0', '.0001', '1', '20', '1e10']) {
      final vm = visualVm('reynolds-number', {
        ...visualSamples[2].values,
        'speed': speed,
      });
      addTearDown(vm.dispose);
      final model = mapVisualModel(vm.result!)! as ReynoldsVisualModel;
      expect(model.irregularity, inInclusiveRange(0, 1));
      expect(model.irregularity, greaterThanOrEqualTo(previous));
      expect(model.hasFlow, speed != '0');
      expect(model.summary, contains('not a flow-regime classification'));
      previous = model.irregularity;
    }
  });

  test(
    'IPv4 maps exact engine data and all 33 prefixes including boundaries',
    () {
      var previous = 2.0;
      for (var prefix = 0; prefix <= 32; prefix++) {
        final vm = visualVm('ipv4-subnet', {
          'address': '192.168.1.10',
          'prefix': '$prefix',
        });
        addTearDown(vm.dispose);
        final model = mapVisualModel(vm.result!)! as SubnetVisualModel;
        final original = (vm.result!.context! as SubnetContext).subnet;
        expect(identical(model.inputs.subnet, original), isTrue);
        expect(model.bits, '11000000101010000000000100001010');
        expect(model.inputs.subnet.prefix, prefix);
        expect(model.blockScale, lessThanOrEqualTo(previous));
        expect(model.blockScale, inInclusiveRange(0, 1));
        if (prefix >= 31) {
          expect(model.summary, contains('No directed broadcast'));
        }
        if (prefix == 0) {
          expect(model.summary, contains('4294967296 addresses'));
        }
        if (prefix == 32) expect(model.blockScale, 0);
        previous = model.blockScale;
      }
    },
  );

  test(
    'mapping cannot turn a missing/nonfinite result into a visualization',
    () {
      final vm = visualVm('voltage-divider', visualSamples[0].values);
      addTearDown(vm.dispose);
      for (final value in [null, double.nan, double.infinity]) {
        expect(
          mapVisualModel(
            CalculationResult(
              value: value,
              context: vm.result!.context,
              formattedValue: '',
              formula: '',
              substitution: '',
              explanation: '',
            ),
          ),
          isNull,
        );
      }
      vm.setValue('r1', '-1');
      expect(vm.result, isNull);
      vm.calculate();
      expect(vm.result, isNull);
    },
  );

  test(
    'external input update notifies once and invalidates failed results',
    () {
      final vm = visualVm('voltage-divider', visualSamples[0].values);
      addTearDown(vm.dispose);
      final originalRevision = vm.revision;
      var notifications = 0;
      vm.addListener(() => notifications++);
      vm.updateAndCalculate('voltage', '24');
      expect(vm.valueFor('voltage'), '24');
      expect(vm.result!.value, 16);
      expect(vm.revision, originalRevision + 1);
      expect(notifications, 1);
      vm.updateAndCalculate('unknown-field', '1');
      expect(notifications, 1);
      vm.updateAndCalculate('r1', '-1');
      expect(vm.result, isNull);
      expect(vm.errorFor('r1'), isNotNull);
    },
  );
}
