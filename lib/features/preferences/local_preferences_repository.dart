import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_repository.dart';

class LocalPreferencesRepository implements PreferencesRepository {
  LocalPreferencesRepository({SharedPreferencesAsync? storage})
    : _storage = storage ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _storage;
  static const _key = 'engineering_toolkit.preferences.v1';

  @override
  Future<Preferences> read() async {
    final raw = await _storage.getString(_key);
    if (raw == null) return Preferences();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return Preferences();
    List<String> ids(String key) {
      final value = decoded[key];
      return value is List ? value.whereType<String>().toList() : [];
    }

    return Preferences(
      themeMode:
          ThemeMode.values
              .where((mode) => mode.name == decoded['theme'])
              .firstOrNull ??
          ThemeMode.system,
      favoriteCalculatorIds: ids('favorites'),
      recentCalculatorIds: ids('recents'),
    );
  }

  @override
  Future<void> write(Preferences preferences) => _storage.setString(
    _key,
    jsonEncode({
      'theme': preferences.themeMode.name,
      'favorites': preferences.favoriteCalculatorIds,
      'recents': preferences.recentCalculatorIds,
    }),
  );
}
