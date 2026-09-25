import 'dart:io';

import '../test/domain/all_calculation_cases.dart';

void main() {
  final cases = allCalculationCases();
  var failures = 0;
  for (final entry in cases.entries) {
    try {
      entry.value();
    } catch (error, stack) {
      failures++;
      stderr.writeln('FAIL ${entry.key}: $error\n$stack');
    }
  }
  stdout.writeln(
    '${cases.length - failures}/${cases.length} pure Dart domain cases passed.',
  );
  if (failures != 0) exitCode = 1;
}
