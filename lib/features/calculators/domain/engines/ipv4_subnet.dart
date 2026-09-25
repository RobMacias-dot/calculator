import '../calculation_outcome.dart';
import 'ipv4_address.dart';

class Ipv4SubnetResult {
  const Ipv4SubnetResult({
    required this.address,
    required this.prefix,
    required this.mask,
    required this.network,
    required this.lastAddress,
    required this.totalAddresses,
    required this.usableHosts,
    required this.firstUsable,
    required this.lastUsable,
  });

  final Ipv4Address address;
  final int prefix;
  final BigInt mask;
  final BigInt network;
  final BigInt lastAddress;
  final BigInt totalAddresses;
  final BigInt usableHosts;
  final BigInt firstUsable;
  final BigInt lastUsable;

  /// /31 point-to-point and /32 host routes have no directed broadcast.
  BigInt? get broadcastAddress => prefix <= 30 ? lastAddress : null;
}

abstract final class Ipv4Subnet {
  /// BigInt avoids JavaScript's 32-bit bitwise truncation (notably 1 << 32).
  static CalculationOutcome<Ipv4SubnetResult> calculate({
    required Ipv4Address address,
    required int prefix,
  }) {
    if (prefix < 0 || prefix > 32) {
      return calculationFailure(
        CalculationError.outOfDomain,
        'The prefix must be between 0 and 32.',
        fieldId: Ipv4Input.prefix.name,
      );
    }
    final total = BigInt.one << (32 - prefix);
    final hostMask = total - BigInt.one;
    final mask = Ipv4Address.maxBits ^ hostMask;
    final network = address.bits & mask;
    final lastAddress = network | hostMask;
    final traditional = prefix <= 30;
    return CalculationSuccess(
      Ipv4SubnetResult(
        address: address,
        prefix: prefix,
        mask: mask,
        network: network,
        lastAddress: lastAddress,
        totalAddresses: total,
        usableHosts: traditional ? total - BigInt.two : total,
        firstUsable: traditional ? network + BigInt.one : network,
        lastUsable: traditional ? lastAddress - BigInt.one : lastAddress,
      ),
    );
  }
}
