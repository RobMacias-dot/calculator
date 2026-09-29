import 'dart:math' as math;

import '../../../../core/formatting/number_formatting.dart';
import '../../domain/calculation_context.dart';
import '../../domain/calculation_result.dart';
import '../../domain/engines/ipv4_address.dart';
import '../../domain/engines/ideal_gas_law.dart';
import '../../domain/engineering_unit.dart';

typedef PlotPoint = ({double x, double y});

sealed class VisualModel {
  const VisualModel(this.report, this.summary);
  final CalculationResult report;
  final String summary;
}

final class IdealGasVisualizationModel extends VisualModel {
  IdealGasVisualizationModel(
    super.report,
    super.summary,
    this.inputs,
    Map<GasVariable, double> values,
    this.chamberFraction,
    this.particleCount,
    this.motionIntensity,
  ) : values = Map.unmodifiable(values);

  final IdealGasContext inputs;
  final Map<GasVariable, double> values;
  final double chamberFraction;
  final int particleCount;
  final double motionIntensity;

  String label(GasVariable variable) =>
      '${variable == inputs.solved ? report.formattedValue : NumberFormatting.operand(values[variable]!)} ${gasUnit(variable).symbol}';
}

EngineeringUnit gasUnit(GasVariable variable) => switch (variable) {
  GasVariable.pressure => EngineeringUnit.pascal,
  GasVariable.volume => EngineeringUnit.cubicMetre,
  GasVariable.amount => EngineeringUnit.mole,
  GasVariable.temperature => EngineeringUnit.kelvin,
};

/// Consumes the solved value verbatim. All logarithms below are bounded display
/// scales, not gas equations. Clamp BEFORE division to handle finite extremes.
abstract final class IdealGasVisualizationMapper {
  static IdealGasVisualizationModel? map(CalculationResult report) {
    final context = report.context;
    final result = report.value;
    if (context is! IdealGasContext ||
        result == null ||
        !result.isFinite ||
        result <= 0 ||
        report.unit != gasUnit(context.solved) ||
        context.inputs.length != 3) {
      return null;
    }
    final values = <GasVariable, double>{context.solved: result};
    for (final variable in GasVariable.values) {
      if (variable == context.solved) continue;
      final matches = context.inputs.where((i) => i.input.id == variable.name);
      if (matches.length != 1) return null;
      final input = matches.single;
      if (!input.baseValue.isFinite ||
          input.baseValue <= 0 ||
          input.baseUnit != gasUnit(variable)) {
        return null;
      }
      values[variable] = input.baseValue;
    }
    double scale(GasVariable variable, double ceiling) =>
        math.log(1 + values[variable]!.clamp(0.0, ceiling) / ceiling * 9) /
        math.ln10;
    // Educational reference ceilings: 100 L, 5 mol, 1000 K. There is a
    // readable minimum even for very small valid gas states. Never domain limits.
    return IdealGasVisualizationModel(
      report,
      'Ideal gas visualization. ${GasVariable.values.map((v) => '${v.name} ${v == context.solved ? report.formattedValue : NumberFormatting.operand(values[v]!)} ${gasUnit(v).symbol}').join(', ')}. '
      'Calculated ${context.solved.name}. Higher temperature is represented by faster particle motion. '
      'Piston size, particle count, speed and arrangement are illustrative.',
      context,
      values,
      .28 + .62 * scale(GasVariable.volume, .1),
      12 + (24 * scale(GasVariable.amount, 5)).round(),
      .15 + .85 * scale(GasVariable.temperature, 1000),
    );
  }
}

final class DividerVisualModel extends VisualModel {
  const DividerVisualModel(
    super.report,
    super.summary,
    this.inputs,
    this.outputFraction,
  );
  final DividerContext inputs;
  // Null at Vin=0: no voltage ratio can be inferred from two zero voltages.
  final double? outputFraction;
}

final class VectorVisualModel extends VisualModel {
  VectorVisualModel(
    super.report,
    super.summary,
    this.inputs,
    List<PlotPoint> points,
  ) : points = List.unmodifiable(points);
  final VectorContext inputs;
  final List<PlotPoint> points;
  bool get is3d => inputs.components.length == 3;
}

final class ReynoldsVisualModel extends VisualModel {
  const ReynoldsVisualModel(
    super.report,
    super.summary,
    this.inputs,
    this.irregularity,
    this.hasFlow,
  );
  final ReynoldsContext inputs;
  final double irregularity;
  final bool hasFlow;
}

