import 'calculator_category.dart';
import 'calculator_definition.dart';

/// In-memory source of truth. No I/O or Flutter dependency.
class CalculatorRegistry {
  CalculatorRegistry(Iterable<CalculatorDefinition> definitions) {
    final entries = <String, CalculatorDefinition>{};
    for (final definition in definitions) {
      if (entries.containsKey(definition.id)) {
        throw ArgumentError('Duplicate calculator id: ${definition.id}');
      }
      entries[definition.id] = definition;
    }
    _byId = Map.unmodifiable(entries);
    all = List.unmodifiable(entries.values);
  }

  late final Map<String, CalculatorDefinition> _byId;
  late final List<CalculatorDefinition> all;

  CalculatorDefinition? byId(String id) => _byId[id];

  List<CalculatorDefinition> inCategory(CalculatorCategory category) =>
      List.unmodifiable(all.where((item) => item.category == category));

  List<CalculatorDefinition> search(String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return all;
    final terms = normalized.split(' ');
    // Stable catalog order within three simple relevance groups.
    final exact = <CalculatorDefinition>[];
    final titles = <CalculatorDefinition>[];
    final secondary = <CalculatorDefinition>[];
    for (final item in all) {
      final title = _normalize(item.name);
      final text = _normalize(
        '${item.name} ${item.description} ${item.category.label} '
        '${item.keywords.join(' ')} ${item.modes.map((mode) => mode.label).join(' ')}',
      );
      if (!_matches(text, terms)) continue;
      if (title == normalized) {
        exact.add(item);
      } else if (_matches(title, terms)) {
        titles.add(item);
      } else {
        secondary.add(item);
      }
    }
    return List.unmodifiable([...exact, ...titles, ...secondary]);
  }

  static bool _matches(String text, List<String> terms) => terms.every(
    // Short technical tokens (DC, IP, 2D) must not match inside unrelated words.
    (term) =>
        term.length <= 2 ? text.split(' ').contains(term) : text.contains(term),
  );

  static String _normalize(String value) {
    var text = value.toLowerCase().replaceAll(RegExp(r'[\u0300-\u036f]'), '');
    const groups = {
      'a': 'àáâãäå',
      'e': 'èéêë',
      'i': 'ìíîï',
      'o': 'òóôõö',
      'u': 'ùúûü',
      'n': 'ñ',
      'c': 'ç',
    };
    for (final entry in groups.entries) {
      text = text.replaceAll(RegExp('[${entry.value}]'), entry.key);
    }
    return text
        .replaceAll(RegExp("['’]"), '')
        .replaceAll(RegExp(r'[/↔—–(),=]'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
