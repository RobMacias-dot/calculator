import 'calculator_input.dart';
import 'engineering_unit.dart';
import 'engines/ipv4_subnet.dart';
import 'engines/ideal_gas_law.dart';

/// Unrounded, validated facts retained with a successful report. No rendering
/// geometry or secondary solver: these values come from the existing pipeline.
sealed class CalculationContext {
  const CalculationContext();
}

/// Only the three supplied, validated SI inputs; the fourth quantity is the
/// report's value. Retaining the solved variable never requires another solver.
final class IdealGasContext extends CalculationContext {
  IdealGasContext(this.solved, List<CalculatedInput> inputs)
    : inputs = List.unmodifiable(inputs);
  final GasVariable solved;
  final List<CalculatedInput> inputs;
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

final class NewtonContext extends CalculationContext {
  const NewtonContext(this.mass, this.acceleration);
  final CalculatedInput mass;
  final CalculatedInput acceleration;
}

final class TorqueContext extends CalculationContext {
  const TorqueContext(this.force, this.radius);
  final CalculatedInput force;
  final CalculatedInput radius;
}

final class BernoulliContext extends CalculationContext {
  const BernoulliContext(
    this.pressure1,
    this.density,
    this.speed1,
    this.speed2,
    this.height1,
    this.height2,
  );
  final CalculatedInput pressure1;
  final CalculatedInput density;
  final CalculatedInput speed1;
  final CalculatedInput speed2;
  final CalculatedInput height1;
  final CalculatedInput height2;
}
