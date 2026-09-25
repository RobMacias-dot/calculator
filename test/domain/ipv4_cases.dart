import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/ipv4_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/ipv4_address.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/ipv4_subnet.dart';

import 'checks.dart';

Ipv4SubnetResult subnet(String address, int prefix) => successValue(
  Ipv4Subnet.calculate(
    address: successValue(Ipv4Address.parse(address)),
    prefix: prefix,
  ),
);

Map<String, void Function()> ipv4Cases() => {
  'IPv4 192.168.1.10/24 known subnet': () {
    final result = subnet('192.168.1.10', 24);
    checkEqual(Ipv4Address.formatBits(result.network), '192.168.1.0');
    checkEqual(Ipv4Address.formatBits(result.mask), '255.255.255.0');
    checkEqual(
      Ipv4Address.formatBits(result.broadcastAddress!),
      '192.168.1.255',
    );
    checkEqual(result.totalAddresses, BigInt.from(256));
    checkEqual(result.usableHosts, BigInt.from(254));
    checkEqual(Ipv4Address.formatBits(result.firstUsable), '192.168.1.1');
    checkEqual(Ipv4Address.formatBits(result.lastUsable), '192.168.1.254');
  },
  'IPv4 10.0.0.7/8 known subnet': () {
    final result = subnet('10.0.0.7', 8);
    checkEqual(Ipv4Address.formatBits(result.network), '10.0.0.0');
    checkEqual(
      Ipv4Address.formatBits(result.broadcastAddress!),
      '10.255.255.255',
    );
    checkEqual(result.totalAddresses.toString(), '16777216');
  },
  'IPv4 /0 uses 4294967296 addresses without 32-bit truncation': () {
    final result = subnet('255.255.255.255', 0);
    checkEqual(result.network, BigInt.zero);
    checkEqual(result.mask, BigInt.zero);
    checkEqual(result.totalAddresses.toString(), '4294967296');
    checkEqual(result.usableHosts.toString(), '4294967294');
    checkEqual(
      Ipv4Address.formatBits(result.broadcastAddress!),
      '255.255.255.255',
    );
  },
  'IPv4 /31 uses both endpoints and has no directed broadcast': () {
    final result = subnet('192.0.2.5', 31);
    checkEqual(Ipv4Address.formatBits(result.network), '192.0.2.4');
    checkEqual(Ipv4Address.formatBits(result.lastAddress), '192.0.2.5');
    checkEqual(result.totalAddresses, BigInt.two);
    checkEqual(result.usableHosts, BigInt.two);
    checkEqual(result.broadcastAddress, null);
    checkEqual(result.firstUsable, result.network);
    checkEqual(result.lastUsable, result.lastAddress);
  },
  'IPv4 /32 is one host with no directed broadcast': () {
    final result = subnet('255.255.255.255', 32);
    checkEqual(result.network, Ipv4Address.maxBits);
    checkEqual(result.mask, Ipv4Address.maxBits);
    checkEqual(result.totalAddresses, BigInt.one);
    checkEqual(result.usableHosts, BigInt.one);
    checkEqual(result.firstUsable, result.lastUsable);
    checkEqual(result.broadcastAddress, null);
  },
  'IPv4 /30 still uses the traditional convention': () {
    final result = subnet('192.0.2.5', 30);
    checkEqual(result.usableHosts, BigInt.two);
    checkEqual(Ipv4Address.formatBits(result.broadcastAddress!), '192.0.2.7');
  },
  for (final ip in ['0.0.0.0', '127.0.0.1', '128.0.0.0', '255.255.255.255'])
    'IPv4 canonical roundtrip $ip': () =>
        checkEqual(successValue(Ipv4Address.parse(' $ip ')).toString(), ip),
  for (final raw in [
    '',
    '1.2.3',
    '1.2.3.4.5',
    '256.0.0.1',
    '-1.0.0.1',
    '1.2.3.4/24',
    '1.2..4',
    '1.2.3.a',
    '01.2.3.4',
    '1.2.3.004',
    '1. 2.3.4',
    '+1.2.3.4',
    '1e1.0.0.1',
    '::1',
  ])
    'IPv4 rejects "$raw" cleanly': () => checkEqual(
      Ipv4Address.parse(raw) is CalculationFailure<Ipv4Address>,
      true,
    ),
  for (final prefix in [
    '',
    '-1',
    '33',
    '1.5',
    '/24',
    '024',
    'NaN',
    '4294967296',
  ])
    'IPv4 rejects prefix "$prefix"': () => checkEqual(
      Ipv4Address.parsePrefix(prefix) is CalculationFailure<int>,
      true,
    ),
  'IPv4 validates direct domain prefix bounds': () {
    final address = successValue(Ipv4Address.parse('1.2.3.4'));
    checkFailure(
      Ipv4Subnet.calculate(address: address, prefix: -1),
      CalculationError.outOfDomain,
    );
    checkFailure(
      Ipv4Subnet.calculate(address: address, prefix: 33),
      CalculationError.outOfDomain,
    );
  },
  'IPv4 all prefixes preserve address membership and contiguous masks': () {
    for (var prefix = 0; prefix <= 32; prefix++) {
      final result = subnet('203.0.113.7', prefix);
      checkEqual(
        result.address.bits >= result.network &&
            result.address.bits <= result.lastAddress,
        true,
      );
      checkEqual(
        result.lastAddress - result.network + BigInt.one,
        result.totalAddresses,
      );
      checkEqual(
        result.mask.toRadixString(2).padLeft(32, '0'),
        '${'1' * prefix}${'0' * (32 - prefix)}',
      );
    }
  },
  'IPv4 pipeline presents exact integer counts and convention': () {
    final mode = createIpv4Definition().modes.single;
    final zero = successValue(
      mode.calculate({'address': '1.2.3.4', 'prefix': '0'}, {}),
    );
    checkEqual(
      zero.details
          .firstWhere((detail) => detail.label == 'Total addresses')
          .value,
      '4294967296',
    );
    final pointToPoint = successValue(
      mode.calculate({'address': '192.0.2.5', 'prefix': '31'}, {}),
    );
    checkEqual(pointToPoint.explanation.contains('RFC 3021'), true);
    final host = successValue(
      mode.calculate({'address': '192.0.2.5', 'prefix': '32'}, {}),
    );
    checkEqual(host.explanation.contains('one host/address'), true);
  },
};
