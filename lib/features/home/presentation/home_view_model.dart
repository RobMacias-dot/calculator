import 'package:flutter/foundation.dart';

import '../../calculators/domain/calculator_definition.dart';
import '../../calculators/domain/calculator_registry.dart';
import '../../calculators/domain/calculator_category.dart';

enum HomeSection { home, favorites, tools }

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._registry);

  final CalculatorRegistry _registry;
  String _query = '';
  HomeSection _section = HomeSection.home;
  CalculatorCategory? _category;

  String get query => _query;
  HomeSection get section => _section;
  CalculatorCategory? get category => _category;
  List<CalculatorDefinition> get results => List.unmodifiable(
    _registry
        .search(_query)
        .where(
          (item) =>
              _section != HomeSection.tools ||
              _category == null ||
              item.category == _category,
        ),
  );

  void setCategory(CalculatorCategory? category) {
    if (_category == category) return;
    _category = category;
    notifyListeners();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void selectSection(HomeSection value) {
    if (_section == value) return;
    _section = value;
    notifyListeners();
  }

  void resetSearch() => setQuery('');
}
