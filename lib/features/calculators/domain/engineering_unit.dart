import 'calculation_outcome.dart';

enum UnitDimension {
  voltage,
  current,
  resistance,
  mass,
  acceleration,
  density,
  velocity,
  length,
  dynamicViscosity,
  amount,
  temperature,
  volume,
  force,
  dimensionless,
  pressure,
  power,
  energy,
  time,
  torque,
  momentum,
  area,
  flow,
  temperatureDifference,
  specificHeat,
  expansionCoefficient,
}

/// Only units required by the current catalog. Bounds apply AFTER conversion.
enum EngineeringUnit {
  millivolt('mV', UnitDimension.voltage, 0.001),
  volt('V', UnitDimension.voltage, 1),
  kilovolt('kV', UnitDimension.voltage, 1000),
  milliampere('mA', UnitDimension.current, 0.001),
  ampere('A', UnitDimension.current, 1),
  kiloampere('kA', UnitDimension.current, 1000),
  milliohm('mΩ', UnitDimension.resistance, 0.001),
  ohm('Ω', UnitDimension.resistance, 1),
  kiloohm('kΩ', UnitDimension.resistance, 1000),
  megaohm('MΩ', UnitDimension.resistance, 1000000),
  kilogram('kg', UnitDimension.mass, 1),
  gram('g', UnitDimension.mass, 0.001),
  newton('N', UnitDimension.force, 1),
  acceleration('m/s²', UnitDimension.acceleration, 1),
  density('kg/m³', UnitDimension.density, 1),
  velocity('m/s', UnitDimension.velocity, 1),
  metre('m', UnitDimension.length, 1),
  centimetre('cm', UnitDimension.length, 0.01),
  millimetre('mm', UnitDimension.length, 0.001),
  dynamicViscosity('Pa·s', UnitDimension.dynamicViscosity, 1),
  millipascalSecond('mPa·s', UnitDimension.dynamicViscosity, 0.001),
  dimensionless('', UnitDimension.dimensionless, 1),
  mole('mol', UnitDimension.amount, 1),
  kelvin('K', UnitDimension.temperature, 1),
  celsius('°C', UnitDimension.temperature, 1, 273.15),
  cubicMetre('m³', UnitDimension.volume, 1),
  litre('L', UnitDimension.volume, 0.001),
  pascal('Pa', UnitDimension.pressure, 1),
  kilopascal('kPa', UnitDimension.pressure, 1000),
  bar('bar', UnitDimension.pressure, 100000),
  atmosphere('atm', UnitDimension.pressure, 101325),
  // Energy and rates. One Wh is exactly 3600 J.
  watt('W', UnitDimension.power, 1),
  kilowatt('kW', UnitDimension.power, 1000),
  joule('J', UnitDimension.energy, 1),
  kilojoule('kJ', UnitDimension.energy, 1000),
  wattHour('Wh', UnitDimension.energy, 3600),
  kilowattHour('kWh', UnitDimension.energy, 3600000),
  second('s', UnitDimension.time, 1),
  minute('min', UnitDimension.time, 60),
  hour('h', UnitDimension.time, 3600),
  newtonMetre('N·m', UnitDimension.torque, 1),
  momentum('kg·m/s', UnitDimension.momentum, 1),
  squareMetre('m²', UnitDimension.area, 1),
  squareCentimetre('cm²', UnitDimension.area, 0.0001),
  cubicMetrePerSecond('m³/s', UnitDimension.flow, 1),
  litrePerSecond('L/s', UnitDimension.flow, 0.001),
  litrePerMinute('L/min', UnitDimension.flow, 0.001 / 60),
  // Intervals intentionally have a DIFFERENT dimension and zero offset.
  kelvinDifference('ΔK', UnitDimension.temperatureDifference, 1),
  celsiusDifference('Δ°C', UnitDimension.temperatureDifference, 1),
  specificHeat('J/(kg·K)', UnitDimension.specificHeat, 1),
  kilojouleSpecificHeat('kJ/(kg·K)', UnitDimension.specificHeat, 1000),
  perKelvin('1/K', UnitDimension.expansionCoefficient, 1),
  perCelsius('1/°C', UnitDimension.expansionCoefficient, 1),
  fahrenheit('°F', UnitDimension.temperature, 5 / 9, 459.67 * (5 / 9)),
  percent('%', UnitDimension.dimensionless, 0.01);

  const EngineeringUnit(
    this.symbol,
    this.dimension,
    this.scale, [
    this.offset = 0,
  ]);
  final String symbol;
  final UnitDimension dimension;
  final double scale;
  final double offset;

  CalculationOutcome<double> toBase(double value) {
    if (!value.isFinite) {
      return calculationFailure(
        CalculationError.nonFinite,
        'Enter a finite number.',
      );
    }
    final converted = value * scale + offset;
    if (!converted.isFinite || (converted == 0 && value != 0 && offset == 0)) {
      return calculationFailure(
        CalculationError.numericRange,
        'This value cannot be represented in the base unit.',
      );
    }
    return CalculationSuccess(converted);
  }

  CalculationOutcome<double> fromBase(double value) {
    if (!value.isFinite) {
      return calculationFailure(
        CalculationError.nonFinite,
        'Enter a finite number.',
      );
    }
    final converted = (value - offset) / scale;
    return checkedResult(converted, zeroExpected: value == offset);
  }
}
