import 'package:engineering_toolkit/features/calculators/domain/calculator_category.dart';

import '../support/phase3_catalog.dart';

import 'package:engineering_toolkit/features/home/presentation/home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'search normalizes case, internal whitespace, accents and punctuation',
    () {
      final registry = createPhase3Catalog();
      for (final query in [
        "  ÓHM'S   LAW ",
        'ohm\n resistance',
        'ÉLÉCTRICAL',
        'círçuit',
        'o\u0301hm',
      ]) {
        expect(registry.search(query).single.id, 'ohms-law', reason: query);
      }
      expect(registry.search('HOST RANGES').single.id, 'ipv4-subnet');
      expect(registry.search(' \t\n'), hasLength(5));
      expect(registry.search('not in the catalog'), isEmpty);
    },
  );
  test(
    'Tools combines category and query while Home search spans the catalog',
    () {
      final vm = HomeViewModel(createPhase3Catalog());
      addTearDown(vm.dispose);
      vm.selectSection(HomeSection.tools);
      vm.setCategory(CalculatorCategory.electrical);
      expect(vm.results.single.id, 'ohms-law');
      vm.setQuery('gas');
      expect(vm.results, isEmpty);
      vm.selectSection(HomeSection.home);
      expect(vm.results.single.id, 'ideal-gas-law');
      vm.selectSection(HomeSection.tools);
      vm.setCategory(null);
      expect(vm.results.single.id, 'ideal-gas-law');
    },
  );
}
