import '../../../../core/formatting/number_formatting.dart';
import '../calculator_category.dart';
import '../calculator_definition.dart';
import '../numeric_mode.dart';
import '../engines/thermal.dart';

CalculatorDefinition createSensibleHeatDefinition() {
  final mass = CalculatorInput(
    id: 'mass',
    label: 'Mass',
    units: [EngineeringUnit.kilogram, EngineeringUnit.gram],
  );
  final specificHeat = CalculatorInput(
    id: 'specificHeat',
    label: 'Specific heat capacity',
    units: [
      EngineeringUnit.specificHeat,
      EngineeringUnit.kilojouleSpecificHeat,
    ],
  );
  final temperatureChange = CalculatorInput(
    id: 'temperatureChange',
    label: 'Temperature change',
    units: [
      EngineeringUnit.kelvinDifference,
      EngineeringUnit.celsiusDifference,
    ],
  );
  final mode0 = numericMode(
    id: 'heat',
    label: 'Heat (Q)',
    formula: 'Q = m × c × ΔT',
    inputs: [mass, specificHeat, temperatureChange],
    unit: EngineeringUnit.joule,
    solve: (v) => SensibleHeat.calculate(
      mass: v[mass.id]!,
      specificHeat: v[specificHeat.id]!,
      temperatureChange: v[temperatureChange.id]!,
    ),
    substitution: (v) =>
        'Q = ${NumberFormatting.operand(v[mass.id]!)} kg × ${NumberFormatting.operand(v[specificHeat.id]!)} J/(kg·K) × ${NumberFormatting.operand(v[temperatureChange.id]!)} K',
    explanation: (v, result) =>
        'The material exchanges $result J. Positive heat warms it; negative heat corresponds to cooling.',
    alternateUnits: [EngineeringUnit.kilojoule],
  );
  return CalculatorDefinition(
    id: 'sensible-heat',
    name: 'Sensible Heat',
    description: 'Find heat transfer from a temperature change.',
    category: CalculatorCategory.thermodynamics,
    formula: mode0.formula,
    explanation: 'Find heat transfer from a temperature change.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Constant specific heat, no phase change. Temperature intervals satisfy Δ1 °C = Δ1 K.',
    ],
    keywords: ['heat', 'temperature', 'specific', 'cooling'],
  );
}

CalculatorDefinition createThermalEfficiencyDefinition() {
  final work = CalculatorInput(
    id: 'work',
    label: 'Work',
    units: [EngineeringUnit.joule, EngineeringUnit.kilojoule],
  );
  final heat = CalculatorInput(
    id: 'heat',
    label: 'Heat input Qin',
    units: [EngineeringUnit.joule, EngineeringUnit.kilojoule],
  );
  final mode0 = numericMode(
    id: 'efficiency',
    label: 'Efficiency (η)',
    formula: 'η = Wout / Qin',
    inputs: [work, heat],
    unit: EngineeringUnit.dimensionless,
    solve: (v) =>
        ThermalEfficiency.calculate(work: v[work.id]!, heat: v[heat.id]!),
    substitution: (v) =>
        'η = ${NumberFormatting.operand(v[work.id]!)} J / ${NumberFormatting.operand(v[heat.id]!)} J',
    explanation: (v, result) =>
        'A fraction $result of the supplied heat becomes useful work; the equivalent percentage is included in the result details.',
    alternateUnits: [EngineeringUnit.percent],
  );
  return CalculatorDefinition(
    id: 'thermal-efficiency',
    name: 'Thermal Efficiency',
    description: 'Compare useful work output with heat input.',
    category: CalculatorCategory.thermodynamics,
    formula: mode0.formula,
    explanation: 'Compare useful work output with heat input.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Heat-engine convention: 0 ≤ Wout ≤ Qin and Qin > 0; this is not a heat-pump coefficient of performance.',
      'Compare net useful work and supplied heat for the same cycle or interval. The ratio alone does not establish thermodynamic feasibility or a Carnot limit.',
    ],
    keywords: ['efficiency', 'heat engine', 'ratio'],
  );
}

