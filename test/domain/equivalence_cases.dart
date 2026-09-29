import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculation_result.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculator_input.dart';
import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/ipv4_address.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/ipv4_subnet.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/network_representations.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/thermal.dart';

import '../support/catalog_audit_samples.dart';
import 'checks.dart';
import 'numerical_checks.dart';

// Independent conversion references: test data, not calls to production scale.
const _factors = <EngineeringUnit, double>{
  EngineeringUnit.millivolt: 1e-3,
  EngineeringUnit.kilovolt: 1e3,
  EngineeringUnit.milliampere: 1e-3,
  EngineeringUnit.kiloampere: 1e3,
  EngineeringUnit.milliohm: 1e-3,
  EngineeringUnit.kiloohm: 1e3,
  EngineeringUnit.megaohm: 1e6,
  EngineeringUnit.gram: 1e-3,
  EngineeringUnit.centimetre: 1e-2,
  EngineeringUnit.millimetre: 1e-3,
  EngineeringUnit.millipascalSecond: 1e-3,
  EngineeringUnit.litre: 1e-3,
  EngineeringUnit.kilopascal: 1e3,
  EngineeringUnit.bar: 1e5,
  EngineeringUnit.atmosphere: 101325,
  EngineeringUnit.kilowatt: 1e3,
  EngineeringUnit.kilojoule: 1e3,
  EngineeringUnit.wattHour: 3600,
  EngineeringUnit.kilowattHour: 3600000,
  EngineeringUnit.minute: 60,
  EngineeringUnit.hour: 3600,
  EngineeringUnit.squareCentimetre: 1e-4,
  EngineeringUnit.litrePerSecond: 1e-3,
  EngineeringUnit.litrePerMinute: 1 / 60000,
  EngineeringUnit.kilojouleSpecificHeat: 1e3,
  EngineeringUnit.percent: .01,
};

double _base(double raw, EngineeringUnit unit) =>
    unit == EngineeringUnit.celsius
    ? raw + 273.15
    : unit == EngineeringUnit.fahrenheit
    ? (raw + 459.67) * 5 / 9
    : raw * (_factors[unit] ?? 1);
double _inUnit(double base, EngineeringUnit unit) =>
    unit == EngineeringUnit.celsius
    ? base - 273.15
    : unit == EngineeringUnit.fahrenheit
    ? base * 9 / 5 - 459.67
    : base / (_factors[unit] ?? 1);

// Vary model-valid quantities; do not scale every field indiscriminately.
const _scaledInputs = <String, Set<String>>{
  'ohms-law': {'voltage', 'current', 'resistance'},
  'dc-power': {'voltage', 'current', 'power'},
  'newtons-second-law': {'mass'},
  'reynolds-number': {'length'},
  'ideal-gas-law': {'volume', 'pressure'},
  'electrical-energy': {'power'},
  'voltage-divider': {'r1', 'r2'},
  'torque': {'radius'},
  'mechanical-work': {'distance'},
  'mechanical-power': {'work'},
  'kinetic-energy': {'mass'},
  'momentum': {'mass'},
  'volumetric-flow': {'area'},
  'pipe-flow': {'diameter'},
  'hydrostatic-pressure': {'depth'},
  'bernoulli-basic': {'pressure1'},
  'sensible-heat': {'mass'},
  'thermal-efficiency': {'work', 'heat'},
  'linear-expansion': {'length'},
  'pythagorean': {'a', 'b', 'c'},
  'series-resistance': {'r1', 'r2'},
  'parallel-resistance': {'r1', 'r2'},
};

