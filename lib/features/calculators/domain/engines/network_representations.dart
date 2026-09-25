import '../calculation_outcome.dart';
import 'ipv4_address.dart';

abstract final class Ipv4Representations {
  static String binary(Ipv4Address address) => [
    for (final shift in [24, 16, 8, 0])
      ((address.bits >> shift) & BigInt.from(255))
          .toRadixString(2)
          .padLeft(8, '0'),
  ].join('.');

  static CalculationOutcome<String> decimal(String binary) {
    if (!RegExp(r'^[01]{8}\.[01]{8}\.[01]{8}\.[01]{8}$')
        .hasMatch(binary.trim())) {
      return calculationFailure(
        CalculationError.invalidInput,
        'Enter four groups of exactly eight binary digits, separated by dots.',
        fieldId: 'binary',
      );
    }
    final bits = BigInt.parse(binary.trim().replaceAll('.', ''), radix: 2);
    return CalculationSuccess(Ipv4Address.formatBits(bits));
  }

  static CalculationOutcome<int> prefix(Ipv4Address mask) {
    final wildcard = Ipv4Address.maxBits ^ mask.bits;
    if ((wildcard & (wildcard + BigInt.one)) != BigInt.zero) {
      return calculationFailure(
        CalculationError.outOfDomain,
        'A subnet mask must have contiguous ones followed by zeros.',
        fieldId: 'address',
      );
    }
    return CalculationSuccess(32 - wildcard.bitLength);
  }

  static CalculationOutcome<String> mask(int prefix) {
    if (prefix < 0 || prefix > 32) {
      return calculationFailure(
        CalculationError.outOfDomain,
        'The prefix must be between 0 and 32.',
        fieldId: 'prefix',
      );
    }
    final hostBits = (BigInt.one << (32 - prefix)) - BigInt.one;
    return CalculationSuccess(
      Ipv4Address.formatBits(Ipv4Address.maxBits ^ hostBits),
    );
  }

  static CalculationOutcome<String> wildcard(Ipv4Address mask) {
    final checked = prefix(mask);
    if (checked case CalculationFailure<int>(:final issues)) {
      return CalculationFailure(issues);
    }
    return CalculationSuccess(
      Ipv4Address.formatBits(Ipv4Address.maxBits ^ mask.bits),
    );
  }
}
