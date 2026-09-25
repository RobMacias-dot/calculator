import '../support/phase3_catalog.dart';

import 'package:engineering_toolkit/features/preferences/local_preferences_repository.dart';
import 'package:engineering_toolkit/features/preferences/preferences_controller.dart';
import 'package:engineering_toolkit/features/preferences/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'local adapter round trips only theme and IDs under its own key',
    () async {
      final storage = _MemoryStorage();
      final repository = LocalPreferencesRepository(storage: storage);
      await repository.write(
        Preferences(
          themeMode: ThemeMode.dark,
          favoriteCalculatorIds: ['ohms-law'],
          recentCalculatorIds: ['ipv4-subnet'],
        ),
      );
      expect(storage.key, 'engineering_toolkit.preferences.v1');
      expect(
        storage.raw,
        '{"theme":"dark","favorites":["ohms-law"],"recents":["ipv4-subnet"]}',
      );
      final restored = await LocalPreferencesRepository(storage: storage)
          .read();
      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.favoriteCalculatorIds, ['ohms-law']);
      expect(restored.recentCalculatorIds, ['ipv4-subnet']);
    },
  );

  test('absent, malformed and incompatible preferences start safely', () async {
    for (final raw in [
      null,
      '{broken',
      '42',
      '{"theme":"future","favorites":42,"recents":false}',
    ]) {
      final state = await PreferencesController.restore(
        LocalPreferencesRepository(storage: _MemoryStorage()..raw = raw),
        createPhase3Catalog(),
      );
      expect(state.themeMode.value, ThemeMode.system, reason: raw);
      expect(state.favorites, isEmpty);
      expect(state.recents, isEmpty);
      state.dispose();
    }
  });

  test(
    'valid fields survive unrelated corrupt fields and unknown IDs',
    () async {
      final state = await PreferencesController.restore(
        LocalPreferencesRepository(
          storage: _MemoryStorage()..raw = '{"theme":"dark","favorites":[42,"ohms-law","obsolete",null],"recents":"bad"}',
        ),
        createPhase3Catalog(),
      );
      expect(state.themeMode.value, ThemeMode.dark);
      expect(state.favorites.single.id, 'ohms-law');
      expect(state.recents, isEmpty);
      state.dispose();
    },
  );
}

class _MemoryStorage extends Fake implements SharedPreferencesAsync {
  final _values = <String, String?>{};
  String? get raw => _values['raw'];
  set raw(String? value) => _values['raw'] = value;
  String? get key => _values['key'];
  @override
  Future<String?> getString(String key) async => raw;
  @override
  Future<void> setString(String key, String value) async {
    _values['key'] = key;
    raw = value;
  }
}
