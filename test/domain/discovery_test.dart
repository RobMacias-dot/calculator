import 'package:engineering_toolkit/features/calculators/domain/calculator_category.dart';
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final registry = createInitialCatalog();

  test(
    'all 30 tools remain discoverable by title, significant word and field',
    () {
      expect(registry.all, hasLength(30));
      final categoryIds = <String>[];
      for (final category in CalculatorCategory.values) {
        final entries = registry.inCategory(category);
        expect(entries, isNotEmpty);
        categoryIds.addAll(entries.map((d) => d.id));
        expect(registry.search(category.label), containsAll(entries));
      }
      expect(categoryIds.toSet(), hasLength(30));
      expect(categoryIds, hasLength(30));
      for (final d in registry.all) {
        expect(registry.search(d.name).first, same(d));
        final word = d.name
            .split(RegExp(r'\s+'))
            .firstWhere((w) => w.length > 3);
        expect(registry.search(word), contains(d));
        expect(registry.search(d.description), contains(d));
      }
    },
  );

  test(
    'representative engineering intent finds the authoritative parent once',
    () {
      const matrix = {
        'current': 'ohms-law',
        'resistor divider': 'voltage-divider',
        'force': 'newtons-second-law',
        'F=ma': 'newtons-second-law',
        'F = ma': 'newtons-second-law',
        'vector length': 'vector-magnitude',
        'gas pressure': 'ideal-gas-law',
        'subnet': 'ipv4-subnet',
        'CIDR': 'ipv4-subnet',
        'pipe velocity': 'pipe-flow',
        'roots': 'quadratic-equation',
        'thermal expansion': 'linear-expansion',
        'missing leg': 'pythagorean',
      };
      for (final entry in matrix.entries) {
        final ids = registry.search(entry.key).map((d) => d.id).toList();
        expect(
          ids.where((id) => id == entry.value),
          hasLength(1),
          reason: entry.key,
        );
        expect(ids.toSet().length, ids.length, reason: entry.key);
      }
    },
  );

  test(
    'normalization keeps engineering tokens and unusual input predictable',
    () {
      for (final query in ['  ÓHMS   LAW ', 'ohm\n law', 'Ohm’s Law']) {
        expect(registry.search(query).single.id, 'ohms-law');
      }
      expect(registry.search('IPv4/CIDR').single.id, 'ipv4-subnet');
      expect(registry.search('DC').single.id, 'dc-power');
      expect(registry.search('2D').single.id, 'vector-magnitude');
      expect(registry.search('3D').single.id, 'vector-magnitude');
      expect(registry.search(' \t\n'), same(registry.all));
      expect(registry.search(''), same(registry.all));
      for (final query in ['unmatched concept', '東京', '!!!']) {
        expect(registry.search(query), isEmpty);
      }
    },
  );

  test(
    'existing mode labels find parents without mode routes or duplicates',
    () {
      for (final definition in registry.all) {
        for (final mode in definition.modes) {
          expect(
            registry.search(mode.label).where((d) => d.id == definition.id),
            hasLength(1),
            reason: '${definition.id}: ${mode.label}',
          );
        }
      }
      expect(registry.search('CIDR to mask').single.id, 'subnet-mask');
      expect(
        registry.search('absolute temperature').map((d) => d.id),
        contains('temperature-converter'),
      );
      expect(
        registry.search('total resistance').map((d) => d.id),
        containsAll(['series-resistance', 'parallel-resistance']),
      );
    },
  );

  test('title relevance precedes secondary matches with stable ties', () {
    expect(registry.search('temperature').first.id, 'temperature-converter');
    expect(registry.search('flow').map((d) => d.id), [
      'volumetric-flow',
      'pipe-flow',
      'reynolds-number',
    ]);
    expect(registry.search('voltage divider').first.id, 'voltage-divider');
    final original = registry.search('current').map((d) => d.id).toList();
    expect(registry.search('CURRENT').map((d) => d.id), original);
    expect(() => registry.search('current').clear(), throwsUnsupportedError);
  });
}
