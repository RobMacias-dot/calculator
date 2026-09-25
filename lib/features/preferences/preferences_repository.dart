import 'package:flutter/material.dart' show ThemeMode;

/// Only semantic preferences and stable catalog IDs cross the storage boundary.
class Preferences {
  Preferences({
    this.themeMode = ThemeMode.system,
    Iterable<String> favoriteCalculatorIds = const [],
    Iterable<String> recentCalculatorIds = const [],
  }) : favoriteCalculatorIds = List.unmodifiable(favoriteCalculatorIds),
       recentCalculatorIds = List.unmodifiable(recentCalculatorIds);

  final ThemeMode themeMode;
  final List<String> favoriteCalculatorIds;
  final List<String> recentCalculatorIds;
}

abstract interface class PreferencesRepository {
  Future<Preferences> read();
  Future<void> write(Preferences preferences);
}
