import '../calculation_outcome.dart';
import '../calculation_result.dart';
import '../calculation_context.dart';
import '../calculator_category.dart';
import '../calculator_definition.dart';
import '../calculator_mode.dart';
import '../engines/ipv4_address.dart';
import '../engines/ipv4_subnet.dart';

CalculatorDefinition createIpv4Definition() {
  const formula = 'Network = IPv4 address AND subnet mask';
  final inputs = [
    CalculatorInput(
      id: Ipv4Input.address.name,
      label: 'IPv4 address',
      kind: CalculatorInputKind.ipv4,
    ),
    CalculatorInput(
      id: Ipv4Input.prefix.name,
      label: 'CIDR prefix',
      kind: CalculatorInputKind.integer,
      minimum: 0,
      maximum: 32,
    ),
  ];
  final mode = CalculatorMode(
    id: 'subnet',
    label: 'Subnet',
    formula: formula,
    inputs: inputs,
    inputHint: 'Enter four decimal octets and a prefix from 0 to 32. No leading zeros or slash.',
    calculate: (values, _) {
      final address = Ipv4Address.parse(values[Ipv4Input.address.name] ?? '');
      final prefix = Ipv4Address.parsePrefix(
        values[Ipv4Input.prefix.name] ?? '',
      );
      final issues = <CalculationIssue>[
        if (address case CalculationFailure<Ipv4Address>(:final issues))
          ...issues,
        if (prefix case CalculationFailure<int>(:final issues)) ...issues,
      ];
      if (issues.isNotEmpty) return CalculationFailure(issues);
      final subnet = Ipv4Subnet.calculate(
        address: (address as CalculationSuccess<Ipv4Address>).value,
        prefix: (prefix as CalculationSuccess<int>).value,
      );
      return switch (subnet) {
        CalculationFailure<Ipv4SubnetResult>(:final issues) =>
          CalculationFailure(issues),
        CalculationSuccess<Ipv4SubnetResult>(:final value) =>
          CalculationSuccess(_present(value, formula)),
      };
    },
  );
  return CalculatorDefinition(
    id: 'ipv4-subnet',
    supportsVisualLearning: true,
    name: 'IPv4 / CIDR Subnet',
    description: 'Understand network addresses, masks and host ranges.',
    category: CalculatorCategory.networking,
    formula: formula,
    explanation: 'A CIDR prefix identifies the network bits of a 32-bit IPv4 address. Host rules depend on the prefix.',
    inputs: inputs,
    modes: [mode],
    keywords: ['ip', 'cidr', 'subnet', 'mask', 'broadcast', 'hosts'],
  );
}

CalculationResult _present(Ipv4SubnetResult result, String formula) {
  final mask = Ipv4Address.formatBits(result.mask);
  final network = Ipv4Address.formatBits(result.network);
  final broadcast = result.broadcastAddress;
  final convention = switch (result.prefix) {
    31 => 'For /31 point-to-point links, RFC 3021 treats both addresses as endpoints. There is no directed broadcast.',
    32 => 'A /32 identifies one host/address. Its usable count is 1 and there is no directed broadcast.',
    _ => 'For /0–/30, the traditional usable-host count excludes the network and broadcast addresses (total − 2).',
  };
  return CalculationResult(
    context: SubnetContext(result),
    formattedValue: '$network/${result.prefix}',
    formula: formula,
    substitution: '${result.address} AND $mask = $network',
    explanation:
        'This prefix contains ${result.totalAddresses} addresses and ${result.usableHosts} usable addresses under the selected convention. $convention',
    warnings: [
      'Counts describe subnet arithmetic; reserved or special-purpose addresses are not guaranteed assignable or publicly routable.',
    ],
    details: [
      ResultDetail('IP', result.address.toString()),
      ResultDetail('CIDR', '/${result.prefix}'),
      ResultDetail('Subnet mask', mask),
      ResultDetail('Network address', network),
      ResultDetail(
        'Broadcast address',
        broadcast == null
            ? 'Not applicable for /${result.prefix}'
            : Ipv4Address.formatBits(broadcast),
      ),
      ResultDetail('Last address', Ipv4Address.formatBits(result.lastAddress)),
      ResultDetail('Total addresses', result.totalAddresses.toString()),
      ResultDetail('Usable host addresses', result.usableHosts.toString()),
      ResultDetail(
        'Usable range',
        '${Ipv4Address.formatBits(result.firstUsable)} – ${Ipv4Address.formatBits(result.lastUsable)}',
      ),
    ],
  );
}
