import 'package:flutter/foundation.dart';

import '../domain/calculation_outcome.dart';
import '../domain/calculation_result.dart';
import '../domain/calculator_definition.dart';
import '../domain/calculator_mode.dart';
import '../domain/resistor_mode.dart';

enum CalculationStatus { idle, success, invalid }

/// Form state coordinator. Operations are injected; no calculator-specific branches.
class CalculatorViewModel extends ChangeNotifier {
  CalculatorViewModel(this.definition) : _mode = definition.modes.first {
    _initializeFields();
  }

  final CalculatorDefinition definition;
  CalculatorMode _mode;
  final _values = <String, String>{};
  final _units = <String, EngineeringUnit>{};
  List<CalculationIssue> _issues = const [];
  CalculationResult? _result;
  CalculationStatus _status = CalculationStatus.idle;
  int _revision = 0;
  late List<CalculatorInput> _inputs;

  CalculatorMode get mode => _mode;
  List<CalculatorInput> get inputs => List.unmodifiable(_inputs);
  bool get hasResistorList => _mode is ResistorMode;
  CalculationStatus get status => _status;
  CalculationResult? get result => _result;
  List<CalculationIssue> get issues => _issues;
  int get revision => _revision;
  String valueFor(String id) => _values[id] ?? '';
  EngineeringUnit? unitFor(String id) => _units[id];
  String? errorFor(String id) {
    for (final issue in _issues) {
      if (issue.fieldId == id) return issue.message;
    }
    return null;
  }

  List<CalculationIssue> get generalIssues =>
      _issues.where((issue) => issue.fieldId == null).toList(growable: false);

  void setValue(String id, String value) {
    if (!_values.containsKey(id) || _values[id] == value) return;
    _values[id] = value;
    _invalidate();
    notifyListeners();
  }

  void setUnit(String id, EngineeringUnit unit) {
    final input = _inputs.where((input) => input.id == id).firstOrNull;
    if (input == null || !input.units.contains(unit) || _units[id] == unit) {
      return;
    }
    _units[id] = unit;
    _invalidate();
    notifyListeners();
  }

  void selectMode(CalculatorMode mode) {
    if (!definition.modes.contains(mode) || identical(mode, _mode)) return;
    _mode = mode;
    _initializeFields();
    notifyListeners();
  }

  /// External controls edit the same form, then run its normal calculation.
  /// Bump the revision so TextFormField.initialValue also refreshes on return.
  void updateAndCalculate(String id, String value) {
    if (!_values.containsKey(id)) return;
    _values[id] = value;
    _revision++;
    calculate();
  }

  void calculate() {
    final outcome = _mode.calculate(
      Map.unmodifiable(_values),
      Map.unmodifiable(_units),
    );
    switch (outcome) {
      case CalculationSuccess<CalculationResult>(:final value):
        _result = value;
        _issues = const [];
        _status = CalculationStatus.success;
      case CalculationFailure<CalculationResult>(:final issues):
        _result = null;
        _issues = issues;
        _status = CalculationStatus.invalid;
    }
    notifyListeners();
  }

  void reset() {
    _mode = definition.modes.first;
    _initializeFields();
    notifyListeners();
  }

  void addResistor() {
    if (!hasResistorList) return;
    final input = ResistorMode.input(_inputs.length + 1);
    _inputs.add(input);
    _values[input.id] = '';
    _units[input.id] = input.units.first;
    _invalidate();
    notifyListeners();
  }

  void removeResistor() {
    if (!hasResistorList || _inputs.length <= 2) return;
    final input = _inputs.removeLast();
    _values.remove(input.id);
    _units.remove(input.id);
    _invalidate();
    notifyListeners();
  }

  void _initializeFields() {
    _values.clear();
    _units.clear();
    _inputs = _mode.inputs.toList();
    for (final input in _inputs) {
      _values[input.id] = '';
      if (input.units.isNotEmpty) _units[input.id] = input.units.first;
    }
    _revision++;
    _invalidate();
  }

  void _invalidate() {
    _result = null;
    _issues = const [];
    _status = CalculationStatus.idle;
  }
}
