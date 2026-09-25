import 'calculator_category.dart';
import 'calculator_mode.dart';
import 'calculator_input.dart';

export 'engineering_unit.dart';
export 'calculator_input.dart';

/// Immutable catalog entry with optional executable modes.
/// Formula is explanatory text, not an instruction for a calculation engine.
class CalculatorDefinition {
  CalculatorDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.formula,
    required this.explanation,
    required List<CalculatorInput> inputs,
    List<CalculatorMode> modes = const [],
    List<String> keywords = const [],
    List<String> assumptions = const [],
    this.supportsVisualLearning = false,
  }) : inputs = List.unmodifiable(inputs),
       modes = List.unmodifiable(modes),
       keywords = List.unmodifiable(keywords),
       assumptions = List.unmodifiable(assumptions) {
    if (!RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(id)) {
      throw ArgumentError.value(id, 'id', 'Use a stable lowercase slug.');
    }
    if (inputs.map((input) => input.id).toSet().length != inputs.length) {
      throw ArgumentError('Input ids must be unique within a calculator.');
    }
    if (modes.map((mode) => mode.id).toSet().length != modes.length) {
      throw ArgumentError('Mode ids must be unique within a calculator.');
    }
  }

  final String id;
  final String name;
  final String description;
  final CalculatorCategory category;
  final String formula;
  final String explanation;
  final List<CalculatorInput> inputs;
  final List<CalculatorMode> modes;
  final List<String> keywords;
  final List<String> assumptions;
  final bool supportsVisualLearning;
  bool get isAvailable => modes.isNotEmpty;
}
