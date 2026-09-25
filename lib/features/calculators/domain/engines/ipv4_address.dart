import '../calculation_outcome.dart';

enum Ipv4Input { address, prefix }

class Ipv4Address {
  const Ipv4Address._(this.bits);
  final BigInt bits;
  static final maxBits = (BigInt.one << 32) - BigInt.one;
  static final _octetPattern = RegExp(r'^(0|[1-9][0-9]{0,2})$');

  /// Canonical decimal only. Leading zeros are rejected to avoid octal ambiguity.
  static CalculationOutcome<Ipv4Address> parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return calculationFailure(
        CalculationError.missingInput,
        'Enter an IPv4 address.',
        fieldId: Ipv4Input.address.name,
      );
    }
    final octets = text.split('.');
    var bits = BigInt.zero;
    if (octets.length == 4) {
      for (final octet in octets) {
        if (!_octetPattern.hasMatch(octet)) return _invalidAddress();
        final value = int.parse(octet);
        if (value > 255) return _invalidAddress();
        bits = (bits << 8) | BigInt.from(value);
      }
      return CalculationSuccess(Ipv4Address._(bits));
    }
    return _invalidAddress();
  }

  static CalculationFailure<Ipv4Address>
  _invalidAddress() => calculationFailure(
    CalculationError.invalidInput,
    'Use four octets from 0 to 255, without leading zeros (e.g. 192.168.1.10).',
    fieldId: Ipv4Input.address.name,
  );

  static CalculationOutcome<int> parsePrefix(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return calculationFailure(
        CalculationError.missingInput,
        'Enter a CIDR prefix.',
        fieldId: Ipv4Input.prefix.name,
      );
    }
    if (!RegExp(r'^(0|[1-9][0-9]?)$').hasMatch(text)) {
      return calculationFailure(
        CalculationError.invalidInput,
        'Enter an integer prefix from 0 to 32, without the slash.',
        fieldId: Ipv4Input.prefix.name,
      );
    }
    final prefix = int.parse(text);
    if (prefix > 32) {
      return calculationFailure(
        CalculationError.outOfDomain,
        'The prefix must be between 0 and 32.',
        fieldId: Ipv4Input.prefix.name,
      );
    }
    return CalculationSuccess(prefix);
  }

  /// Used only with validated address/mask bits. Throws for programmer misuse.
  static String formatBits(BigInt bits) {
    if (bits < BigInt.zero || bits > maxBits) {
      throw ArgumentError.value(
        bits,
        'bits',
        'Expected an unsigned 32-bit value.',
      );
    }
    final octetMask = BigInt.from(255);
    return [
      for (final shift in [24, 16, 8, 0])
        ((bits >> shift) & octetMask).toString(),
    ].join('.');
  }

  @override
  String toString() => formatBits(bits);
}