final class SubnetVisualModel extends VisualModel {
  const SubnetVisualModel(
    super.report,
    super.summary,
    this.inputs,
    this.bits,
    this.network,
    this.lastAddress,
    this.blockScale,
  );
  final SubnetContext inputs;
  final String bits;
  final String network;
  final String lastAddress;
  // Logarithmic display scale, not a count or a linear address-space fraction.
  final double blockScale;
}

final class NewtonVisualModel extends VisualModel {
  const NewtonVisualModel(
    super.report,
    super.summary,
    this.inputs,
    this.massSize,
    this.forceArrow,
    this.accelerationArrow,
  );
  final NewtonContext inputs;
  final double massSize;
  final double forceArrow;
  final double accelerationArrow;
}

final class TorqueVisualModel extends VisualModel {
  const TorqueVisualModel(
    super.report,
    super.summary,
    this.inputs,
    this.leverLength,
    this.forceArrow,
  );
  final TorqueContext inputs;
  final double leverLength;
  final double forceArrow;
}

final class BernoulliVisualModel extends VisualModel {
  const BernoulliVisualModel(
    super.report,
    super.summary,
    this.inputs,
    this.elevation1,
    this.elevation2,
    this.speed1,
    this.speed2,
    this.pressure1,
    this.pressure2,
  );
  final BernoulliContext inputs;
  // Bounded common scales for each pair; never physical pipe dimensions.
  final double elevation1, elevation2, speed1, speed2, pressure1, pressure2;
}

// Capped logarithmic display intensity. No physical result is computed here.
double _displayMagnitude(double value, double ceiling) =>
    (math.log(1 + value.abs()) / math.log(1 + ceiling)).clamp(0.0, 1.0);

String quantityLabel(CalculatedInput input) =>
    '${NumberFormatting.operand(input.baseValue)}${input.baseUnit.symbol.isEmpty ? '' : ' ${input.baseUnit.symbol}'}';

