import '../calculation_outcome.dart';
import '../calculation_result.dart';
import '../calculator_category.dart';
import '../calculator_definition.dart';
import '../calculator_mode.dart';
import '../engines/ipv4_address.dart';
import '../engines/network_representations.dart';

CalculatorDefinition createIpv4RepresentationDefinition() {
  final binary = _addressMode(
    id: 'binary',
    label: 'Decimal to binary',
    resultLabel: 'Binary IPv4',
    formula: 'Binary IPv4 = four 8-bit octets',
    inputLabel: 'IPv4 address',
    calculate: (address) =>
        CalculationSuccess(Ipv4Representations.binary(address)),
    explanation: 'Each decimal octet is represented by exactly eight bits, including leading zeros.',
  );
  final decimal = CalculatorMode(
    id: 'decimal',
    label: 'Binary to decimal',
    formula: 'Decimal IPv4 = four base-10 octets',
    inputHint: 'Use four groups of eight bits separated by dots.',
    inputs: [
      CalculatorInput(
        id: 'binary',
        label: 'Binary IPv4',
        kind: CalculatorInputKind.text,
      ),
    ],
    calculate: (raw, _) => _report(
      Ipv4Representations.decimal(raw['binary'] ?? ''),
      label: 'Decimal IPv4',
      formula: 'Decimal IPv4 = four base-10 octets',
      input: raw['binary'] ?? '',
      explanation: 'Each group of eight bits becomes one decimal octet between 0 and 255.',
    ),
  );
  return CalculatorDefinition(
    id: 'ipv4-representation',
    name: 'Binary / Decimal IPv4',
    description: 'Convert dotted IPv4 addresses between binary and decimal.',
    category: CalculatorCategory.networking,
    formula: binary.formula,
    explanation: 'An IPv4 address is exactly 32 bits in four octets.',
    inputs: binary.inputs,
    modes: [binary, decimal],
    keywords: ['binary', 'decimal', 'ipv4', 'bits'],
  );
}

CalculatorDefinition createSubnetMaskDefinition() {
  final toPrefix = _addressMode(
    id: 'prefix',
    label: 'Mask to CIDR',
    resultLabel: 'CIDR',
    formula: 'CIDR = count of leading one bits',
    inputLabel: 'Subnet mask',
    calculate: (address) => switch (Ipv4Representations.prefix(address)) {
      CalculationSuccess<int>(:final value) => CalculationSuccess('/$value'),
      CalculationFailure<int>(:final issues) => CalculationFailure(issues),
    },
    explanation: 'The prefix counts contiguous network bits. All remaining bits must be zero.',
  );
  final toMask = CalculatorMode(
    id: 'mask',
    label: 'CIDR to mask',
    formula: 'Mask = prefix one bits followed by zeros',
    inputs: [
      CalculatorInput(
        id: 'prefix',
        label: 'CIDR prefix',
        kind: CalculatorInputKind.integer,
      ),
    ],
    calculate: (raw, _) {
      final parsed = Ipv4Address.parsePrefix(raw['prefix'] ?? '');
      if (parsed case CalculationFailure<int>(:final issues)) {
        return CalculationFailure(issues);
      }
      return _report(
        Ipv4Representations.mask((parsed as CalculationSuccess<int>).value),
        label: 'Mask',
        formula: 'Mask = prefix one bits followed by zeros',
        input: '/${raw['prefix']}',
        explanation: 'One bits identify the network portion; zero bits identify host positions.',
      );
    },
  );
  return CalculatorDefinition(
    id: 'subnet-mask',
    name: 'Subnet Mask ↔ CIDR',
    description: 'Convert contiguous subnet masks and CIDR prefixes.',
    category: CalculatorCategory.networking,
    formula: toPrefix.formula,
    explanation: 'A subnet mask has a contiguous block of network bits.',
    inputs: toPrefix.inputs,
    modes: [toPrefix, toMask],
    keywords: ['mask', 'cidr', 'prefix', 'contiguous'],
  );
}

CalculatorDefinition createWildcardDefinition() {
  final mode = _addressMode(
    id: 'wildcard',
    label: 'Wildcard mask',
    resultLabel: 'Wildcard',
    formula: 'Wildcard = 255.255.255.255 XOR mask',
    inputLabel: 'Subnet mask',
    calculate: Ipv4Representations.wildcard,
    explanation: 'A one in the wildcard marks a host bit that the corresponding subnet mask leaves unselected.',
  );
  return CalculatorDefinition(
    id: 'wildcard-mask',
    name: 'Wildcard Mask',
    description: 'Invert a valid subnet mask to its wildcard mask.',
    category: CalculatorCategory.networking,
    formula: mode.formula,
    explanation:
        'The wildcard is the bitwise complement of a contiguous subnet mask.',
    inputs: mode.inputs,
    modes: [mode],
    assumptions: [
      'Input must be a contiguous subnet mask, not an arbitrary ACL wildcard.',
    ],
    keywords: ['wildcard', 'mask', 'inverse', 'acl'],
  );
}

CalculatorMode _addressMode({
  required String id,
  required String label,
  required String resultLabel,
  required String formula,
  required String inputLabel,
  required CalculationOutcome<String> Function(Ipv4Address) calculate,
  required String explanation,
}) => CalculatorMode(
  id: id,
  label: label,
  formula: formula,
  inputHint: 'Use four decimal octets from 0 to 255, without leading zeros.',
  inputs: [
    CalculatorInput(
      id: 'address',
      label: inputLabel,
      kind: CalculatorInputKind.ipv4,
    ),
  ],
  calculate: (raw, _) {
    final parsed = Ipv4Address.parse(raw['address'] ?? '');
    if (parsed case CalculationFailure<Ipv4Address>(:final issues)) {
      return CalculationFailure(issues);
    }
    return _report(
      calculate((parsed as CalculationSuccess<Ipv4Address>).value),
      label: resultLabel,
      formula: formula,
      input: raw['address'] ?? '',
      explanation: explanation,
    );
  },
);

CalculationOutcome<CalculationResult> _report(
  CalculationOutcome<String> outcome, {
  required String label,
  required String formula,
  required String input,
  required String explanation,
}) => switch (outcome) {
  CalculationFailure<String>(:final issues) => CalculationFailure(issues),
  CalculationSuccess<String>(:final value) => CalculationSuccess(
    CalculationResult(
      formattedValue: value,
      resultLabel: label,
      formula: formula,
      substitution: '$input → $value',
      explanation: explanation,
    ),
  ),
};
