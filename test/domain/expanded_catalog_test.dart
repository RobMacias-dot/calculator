import 'package:engineering_toolkit/features/calculators/domain/calculator_category.dart';
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/home/presentation/home_view_model.dart';
import 'package:engineering_toolkit/features/preferences/preferences_controller.dart';
import 'package:engineering_toolkit/features/preferences/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_preferences_repository.dart';

void main() {
  test(
    'production registry contains 30 executable tools in all six fields',
    () {
      final registry = createInitialCatalog();
      expect(registry.all, hasLength(30));
      expect(registry.all.map((tool) => tool.id).toSet(), hasLength(30));
      expect(registry.all.every((tool) => tool.isAvailable), isTrue);
      expect(
        CalculatorCategory.values.map(
          (category) => registry.inCategory(category).length,
        ),
        [6, 6, 5, 5, 4, 4],
      );
      for (final id in [
        'ohms-law',
        'newtons-second-law',
        'reynolds-number',
        'ideal-gas-law',
        'ipv4-subnet',
      ]) {
        expect(registry.byId(id), isNotNull);
      }
    },
  );
  test('expanded search and filters derive results from the same registry', () {
    final registry = createInitialCatalog();
    expect(
      registry.search('resistance').map((tool) => tool.id),
      containsAll(['ohms-law', 'series-resistance', 'parallel-resistance']),
    );
    expect(
      registry.search('  QUADRÁTIC   roots ').single.id,
      'quadratic-equation',
    );
    expect(registry.search('networking'), hasLength(4));
    expect(registry.search('heat'), isNotEmpty);
    final vm = HomeViewModel(registry);
    addTearDown(vm.dispose);
    vm.selectSection(HomeSection.tools);
    vm.setCategory(CalculatorCategory.mathematics);
    expect(vm.results, hasLength(4));
    vm.setQuery('vector');
    expect(vm.results.single, same(registry.byId('vector-magnitude')));
  });
  test(
    'new tool IDs restore favorites and only the five newest recent tools',
    () async {
      final registry = createInitialCatalog();
      final repository = MemoryPreferencesRepository(
        Preferences(
          favoriteCalculatorIds: [
            'quadratic-equation',
            'series-resistance',
            'obsolete',
          ],
          recentCalculatorIds: registry.all.reversed.map((tool) => tool.id),
        ),
      );
      final state = await PreferencesController.restore(repository, registry);
      addTearDown(state.dispose);
      expect(state.favorites.map((tool) => tool.id), [
        'quadratic-equation',
        'series-resistance',
      ]);
      expect(state.recents, hasLength(5));
      for (final tool in registry.all) {
        state.recordOpened(tool.id);
      }
      await state.pendingWrites;
      expect(
        repository.value.recentCalculatorIds,
        registry.all.reversed.take(5).map((tool) => tool.id),
      );
      expect(state.recents.first, same(registry.all.last));
    },
  );
}
