import '../domain/phase4_cases.dart';

// Canonical inputs for every registered mode, reused by the catalog state audit.
final catalogAuditInputs = <String, Map<String, String>>{
  for (final sample in numericSamples)
    '${sample.id}/${sample.mode}': sample.values,
  'ohms-law/current': {'voltage': '12', 'resistance': '6'},
  'ohms-law/voltage': {'current': '2', 'resistance': '6'},
  'ohms-law/resistance': {'voltage': '12', 'current': '2'},
  'newtons-second-law/force': {'mass': '2', 'acceleration': '-3'},
  'reynolds-number/reynolds': {
    'density': '1000',
    'speed': '2',
    'length': '0.05',
    'viscosity': '0.001',
  },
  'ideal-gas-law/pressure': {
    'amount': '1',
    'temperature': '300',
    'volume': '0.025',
  },
  'ideal-gas-law/volume': {
    'amount': '1',
    'temperature': '300',
    'pressure': '100000',
  },
  'ideal-gas-law/amount': {
    'volume': '0.025',
    'temperature': '300',
    'pressure': '100000',
  },
  'ideal-gas-law/temperature': {
    'amount': '1',
    'volume': '0.025',
    'pressure': '100000',
  },
  'ipv4-subnet/subnet': {'address': '192.168.1.10', 'prefix': '24'},
  'ipv4-representation/binary': {'address': '192.168.1.10'},
  'ipv4-representation/decimal': {
    'binary': '11000000.10101000.00000001.00001010',
  },
  'subnet-mask/prefix': {'address': '255.255.255.0'},
  'subnet-mask/mask': {'prefix': '24'},
  'wildcard-mask/wildcard': {'address': '255.255.255.0'},
  'quadratic-equation/roots': {'a': '1', 'b': '-10', 'c': '25'},
};
