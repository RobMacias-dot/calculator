import 'dart:async';

import 'package:engineering_toolkit/features/calculators/domain/calculator_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculator_category.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculator_registry.dart';

import '../support/phase3_catalog.dart';

import 'package:engineering_toolkit/features/preferences/preferences_controller.dart';
import 'package:engineering_toolkit/features/preferences/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_preferences_repository.dart';

void main() {
  final registry = createPhase3Catalog();
  Future<PreferencesController> restore(
    PreferencesRepository repository,
  ) async {
    final controller = await PreferencesController.restore(
      repository,
      registry,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('safe defaults and immutable ID snapshots', () async {
    final state = await restore(MemoryPreferencesRepository());
    expect(state.themeMode.value, ThemeMode.system);
    expect(state.favorites, isEmpty);
    expect(state.recents, isEmpty);
    final ids = ['ohms-law'];
    final snapshot = Preferences(favoriteCalculatorIds: ids);
    ids.clear();
    expect(snapshot.favoriteCalculatorIds, ['ohms-law']);
    expect(
      () => snapshot.favoriteCalculatorIds.clear(),
      throwsUnsupportedError,
    );
  });

  test('favorite add is idempotent, resolves registry entries and persists removal', () async {
    final repository = MemoryPreferencesRepository();
    final state = await restore(repository);
    state.setFavorite('ohms-law', true);
    state.setFavorite('ohms-law', true);
    state.setFavorite('missing', true);
    expect(state.favorites.single, same(registry.byId('ohms-law')));
    await state.pendingWrites;
    expect(repository.writes, 1);
    expect(repository.value.favoriteCalculatorIds, ['ohms-law']);
    final restarted = await restore(repository);
    expect(restarted.isFavorite('ohms-law'), isTrue);
    restarted.setFavorite('ohms-law', false);
    restarted.setFavorite('ohms-law', false);
    await restarted.pendingWrites;
    expect((await restore(repository)).favorites, isEmpty);
    expect(repository.writes, 2);
  });

  test('restoration drops obsolete IDs and duplicates', () async {
    final state = await restore(
      MemoryPreferencesRepository(
        Preferences(
          favoriteCalculatorIds: ['missing', 'ohms-law', 'ohms-law'],
          recentCalculatorIds: [
            'missing',
            'ipv4-subnet',
            'ipv4-subnet',
            'ohms-law',
          ],
        ),
      ),
    );
    expect(state.favorites.map((item) => item.id), ['ohms-law']);
    expect(state.recents.map((item) => item.id), ['ipv4-subnet', 'ohms-law']);
    state.recordOpened('missing');
    expect(state.recents, hasLength(2));
  });

  test('all semantic theme choices restore without changing tools', () async {
    final repository = MemoryPreferencesRepository();
    final state = await restore(repository);
    state.setFavorite('ohms-law', true);
    state.recordOpened('ipv4-subnet');
    for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.system]) {
      state.setThemeMode(mode);
      expect(state.themeMode.value, mode);
      await state.pendingWrites;
      final restarted = await restore(repository);
      expect(restarted.themeMode.value, mode);
      expect(restarted.favorites.single.id, 'ohms-law');
      expect(restarted.recents.single.id, 'ipv4-subnet');
    }
  });

  test('recents promote duplicates, cap at five and restore order', () async {
    final catalog = CalculatorRegistry([
      ...registry.all,
      CalculatorDefinition(
        id: 'sixth-tool',
        name: 'Sixth',
        description: '',
        category: CalculatorCategory.mathematics,
        formula: '',
        explanation: '',
        inputs: [],
      ),
    ]);
    final repository = MemoryPreferencesRepository();
    final state = await PreferencesController.restore(repository, catalog);
    addTearDown(state.dispose);
    for (final calculator in catalog.all) {
      state.recordOpened(calculator.id);
    }
    expect(
      state.recents.map((item) => item.id),
      catalog.all.reversed.take(5).map((item) => item.id),
    );
    state.recordOpened('reynolds-number');
    state.recordOpened('reynolds-number');
    expect(state.recents.first.id, 'reynolds-number');
    expect(state.recents.map((item) => item.id).toSet(), hasLength(5));
    await state.pendingWrites;
    final restarted = await PreferencesController.restore(repository, catalog);
    addTearDown(restarted.dispose);
    expect(
      restarted.recents.map((item) => item.id),
      state.recents.map((item) => item.id),
    );
    expect(repository.writes, 7);
  });

  test(
    'read and write failures preserve session state and later writes recover',
    () async {
      final repository = MemoryPreferencesRepository()..failRead = true;
      final state = await restore(repository);
      expect(state.themeMode.value, ThemeMode.system);
      expect(state.storageFailed, isTrue);
      repository.failWrite = true;
      state.setFavorite('ohms-law', true);
      state.setThemeMode(ThemeMode.dark);
      state.recordOpened('ipv4-subnet');
      await state.pendingWrites;
      expect(state.storageFailed, isTrue);
      expect(state.isFavorite('ohms-law'), isTrue);
      expect(state.themeMode.value, ThemeMode.dark);
      repository.failWrite = false;
      state.setFavorite('reynolds-number', true);
      await state.pendingWrites;
      expect(state.storageFailed, isFalse);
      expect(repository.value.favoriteCalculatorIds, [
        'ohms-law',
        'reynolds-number',
      ]);
      expect(repository.value.recentCalculatorIds, ['ipv4-subnet']);
      expect(repository.value.themeMode, ThemeMode.dark);
    },
  );

  test('slow writes are serialized and cannot restore stale state', () async {
    final repository = _DelayedRepository();
    final state = await restore(repository);
    state.setFavorite('ohms-law', true);
    state.setFavorite('ohms-law', false);
    state.setThemeMode(ThemeMode.dark);
    await Future<void>.delayed(Duration.zero);
    expect(repository.started, 1);
    repository.firstWrite.complete();
    await state.pendingWrites;
    expect(repository.started, 3);
    expect(repository.value.favoriteCalculatorIds, isEmpty);
    expect(repository.value.themeMode, ThemeMode.dark);
  });

  test('favorites and recents do not notify global theme listener', () async {
    final state = await restore(MemoryPreferencesRepository());
    var themeUpdates = 0;
    state.themeMode.addListener(() => themeUpdates++);
    state.setFavorite('ohms-law', true);
    state.recordOpened('ohms-law');
    expect(themeUpdates, 0);
    state.setThemeMode(ThemeMode.dark);
    state.setThemeMode(ThemeMode.dark);
    expect(themeUpdates, 1);
    await state.pendingWrites;
  });
}

class _DelayedRepository extends MemoryPreferencesRepository {
  final firstWrite = Completer<void>();
  int started = 0;
  @override
  Future<void> write(Preferences preferences) async {
    if (++started == 1) await firstWrite.future;
    await super.write(preferences);
  }
}
