import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../calculators/domain/calculator_definition.dart';
import '../calculators/domain/calculator_registry.dart';
import 'preferences_repository.dart';

/// Small session state. Form values and catalog/search state stay in their VMs.
class PreferencesController extends ChangeNotifier {
  PreferencesController._(this._repository, this._registry, Preferences initial)
    : _theme = ValueNotifier(initial.themeMode) {
    _favorites = _validIds(initial.favoriteCalculatorIds).toSet();
    _recents = _validIds(initial.recentCalculatorIds).take(5).toList();
  }

  static Future<PreferencesController> restore(
    PreferencesRepository repository,
    CalculatorRegistry registry,
  ) async {
    Preferences initial;
    var failed = false;
    try {
      initial = await repository.read().timeout(const Duration(seconds: 2));
    } catch (_) {
      initial = Preferences();
      failed = true;
    }
    return PreferencesController._(repository, registry, initial)
      .._storageFailed = failed;
  }

  final PreferencesRepository _repository;
  final CalculatorRegistry _registry;
  final ValueNotifier<ThemeMode> _theme;
  late Set<String> _favorites;
  late List<String> _recents;
  Future<void> _pending = Future.value();
  bool _storageFailed = false;
  bool _disposed = false;

  ValueListenable<ThemeMode> get themeMode => _theme;
  bool get storageFailed => _storageFailed;
  Future<void> get pendingWrites => _pending;
  bool isFavorite(String id) => _favorites.contains(id);
  List<CalculatorDefinition> get favorites => _resolve(_favorites);
  List<CalculatorDefinition> get recents => _resolve(_recents);

  Iterable<String> _validIds(Iterable<String> ids) =>
      ids.where((id) => _registry.byId(id) != null).toSet();
  List<CalculatorDefinition> _resolve(Iterable<String> ids) =>
      List.unmodifiable(
        ids.map(_registry.byId).whereType<CalculatorDefinition>(),
      );

  void setThemeMode(ThemeMode mode) {
    if (_theme.value == mode) return;
    _theme.value = mode;
    _save();
  }

  void setFavorite(String id, bool selected) {
    if (_registry.byId(id) == null) return;
    final changed = selected ? _favorites.add(id) : _favorites.remove(id);
    if (!changed) return;
    notifyListeners();
    _save();
  }

  void recordOpened(String id) {
    if (_registry.byId(id) == null || _recents.firstOrNull == id) return;
    _recents = [id, ..._recents.where((item) => item != id)].take(5).toList();
    notifyListeners();
    _save();
  }

  void _save() {
    final snapshot = Preferences(
      themeMode: _theme.value,
      favoriteCalculatorIds: _favorites,
      recentCalculatorIds: _recents,
    );
    // Serial snapshots prevent rapid changes from overwriting newer choices.
    // A failed write must not poison the queue or revert usable session state.
    _pending = _pending.then((_) async {
      var failed = false;
      try {
        await _repository.write(snapshot);
      } catch (_) {
        failed = true;
      }
      if (!_disposed && _storageFailed != failed) {
        _storageFailed = failed;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _theme.dispose();
    super.dispose();
  }
}
