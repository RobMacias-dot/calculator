import 'dart:math' as math;

import '../../../../core/formatting/number_formatting.dart';
import '../../domain/calculation_context.dart';
import '../../domain/calculation_result.dart';
import '../../domain/engines/ipv4_address.dart';

typedef PlotPoint = ({double x, double y});

sealed class VisualModel {
  const VisualModel(this.report, this.summary);
  final CalculationResult report;
  final String summary;
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

String quantityLabel(CalculatedInput input) =>
    '${NumberFormatting.format(input.baseValue)}${input.baseUnit.symbol.isEmpty ? '' : ' ${input.baseUnit.symbol}'}';

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
