import 'engineering_unit.dart';

enum CalculatorInputKind { decimal, integer, ipv4, text }

class CalculatorInput {
  CalculatorInput({
    required this.id,
    required this.label,
    this.kind = CalculatorInputKind.decimal,
    List<EngineeringUnit> units = const [],
    this.minimum,
    this.maximum,
    this.minimumExclusive = false,
  }) : units = List.unmodifiable(units) {
    if (id.isEmpty || label.isEmpty) {
      throw ArgumentError('Input id and label must not be empty.');
    }
    if (units.map((unit) => unit.dimension).toSet().length > 1 ||
        units.toSet().length != units.length) {
      throw ArgumentError('Units must be unique and describe one quantity.');
    }
    if ((minimum != null && !minimum!.isFinite) ||
        (maximum != null && !maximum!.isFinite) ||
        (minimum != null &&
            maximum != null &&
            (minimum! > maximum! ||
                (minimumExclusive && minimum == maximum)))) {
      throw ArgumentError('Input bounds must define a finite, nonempty range.');
    }
  }

  final String id;
  final String label;
  final CalculatorInputKind kind;
  final List<EngineeringUnit> units;
  final double? minimum;
  final double? maximum;
  final bool minimumExclusive;
}