CalculatorDefinition createTemperatureDefinition() {
  final temperature = CalculatorInput(
    id: 'temperature',
    label: 'Temperature',
    units: [
      EngineeringUnit.celsius,
      EngineeringUnit.fahrenheit,
      EngineeringUnit.kelvin,
    ],
  );
  final mode0 = numericMode(
    id: 'temperature',
    label: 'Absolute temperature',
    formula: 'K = °C + 273.15 = (°F + 459.67) × 5/9',
    inputs: [temperature],
    unit: EngineeringUnit.kelvin,
    solve: (v) => AbsoluteTemperature.kelvin(v[temperature.id]!),
    substitution: (v) =>
        'T = ${NumberFormatting.operand(v[temperature.id]!)} K (after conversion to the absolute scale)',
    explanation: (v, result) =>
        'The same physical temperature is $result K; Celsius and Fahrenheit use different zero points.',
    alternateUnits: [EngineeringUnit.celsius, EngineeringUnit.fahrenheit],
  );
  return CalculatorDefinition(
    id: 'temperature-converter',
    name: 'Temperature Converter',
    description: 'Convert Celsius, Fahrenheit and Kelvin.',
    category: CalculatorCategory.thermodynamics,
    formula: mode0.formula,
    explanation: 'Convert Celsius, Fahrenheit and Kelvin.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Absolute temperature cannot be below 0 K. These are absolute temperatures, not temperature differences.',
    ],
    keywords: ['celsius', 'fahrenheit', 'kelvin', 'temperature'],
  );
}

CalculatorDefinition createExpansionDefinition() {
  final coefficient = CalculatorInput(
    id: 'coefficient',
    label: 'Linear expansion coefficient',
    units: [EngineeringUnit.perKelvin, EngineeringUnit.perCelsius],
  );
  final length = CalculatorInput(
    id: 'length',
    label: 'Initial length',
    units: [
      EngineeringUnit.metre,
      EngineeringUnit.centimetre,
      EngineeringUnit.millimetre,
    ],
  );
  final temperatureChange = CalculatorInput(
    id: 'temperatureChange',
    label: 'Temperature change',
    units: [
      EngineeringUnit.kelvinDifference,
      EngineeringUnit.celsiusDifference,
    ],
  );
  final mode0 = numericMode(
    id: 'expansion',
    label: 'Length change',
    formula: 'ΔL = α × L0 × ΔT',
    inputs: [coefficient, length, temperatureChange],
    unit: EngineeringUnit.metre,
    solve: (v) => LinearExpansion.calculate(
      coefficient: v[coefficient.id]!,
      length: v[length.id]!,
      temperatureChange: v[temperatureChange.id]!,
    ),
    substitution: (v) =>
        'ΔL = ${NumberFormatting.operand(v[coefficient.id]!)} /K × ${NumberFormatting.operand(v[length.id]!)} m × ${NumberFormatting.operand(v[temperatureChange.id]!)} K',
    explanation: (v, result) =>
        'The estimated length change is $result m. Add it to the initial length; a negative result denotes contraction.',
    alternateUnits: [EngineeringUnit.millimetre],
  );
  return CalculatorDefinition(
    id: 'linear-expansion',
    name: 'Linear Thermal Expansion',
    description: 'Estimate a length change from heating or cooling.',
    category: CalculatorCategory.thermodynamics,
    formula: mode0.formula,
    explanation: 'Estimate a length change from heating or cooling.',
    inputs: mode0.inputs,
    modes: [mode0],
    assumptions: [
      'Linear approximation with constant expansion coefficient and small strain. Δ1 °C = Δ1 K; negative coefficients are allowed for materials that contract on heating.',
      'Use a coefficient appropriate to the material and entered temperature interval. ΔT is final minus initial temperature; phase changes, varying coefficients and restraint stresses are outside the model.',
    ],
    keywords: ['expansion', 'thermal', 'length', 'coefficient'],
  );
}
