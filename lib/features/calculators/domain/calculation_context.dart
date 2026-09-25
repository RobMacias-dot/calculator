import 'calculator_input.dart';
import 'engineering_unit.dart';
import 'engines/ipv4_subnet.dart';

/// Unrounded, validated facts retained with a successful report. No rendering
/// geometry or secondary solver: these values come from the existing pipeline.
sealed class CalculationContext {
  const CalculationContext();
}

class CalculatedInput {
  const CalculatedInput(this.input, this.baseValue, this.baseUnit);
  final CalculatorInput input;
  final double baseValue;
  final EngineeringUnit baseUnit;
}

final class DividerContext extends CalculationContext {
  const DividerContext(this.voltage, this.r1, this.r2);
  final CalculatedInput voltage;
  final CalculatedInput r1;
  final CalculatedInput r2;
}

final class VectorContext extends CalculationContext {
  VectorContext(List<CalculatedInput> components)
    : components = List.unmodifiable(components);
  final List<CalculatedInput> components;
}

final class ReynoldsContext extends CalculationContext {
  const ReynoldsContext(this.speed);
  final CalculatedInput speed;
}

final class SubnetContext extends CalculationContext {
  const SubnetContext(this.subnet);
  final Ipv4SubnetResult subnet;
}
