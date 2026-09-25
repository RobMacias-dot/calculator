import '../calculation_outcome.dart';

enum GasVariable { pressure, volume, amount, temperature }

abstract final class IdealGasLaw {
  /// J/(mol·K), numerically equivalent to Pa·m³/(mol·K).
  static const gasConstant = 8.31446261815324;

  static CalculationOutcome<double> pressure({
    required double amount,
    required double temperature,
    required double volume,
  }) => _evaluate(
    {
      GasVariable.amount: amount,
      GasVariable.temperature: temperature,
      GasVariable.volume: volume,
    },
    {GasVariable.volume},
    () => amount * gasConstant * temperature / volume,
  );

  static CalculationOutcome<double> volume({
    required double amount,
    required double temperature,
    required double pressure,
  }) => _evaluate(
    {
      GasVariable.amount: amount,
      GasVariable.temperature: temperature,
      GasVariable.pressure: pressure,
    },
    {GasVariable.pressure},
    () => amount * gasConstant * temperature / pressure,
  );

  static CalculationOutcome<double> amount({
    required double pressure,
    required double volume,
    required double temperature,
  }) => _evaluate(
    {
      GasVariable.pressure: pressure,
      GasVariable.volume: volume,
      GasVariable.temperature: temperature,
    },
    {GasVariable.temperature},
    () => pressure * volume / (gasConstant * temperature),
  );

  static CalculationOutcome<double> temperature({
    required double pressure,
    required double volume,
    required double amount,
  }) => _evaluate(
    {
      GasVariable.pressure: pressure,
      GasVariable.volume: volume,
      GasVariable.amount: amount,
    },
    {GasVariable.amount},
    () => pressure * volume / (amount * gasConstant),
  );

  /// Positive absolute P, V, n and T describe a nonempty ideal gas state.
  static CalculationOutcome<double> _evaluate(
    Map<GasVariable, double> inputs,
    Set<GasVariable> divisors,
    double Function() calculate,
  ) {
    final issues = finiteInputIssues({
      for (final entry in inputs.entries) entry.key.name: entry.value,
    });
    if (issues.isNotEmpty) return CalculationFailure(issues);
    for (final entry in inputs.entries) {
      if (entry.value <= 0) {
        issues.add(
          CalculationIssue(
            entry.value == 0 && divisors.contains(entry.key)
                ? CalculationError.divisionByZero
                : CalculationError.outOfDomain,
            entry.key == GasVariable.temperature
                ? 'Absolute temperature must be greater than 0 K (−273.15 °C).'
                : 'This quantity must be greater than zero in an ideal gas state.',
            fieldId: entry.key.name,
          ),
        );
      }
    }
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return checkedResult(calculate(), zeroExpected: false);
  }
}