Map<String, void Function()> equivalenceCases() => {
  'all multiplicative unit alternatives preserve physical results at selected scales': () {
    final catalog = createInitialCatalog();
    final visited = <String>{};
    for (final d in catalog.all) {
      if (d.id == 'temperature-converter') {
        continue; // Affine cycle family below.
      }
      for (final m in d.modes) {
        if (!m.inputs.any((i) => i.units.length > 1)) continue;
        final selected = _scaledInputs[d.id];
        if (selected == null) {
          throw StateError('Missing explicit scale selection for ${d.id}');
        }
        visited.add(d.id);
        final canonical = catalogAuditInputs['${d.id}/${m.id}']!;
        for (final s in engineeringScales) {
          final raw = <String, String>{
            for (final i in m.inputs)
              i.id:
                  (double.parse(canonical[i.id]!) *
                          (selected.contains(i.id) ? s : 1))
                      .toString(),
          };
          final reference = valueOf(
            m.calculate(raw, {}),
            '${d.id}/${m.id} canonical scale=$s',
          );
          final mixed = <String, String>{...raw};
          final mixedUnits = <String, EngineeringUnit>{};
          for (final input in m.inputs) {
            final normalized = _base(
              double.parse(raw[input.id]!),
              input.units.first,
            );
            for (final unit in input.units.skip(1)) {
              final equivalent = _inUnit(normalized, unit).toString();
              final context =
                  '${d.id}/${m.id} scale=$s ${input.id}=$equivalent ${unit.symbol}; base $raw';
              final actual = valueOf(
                m.calculate({...raw, input.id: equivalent}, {input.id: unit}),
                context,
              );
              final budget = d.id == 'pythagorean'
                  ? 64
                  : 16; // bounded leg inversion conditioning.
              near(
                actual.value!,
                reference.value!,
                relative: budget * binary64Epsilon,
                context: context,
              );
              mixed[input.id] = equivalent;
              mixedUnits[input.id] = unit;
            }
          }
          final combined = valueOf(
            m.calculate(mixed, mixedUnits),
            '${d.id}/${m.id} mixed units scale=$s',
          );
          near(
            combined.value!,
            reference.value!,
            relative: (d.id == 'pythagorean' ? 64 : 32) * binary64Epsilon,
            context: '${d.id}/${m.id} simultaneous mixed units scale=$s',
          );
        }
      }
    }
    checkEqual(visited.length, _scaledInputs.length);
  },
  'conversion reference factors and alternate result units round-trip': () {
    for (final entry in _factors.entries) {
      for (final x in engineeringScales) {
        final normalized = valueOf(
          entry.key.toBase(x),
          'unit ${entry.key} input=$x',
        );
        near(
          normalized,
          x * entry.value,
          relative: 4 * binary64Epsilon,
          context: 'reference ${entry.key} x=$x',
        );
        near(
          valueOf(
            entry.key.fromBase(normalized),
            'unit inverse ${entry.key} x=$x',
          ),
          x,
          relative: 8 * binary64Epsilon,
          context: 'inverse ${entry.key} x=$x',
        );
      }
    }
  },
  'absolute temperatures cycle across all three affine scales': () {
    final units = [
      EngineeringUnit.celsius,
      EngineeringUnit.fahrenheit,
      EngineeringUnit.kelvin,
    ];
    final inputs = <EngineeringUnit, List<double>>{
      EngineeringUnit.celsius: [-273.15, -200, -40, 0, 20, 37, 100, 1000, 1e6],
      EngineeringUnit.fahrenheit: [-459.67, -40, 32, 68, 212, 1000, 1e6],
      EngineeringUnit.kelvin: [0, 1, 273.15, 300, 1000, 1e6],
    };
    for (final from in units) {
      for (final raw in inputs[from]!) {
        final base = valueOf(
          from.toBase(raw),
          'temperature $raw ${from.symbol}',
        );
        valueOf(
          AbsoluteTemperature.kelvin(base),
          'physical temperature $raw ${from.symbol}',
        );
        for (final via in units) {
          final transferred = valueOf(
            via.fromBase(base),
            'temperature to $via',
          );
          final returnedBase = valueOf(
            via.toBase(transferred),
            'temperature from $via',
          );
          final returned = valueOf(
            from.fromBase(returnedBase),
            'temperature return $from',
          );
          // Cancellation against offsets requires an absolute bound in degrees,
          // scaled by operands including those offsets, not relative to zero.
          final bound =
              8 *
              binary64Epsilon *
              (raw.abs() + transferred.abs() + 273.15 + 459.67);
          near(
            returned,
            raw,
            relative: 0,
            absolute: bound,
            context: 'temperature $raw $from via $via',
          );
        }
      }
    }
    for (final value in [-1e12, -1.0, 0.0, 1e-12, 1.0, 1e12]) {
      checkEqual(
        valueOf(EngineeringUnit.celsiusDifference.toBase(value), 'C interval'),
        value,
      );
      checkEqual(
        valueOf(EngineeringUnit.kelvinDifference.toBase(value), 'K interval'),
        value,
      );
    }
    // Unrecoverable affine encoding near absolute zero is explicit evidence of
    // conditioning, not permission to loosen all unit-equivalence comparisons.
    final c = valueOf(
      EngineeringUnit.celsius.fromBase(double.minPositive),
      'tiny K to C',
    );
    checkEqual(c, -273.15);
    checkEqual(valueOf(EngineeringUnit.celsius.toBase(c), 'tiny K via C'), 0.0);
  },
  'network representations masks wildcards and subnet partitions are exact':
      () {
        final addresses = <BigInt>{
          BigInt.zero,
          Ipv4Address.maxBits,
          BigInt.from(0xC0A8010A),
          BigInt.from(0x7FFFFFFF),
          BigInt.from(0x80000000),
        };
        for (var bit = 0; bit < 32; bit++) {
          addresses.add(BigInt.one << bit);
          addresses.add(Ipv4Address.maxBits ^ (BigInt.one << bit));
        }
        for (final prefix in List.generate(33, (i) => i)) {
          final maskText = valueOf(
            Ipv4Representations.mask(prefix),
            'mask /$prefix',
          );
          final mask = valueOf(
            Ipv4Address.parse(maskText),
            'parse mask /$prefix',
          );
          checkEqual(
            valueOf(Ipv4Representations.prefix(mask), 'prefix /$prefix'),
            prefix,
          );
          final wildcardText = valueOf(
            Ipv4Representations.wildcard(mask),
            'wildcard /$prefix',
          );
          final wildcard = valueOf(
            Ipv4Address.parse(wildcardText),
            'wildcard parse',
          );
          checkEqual(mask.bits ^ wildcard.bits, Ipv4Address.maxBits);
          for (final bits in addresses) {
            final decimal = Ipv4Address.formatBits(bits);
            final address = valueOf(
              Ipv4Address.parse(decimal),
              'address $decimal',
            );
            checkEqual(
              valueOf(
                Ipv4Representations.decimal(
                  Ipv4Representations.binary(address),
                ),
                'binary round-trip $decimal',
              ),
              decimal,
            );
            final subnet = valueOf(
              Ipv4Subnet.calculate(address: address, prefix: prefix),
              'subnet $decimal/$prefix',
            );
            final size = BigInt.one << (32 - prefix);
            checkEqual(subnet.network, bits & mask.bits);
            checkEqual(subnet.network & (size - BigInt.one), BigInt.zero);
            checkEqual(subnet.lastAddress, subnet.network + size - BigInt.one);
            checkEqual(subnet.totalAddresses, size);
            checkEqual(
              subnet.usableHosts,
              prefix <= 30 ? size - BigInt.two : size,
            );
            checkEqual(
              subnet.broadcastAddress,
              prefix <= 30 ? subnet.lastAddress : null,
            );
            checkEqual(
              subnet.firstUsable,
              subnet.network + (prefix <= 30 ? BigInt.one : BigInt.zero),
            );
            checkEqual(
              subnet.lastUsable,
              subnet.lastAddress - (prefix <= 30 ? BigInt.one : BigInt.zero),
            );
          }
        }
      },
  'all numeric modes reject missing malformed nonfinite and overflowing input': () {
    for (final d in createInitialCatalog().all) {
      for (final mode in d.modes) {
        final raw = catalogAuditInputs['${d.id}/${mode.id}']!;
        for (final input in mode.inputs.where(
          (i) => i.kind == CalculatorInputKind.decimal,
        )) {
          for (final bad in [
            '',
            'bad',
            'NaN',
            'Infinity',
            '-Infinity',
            '1e309',
          ]) {
            final outcome = mode.calculate({...raw, input.id: bad}, {});
            if (outcome is! CalculationFailure<CalculationResult> ||
                !outcome.issues.any((i) => i.fieldId == input.id)) {
              throw StateError(
                '${d.id}/${mode.id} ${input.id}=$bad did not give a field failure',
              );
            }
          }
        }
      }
    }
  },
};
