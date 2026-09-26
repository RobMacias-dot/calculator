import 'package:engineering_toolkit/features/calculators/domain/calculation_context.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculation_result.dart';
import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/ideal_gas_law.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/ideal_gas_visual.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/visual_learning_samples.dart';

const gasValues = {
  'pressure': '100000',
  'volume': '.025',
  'amount': '1',
  'temperature': '300',
};

CalculationResult synthetic(
  CalculationResult original, {
  double? value,
  IdealGasContext? context,
}) => CalculationResult(
  value: value ?? original.value,
  unit: original.unit,
  context: context ?? original.context,
  formattedValue: 'synthetic',
  formula: '',
  substitution: '',
  explanation: '',
);

void main() {
  for (final variable in GasVariable.values) {
    test(
      'gas ${variable.name} maps three normalized inputs and verbatim output',
      () {
        final vm = visualVm('ideal-gas-law', gasValues, mode: variable.name);
        addTearDown(vm.dispose);
        final model = mapVisualModel(vm.result!)! as IdealGasVisualizationModel;
        expect(model.inputs.solved, variable);
        expect(model.inputs.inputs.length, 3);
        expect(
          model.inputs.inputs.any((i) => i.input.id == variable.name),
          isFalse,
        );
        expect(model.values[variable], vm.result!.value);
        expect(model.report, same(vm.result));
        final supplied = IdealGasVisualizationMapper.map(
          synthetic(vm.result!, value: 123.456),
        )!;
        expect(supplied.values[variable], 123.456);
        expect(supplied.label(variable), startsWith('synthetic'));
        expect(() => supplied.values[variable] = 2, throwsUnsupportedError);
        expect(() => model.inputs.inputs.clear(), throwsUnsupportedError);
      },
    );
  }

  test('gas Celsius litres and pressure units use existing normalization', () {
    final vm = visualVm('ideal-gas-law', gasValues);
    addTearDown(vm.dispose);
    vm.setUnit('temperature', EngineeringUnit.celsius);
    vm.setValue('temperature', '-20');
    vm.setUnit('volume', EngineeringUnit.litre);
    vm.updateAndCalculate('volume', '25');
    var model = IdealGasVisualizationMapper.map(vm.result!)!;
    expect(model.values[GasVariable.temperature], closeTo(253.15, 1e-10));
    expect(model.values[GasVariable.volume], .025);
    vm.selectMode(vm.definition.modes[1]);
    vm.setValue('amount', '1');
    vm.setValue('temperature', '300');
    vm.setUnit('pressure', EngineeringUnit.atmosphere);
    vm.updateAndCalculate('pressure', '1');
    model = IdealGasVisualizationMapper.map(vm.result!)!;
    expect(model.values[GasVariable.pressure], 101325);
  });

  for (final extreme in ['1e-90', '1e90']) {
    for (final variable in GasVariable.values) {
      test('valid extreme $extreme in ${variable.name} stays bounded', () {
        final vm = visualVm('ideal-gas-law', {
          for (final key in gasValues.keys) key: extreme,
        }, mode: variable.name);
        addTearDown(vm.dispose);
        expect(vm.result, isNotNull);
        final model = IdealGasVisualizationMapper.map(vm.result!)!;
        expect(model.chamberFraction, inInclusiveRange(.28, .9));
        expect(model.particleCount, inInclusiveRange(12, 36));
        expect(model.motionIntensity, inInclusiveRange(.15, 1));
        expect(model.values.values.every((v) => v.isFinite && v > 0), isTrue);
      });
    }
  }

  test(
    'visual scales change monotonically then saturate, never alter quantities',
    () {
      final vm = visualVm('ideal-gas-law', gasValues);
      addTearDown(vm.dispose);
      var previous = IdealGasVisualizationMapper.map(vm.result!)!;
      for (final entry in {
        'volume': '.05',
        'amount': '2',
        'temperature': '600',
      }.entries) {
        vm.updateAndCalculate(entry.key, entry.value);
        final next = IdealGasVisualizationMapper.map(vm.result!)!;
        expect(
          next.chamberFraction,
          greaterThanOrEqualTo(previous.chamberFraction),
        );
        expect(
          next.particleCount,
          greaterThanOrEqualTo(previous.particleCount),
        );
        expect(
          next.motionIntensity,
          greaterThanOrEqualTo(previous.motionIntensity),
        );
        expect(
          [next.chamberFraction, next.particleCount, next.motionIntensity],
          isNot([
            previous.chamberFraction,
            previous.particleCount,
            previous.motionIntensity,
          ]),
        );
        previous = next;
      }
      vm.updateAndCalculate('volume', '1e300');
      final next = IdealGasVisualizationMapper.map(vm.result!)!;
      expect(next.chamberFraction, closeTo(.9, 1e-12));
      expect(next.values[GasVariable.volume], 1e300);
    },
  );

  test(
    'mapper rejects missing, invalid and malformed reports without rendering',
    () {
      final vm = visualVm('ideal-gas-law', gasValues);
      addTearDown(vm.dispose);
      final report = vm.result!;
      for (final invalid in [0.0, -1.0, double.nan, double.infinity]) {
        expect(
          IdealGasVisualizationMapper.map(synthetic(report, value: invalid)),
          isNull,
        );
        final c = report.context! as IdealGasContext;
        expect(
          IdealGasVisualizationMapper.map(
            synthetic(
              report,
              context: IdealGasContext(c.solved, [
                CalculatedInput(
                  c.inputs.first.input,
                  invalid,
                  c.inputs.first.baseUnit,
                ),
                ...c.inputs.skip(1),
              ]),
            ),
          ),
          isNull,
        );
      }
      expect(
        IdealGasVisualizationMapper.map(
          synthetic(report, context: IdealGasContext(GasVariable.pressure, [])),
        ),
        isNull,
      );
      expect(
        IdealGasVisualizationMapper.map(
          CalculationResult(
            formattedValue: '',
            formula: '',
            substitution: '',
            explanation: '',
          ),
        ),
        isNull,
      );
      vm.updateAndCalculate('temperature', '0');
      expect(vm.result, isNull);
    },
  );

  test(
    'seed positions are deterministic finite bounded and seamless each cycle',
    () {
      final seeds = IdealGasParticles.seeds;
      expect(seeds.length, 36);
      expect(() => seeds.clear(), throwsUnsupportedError);
      for (final size in [
        const Size(1, 1),
        const Size(240, 180),
        const Size(680, 400),
      ]) {
        for (final fraction in [.28, .6, .9]) {
          final painter = IdealGasPainter(
            phase: const AlwaysStoppedAnimation(0),
            chamberFraction: fraction,
            particleCount: 36,
            ink: Colors.black,
            accent: Colors.orange,
          );
          final chamber = painter.chamberFor(size);
          final region = painter.particleRegionFor(size);
          expect(chamber.width, greaterThan(0));
          expect(chamber.top, greaterThanOrEqualTo(0));
          expect(chamber.bottom, lessThanOrEqualTo(size.height));
          for (var i = 0; i < seeds.length; i++) {
            for (final phase in [0.0, .001, .25, .7, .999, 1.0]) {
              final p = IdealGasParticles.position(i, phase, region);
              expect(p.dx.isFinite && p.dy.isFinite, isTrue);
              expect(chamber.contains(p), isTrue);
              expect(p, IdealGasParticles.position(i, phase, region));
            }
            expect(
              (IdealGasParticles.position(i, 0, region) -
                      IdealGasParticles.position(i, 1, region))
                  .distance,
              lessThan(1e-10),
            );
          }
        }
      }
      expect(IdealGasParticles.seeds, same(seeds));
    },
  );

  test('painter compares all geometry style and animation dependencies', () {
    const phase = AlwaysStoppedAnimation(0.0);
    IdealGasPainter painter({
      double fraction = .5,
      int count = 24,
      Color ink = Colors.black,
      Color accent = Colors.orange,
      Animation<double> clock = phase,
    }) => IdealGasPainter(
      phase: clock,
      chamberFraction: fraction,
      particleCount: count,
      ink: ink,
      accent: accent,
    );
    final original = painter();
    expect(painter().shouldRepaint(original), isFalse);
    for (final changed in [
      painter(fraction: .6),
      painter(count: 30),
      painter(ink: Colors.white),
      painter(accent: Colors.blue),
      painter(clock: const AlwaysStoppedAnimation(.1)),
    ]) {
      expect(changed.shouldRepaint(original), isTrue);
    }
  });
}
