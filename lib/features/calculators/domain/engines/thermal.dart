import '../calculation_outcome.dart';
import 'input_checks.dart';

abstract final class SensibleHeat {
  static CalculationOutcome<double> calculate({
    required double mass,
    required double specificHeat,
    required double temperatureChange,
  }) {
    final issues = physicalInputIssues(
      {
        'mass': mass,
        'specificHeat': specificHeat,
        'temperatureChange': temperatureChange,
      },
      positive: {'specificHeat'},
      nonNegative: {'mass'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (mass == 0 || temperatureChange == 0) return const CalculationSuccess(0);
    return checkedResult(
      mass * specificHeat * temperatureChange,
      zeroExpected: false,
    );
  }
}

abstract final class ThermalEfficiency {
  static CalculationOutcome<double> calculate({
    required double work,
    required double heat,
  }) {
    final issues = physicalInputIssues(
      {'work': work, 'heat': heat},
      positive: {'heat'},
      nonNegative: {'work'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (work > heat) {
      return calculationFailure(
        CalculationError.outOfDomain,
        'A heat engine cannot output more work than its heat input.',
        fieldId: 'work',
      );
    }
    return checkedResult(work / heat, zeroExpected: work == 0);
  }
}

abstract final class AbsoluteTemperature {
  static CalculationOutcome<double> kelvin(double temperature) {
    final issues = physicalInputIssues(
      {'temperature': temperature},
      nonNegative: {'temperature'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return CalculationSuccess(temperature);
  }
}

abstract final class LinearExpansion {
  static CalculationOutcome<double> calculate({
    required double coefficient,
    required double length,
    required double temperatureChange,
  }) {
    final issues = physicalInputIssues(
      {
        'coefficient': coefficient,
        'length': length,
        'temperatureChange': temperatureChange,
      },
      positive: {'length'},
    );
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (coefficient == 0 || temperatureChange == 0) {
      return const CalculationSuccess(0);
    }
    final strain = coefficient * temperatureChange;
    if (!strain.isFinite) return checkedResult(strain, zeroExpected: false);
    if (strain <= -1) {
      return calculationFailure(
        CalculationError.outOfDomain,
        'The linear approximation would produce a nonpositive final length.',
        fieldId: 'temperatureChange',
      );
    }
    return checkedResult(strain * length, zeroExpected: false);
  }
}
