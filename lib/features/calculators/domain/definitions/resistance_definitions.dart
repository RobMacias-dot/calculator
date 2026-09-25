import '../calculator_category.dart';
import '../calculator_definition.dart';
import '../resistor_mode.dart';

CalculatorDefinition createSeriesResistanceDefinition() {
  final mode = ResistorMode(parallel: false);
  return CalculatorDefinition(
    id: 'series-resistance',
    name: 'Series Resistance',
    description: 'Add any number of resistors in series.',
    category: CalculatorCategory.electrical,
    formula: mode.formula,
    explanation:
        'Resistances add when the same current passes through every component.',
    inputs: mode.inputs,
    modes: [mode],
    assumptions: [
      'Ideal resistors connected in series. Resistances may be zero but not negative.',
    ],
    keywords: ['resistors', 'resistance', 'series', 'equivalent'],
  );
}

CalculatorDefinition createParallelResistanceDefinition() {
  final mode = ResistorMode(parallel: true);
  return CalculatorDefinition(
    id: 'parallel-resistance',
    name: 'Parallel Resistance',
    description: 'Combine positive resistors connected in parallel.',
    category: CalculatorCategory.electrical,
    formula: mode.formula,
    explanation:
        'Conductances add because all branches share the same voltage.',
    inputs: mode.inputs,
    modes: [mode],
    assumptions: [
      'Ideal parallel branches with strictly positive finite resistance. Short circuits are outside this input model.',
    ],
    keywords: ['resistors', 'resistance', 'parallel', 'equivalent'],
  );
}
