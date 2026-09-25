import '../support/phase3_catalog.dart';

import 'package:engineering_toolkit/features/home/presentation/home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HomeViewModel viewModel;
  setUp(() => viewModel = HomeViewModel(createPhase3Catalog()));
  tearDown(() => viewModel.dispose());

  test('starts in Home with the full preview catalog', () {
    expect(viewModel.section, HomeSection.home);
    expect(viewModel.query, isEmpty);
    expect(viewModel.results, hasLength(5));
  });

  test('query updates results, empty state and reset', () {
    viewModel.setQuery('ohm');
    expect(viewModel.results.single.id, 'ohms-law');
    viewModel.setQuery('unknown');
    expect(viewModel.results, isEmpty);
    viewModel.resetSearch();
    expect(viewModel.query, isEmpty);
    expect(viewModel.results, hasLength(5));
  });

  test('only actual state changes notify listeners', () {
    var notifications = 0;
    viewModel.addListener(() => notifications++);
    viewModel.setQuery('ohm');
    viewModel.setQuery('ohm');
    viewModel.selectSection(HomeSection.tools);
    viewModel.selectSection(HomeSection.tools);
    expect(notifications, 2);
    expect(viewModel.section, HomeSection.tools);
  });

  test('switching sections preserves the search', () {
    viewModel.setQuery('gas');
    viewModel.selectSection(HomeSection.favorites);
    viewModel.selectSection(HomeSection.tools);
    expect(viewModel.results.single.id, 'ideal-gas-law');
  });
}
