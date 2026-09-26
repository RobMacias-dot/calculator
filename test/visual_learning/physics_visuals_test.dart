import 'dart:ui' as ui;

import 'package:engineering_toolkit/features/calculators/domain/calculation_result.dart';
import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/newton_visual.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/torque_visual.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/bernoulli_visual.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/visual_learning_samples.dart';

CalculationResult supplied(CalculationResult original, double value) =>
    CalculationResult(
      value: value,
      context: original.context,
      formattedValue: '$value',
      formula: original.formula,
      substitution: '',
      explanation: '',
    );

void main() {
  test('Newton maps signed result, zero mass and extreme finite inputs without solving force', () {
    for (final values in [
      {'mass': '2', 'acceleration': '-3'},
      {'mass': '0', 'acceleration': '20'},
      {'mass': '100', 'acceleration': '0'},
      {'mass': '1e-200', 'acceleration': '1e100'},
      {'mass': '1e200', 'acceleration': '1e-100'},
    ]) {
      final vm = visualVm('newtons-second-law', values);
      addTearDown(vm.dispose);
      final model = mapVisualModel(vm.result!)! as NewtonVisualModel;
      expect(model.report, same(vm.result));
      expect(model.massSize, inInclusiveRange(0, 1));
      expect(model.forceArrow, inInclusiveRange(-1, 1));
      expect(model.accelerationArrow, inInclusiveRange(-1, 1));
      expect(
        model.inputs.acceleration.baseValue,
        double.parse(values['acceleration']!),
      );
      final synthetic =
          mapVisualModel(supplied(vm.result!, -123))! as NewtonVisualModel;
      expect(synthetic.forceArrow, lessThan(0));
      expect(synthetic.report.value, -123);
      expect(synthetic.summary, contains('-123.0 N'));
    }
  });

  test(
    'Newton maps grams as base mass and keeps the only existing force mode',
    () {
      final vm = visualVm('newtons-second-law', {
        'mass': '500',
        'acceleration': '2',
      });
      addTearDown(vm.dispose);
      vm.setUnit('mass', EngineeringUnit.gram);
      vm.calculate();
      final model = mapVisualModel(vm.result!)! as NewtonVisualModel;
      expect(model.inputs.mass.baseValue, .5);
      expect(vm.definition.modes.map((m) => m.id), ['force']);
      expect(vm.inputs.map((i) => i.id), ['mass', 'acceleration']);
    },
  );

  test('Torque maps nonnegative force/radius, zero and extremes with no angle mode', () {
    for (final values in [
      {'force': '0', 'radius': '5'},
      {'force': '100', 'radius': '0'},
      {'force': '1e200', 'radius': '1e-100'},
      {'force': '1e-100', 'radius': '1e200'},
    ]) {
      final vm = visualVm('torque', values);
      addTearDown(vm.dispose);
      final model = mapVisualModel(vm.result!)! as TorqueVisualModel;
      expect(model.leverLength, inInclusiveRange(0, 1));
      expect(model.forceArrow, inInclusiveRange(0, 1));
      expect(model.report, same(vm.result));
      if (values['radius'] == '0') expect(model.leverLength, 0);
      if (values['force'] == '0') expect(model.forceArrow, 0);
      expect(vm.inputs.map((i) => i.id), ['force', 'radius']);
      expect(vm.definition.modes.map((m) => m.id), ['torque']);
      final synthetic =
          mapVisualModel(supplied(vm.result!, 321))! as TorqueVisualModel;
      expect(synthetic.summary, contains('321.0 N·m'));
    }
  });

  test(
    'Bernoulli maps all inputs, signed P2 and finite common display scales',
    () {
      for (final overrides in [
        <String, String>{},
        {
          'speed1': '0',
          'speed2': '0',
          'height1': '0',
          'height2': '0',
          'pressure1': '-100',
        },
        {
          'speed1': '1e100',
          'speed2': '1e100',
          'height1': '-1e100',
          'height2': '1e100',
        },
        {
          'pressure1': '1e300',
          'density': '1e-200',
          'speed1': '0',
          'speed2': '1e-100',
        },
      ]) {
        final vm = visualVm('bernoulli-basic', {
          ...visualSamples[6].values,
          ...overrides,
        });
        addTearDown(vm.dispose);
        final model = mapVisualModel(vm.result!)! as BernoulliVisualModel;
        for (final value in [
          model.elevation1,
          model.elevation2,
          model.speed1,
          model.speed2,
          model.pressure1,
          model.pressure2,
        ]) {
          expect(value.isFinite, isTrue);
          expect(value, inInclusiveRange(-1, 1));
        }
        expect(model.report, same(vm.result));
        expect(
          model.inputs.density.baseValue,
          double.parse(vm.valueFor('density')),
        );
        expect(vm.definition.modes.map((m) => m.id), ['pressure2']);
        final synthetic =
            mapVisualModel(supplied(vm.result!, -1e300))!
                as BernoulliVisualModel;
        expect(synthetic.pressure2, -1);
        expect(synthetic.report.value, -1e300);
      }
    },
  );

  test('physics mappers reject nonfinite or absent results', () {
    for (final sample in visualSamples.skip(4)) {
      final vm = visualVm(sample.id, sample.values);
      addTearDown(vm.dispose);
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(mapVisualModel(supplied(vm.result!, value)), isNull);
      }
      expect(
        mapVisualModel(
          CalculationResult(
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
  });

  test('static physics painters are deterministic across sizes and repaint only relevant changes', () {
    final newton = visualVm('newtons-second-law', visualSamples[4].values);
    final torque = visualVm('torque', visualSamples[5].values);
    final bernoulli = visualVm('bernoulli-basic', visualSamples[6].values);
    addTearDown(newton.dispose);
    addTearDown(torque.dispose);
    addTearDown(bernoulli.dispose);
    NewtonPainter n(Color color) => NewtonPainter(
      mapVisualModel(newton.result!)! as NewtonVisualModel,
      color,
      Colors.blue,
      const TextScaler.linear(2),
      const TextStyle(),
    );
    TorquePainter t(Color color) => TorquePainter(
      mapVisualModel(torque.result!)! as TorqueVisualModel,
      color,
      Colors.blue,
      const TextScaler.linear(2),
      const TextStyle(),
    );
    BernoulliPainter b(Color color) => BernoulliPainter(
      mapVisualModel(bernoulli.result!)! as BernoulliVisualModel,
      color,
      Colors.blue,
      const TextScaler.linear(2),
      const TextStyle(),
    );
    final oldN = n(Colors.black),
        oldT = t(Colors.black),
        oldB = b(Colors.black);
    expect(n(Colors.black).shouldRepaint(oldN), isFalse);
    expect(t(Colors.black).shouldRepaint(oldT), isFalse);
    expect(b(Colors.black).shouldRepaint(oldB), isFalse);
    expect(n(Colors.white).shouldRepaint(oldN), isTrue);
    expect(t(Colors.white).shouldRepaint(oldT), isTrue);
    expect(b(Colors.white).shouldRepaint(oldB), isTrue);
    newton.updateAndCalculate('acceleration', '-3');
    torque.updateAndCalculate('radius', '0');
    bernoulli.updateAndCalculate('height2', '-4');
    expect(n(Colors.black).shouldRepaint(oldN), isTrue);
    expect(t(Colors.black).shouldRepaint(oldT), isTrue);
    expect(b(Colors.black).shouldRepaint(oldB), isTrue);
    for (final painter in [
      oldN,
      oldT,
      oldB,
      n(Colors.black),
      t(Colors.black),
      b(Colors.black),
    ]) {
      for (final size in [const Size(200, 148), const Size(600, 444)]) {
        final recorder = ui.PictureRecorder();
        painter.paint(Canvas(recorder), size);
        recorder.endRecording().dispose();
      }
    }
  });
}
