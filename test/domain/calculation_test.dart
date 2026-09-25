import 'package:flutter_test/flutter_test.dart';

import 'all_calculation_cases.dart';

void main() {
  for (final entry in allCalculationCases().entries) {
    test(entry.key, entry.value);
  }
}