/// Maps only successful reports. Never parses user text, reruns a solver or
/// reverse-parses rounded presentation strings. Clamping is visual only.
VisualModel? mapVisualModel(CalculationResult report) {
  final context = report.context;
  if (context is SubnetContext) {
    final subnet = context.subnet;
    if (subnet.prefix < 0 || subnet.prefix > 32) return null;
    final bits = subnet.address.bits.toRadixString(2).padLeft(32, '0');
    final network = Ipv4Address.formatBits(subnet.network);
    final last = Ipv4Address.formatBits(subnet.lastAddress);
    // Existing exact count -> display logarithm. No subnet arithmetic here.
    final scale = math.log(subnet.totalAddresses.toDouble()) / math.ln2 / 32;
    return SubnetVisualModel(
      report,
      'IPv4 ${subnet.address}. ${subnet.prefix} network bits, '
      '${32 - subnet.prefix} host bits. ${subnet.totalAddresses} addresses. '
      'Network $network; last address $last. '
      '${subnet.broadcastAddress == null ? 'No directed broadcast.' : ''}',
      context,
      bits,
      network,
      last,
      scale.clamp(0.0, 1.0),
    );
  }
  final value = report.value;
  if (value == null || !value.isFinite) return null;
  switch (context) {
    case IdealGasContext():
      return IdealGasVisualizationMapper.map(report);
    case NewtonContext():
      if (!_finite([context.mass, context.acceleration]) ||
          context.mass.baseValue < 0) {
        return null;
      }
      return NewtonVisualModel(
        report,
        'Newton’s Second Law. Mass ${quantityLabel(context.mass)}. '
        'Input acceleration ${quantityLabel(context.acceleration)}. '
        'Calculated net force ${report.formattedValue} N. '
        'Arrows show signed axis directions; sizes are illustrative.',
        context,
        _displayMagnitude(context.mass.baseValue, 100),
        value.sign * _displayMagnitude(value, 1000),
        context.acceleration.baseValue.sign *
            _displayMagnitude(context.acceleration.baseValue, 20),
      );
    case TorqueContext():
      if (!_finite([context.force, context.radius]) ||
          context.force.baseValue < 0 ||
          context.radius.baseValue < 0 ||
          value < 0) {
        return null;
      }
      return TorqueVisualModel(
        report,
        'Torque. Perpendicular force ${quantityLabel(context.force)}. '
        'Lever arm ${quantityLabel(context.radius)}. '
        'Calculated torque magnitude ${report.formattedValue} N·m. '
        'The depicted orientation is illustrative; no signed rotation or angle input is calculated.',
        context,
        _displayMagnitude(context.radius.baseValue, 5),
        _displayMagnitude(context.force.baseValue, 100),
      );
    case BernoulliContext():
      if (!_finite([
            context.pressure1,
            context.density,
            context.speed1,
            context.speed2,
            context.height1,
            context.height2,
          ]) ||
          context.density.baseValue <= 0 ||
          context.speed1.baseValue < 0 ||
          context.speed2.baseValue < 0) {
        return null;
      }
      final heights = math.max(
        1.0,
        math.max(
          context.height1.baseValue.abs(),
          context.height2.baseValue.abs(),
        ),
      );
      final speeds = math.max(
        1.0,
        math.max(context.speed1.baseValue, context.speed2.baseValue),
      );
      final pressures = math.max(
        1.0,
        math.max(context.pressure1.baseValue.abs(), value.abs()),
      );
      return BernoulliVisualModel(
        report,
        'Bernoulli. Station 1: pressure ${quantityLabel(context.pressure1)}, '
        'speed ${quantityLabel(context.speed1)}, elevation ${quantityLabel(context.height1)}. '
        'Station 2: calculated pressure ${report.formattedValue} Pa, '
        'speed ${quantityLabel(context.speed2)}, elevation ${quantityLabel(context.height2)}. '
        'Density ${quantityLabel(context.density)}. Schematic streamline, no simulated fluid field.',
        context,
        context.height1.baseValue / heights,
        context.height2.baseValue / heights,
        context.speed1.baseValue / speeds,
        context.speed2.baseValue / speeds,
        context.pressure1.baseValue / pressures,
        value / pressures,
      );
    case DividerContext():
      if (!_finite([context.voltage, context.r1, context.r2])) return null;
      final fraction = context.voltage.baseValue == 0
          ? null
          : (value / context.voltage.baseValue).clamp(0.0, 1.0);
      return DividerVisualModel(
        report,
        'Voltage divider. Input ${quantityLabel(context.voltage)}, '
        'R1 ${quantityLabel(context.r1)}, R2 ${quantityLabel(context.r2)}. '
        'Output ${report.formattedValue} volts across R2.',
        context,
        fraction,
      );
    case VectorContext():
      if ((context.components.length != 2 && context.components.length != 3) ||
          !_finite(context.components)) {
        return null;
      }
      final scale = context.components.fold(
        0.0,
        (largest, component) => math.max(largest, component.baseValue.abs()),
      );
      // Normalize before projection so even extreme finite values stay finite.
      final components = context.components
          .map((component) => scale == 0 ? 0.0 : component.baseValue / scale)
          .toList();
      final x = components[0], y = components[1];
      final points = context.components.length == 2
          ? <PlotPoint>[(x: 0, y: 0), (x: x, y: 0), (x: x, y: y)]
          : <PlotPoint>[
              (x: 0, y: 0),
              (x: 0.45 * x, y: -0.23 * x),
              (x: 0.45 * (x - y), y: -0.23 * (x + y)),
              (x: 0.45 * (x - y), y: -0.23 * (x + y) + 0.5 * components[2]),
            ];
      return VectorVisualModel(
        report,
        '${components.length}D vector. ${context.components.map((c) => '${c.input.label} ${quantityLabel(c)}').join(', ')}. '
        'Magnitude ${report.formattedValue}. ${components.length == 3 ? 'Oblique projection; screen length is not the magnitude.' : 'Axes share an automatically fitted scale.'}',
        context,
        points,
      );
    case ReynoldsContext():
      if (!_finite([context.speed]) || value < 0) return null;
      // Artistic logarithmic scale only: no laminar/turbulent thresholds.
      final intensity = value <= 1
          ? 0.0
          : (math.log(value) / math.ln10 / 6).clamp(0.0, 1.0);
      return ReynoldsVisualModel(
        report,
        'Reynolds number ${report.formattedValue}. Speed ${quantityLabel(context.speed)}. '
        '${value == 0 ? 'No flow.' : 'Illustrative flow with progressively more irregular paths as Reynolds number increases.'} '
        'Not CFD and not a flow-regime classification.',
        context,
        intensity,
        context.speed.baseValue > 0,
      );
    case SubnetContext():
    case null:
      return null;
  }
}

bool _finite(List<CalculatedInput> inputs) =>
    inputs.every((input) => input.baseValue.isFinite);
