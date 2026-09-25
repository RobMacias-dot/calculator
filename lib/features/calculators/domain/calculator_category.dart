enum CalculatorCategory {
  electrical('electrical', 'Electrical', 'Circuits, power & energy'),
  mechanical('mechanical', 'Mechanical', 'Forces, motion & materials'),
  fluids('fluids', 'Fluids', 'Flow, pressure & transport'),
  thermodynamics(
    'thermodynamics',
    'Thermodynamics',
    'Heat, work & equilibrium',
  ),
  networking('networking', 'Networking', 'Addresses, subnets & networks'),
  mathematics('mathematics', 'Mathematics', 'Numbers, vectors & equations');

  const CalculatorCategory(this.id, this.label, this.description);

  final String id;
  final String label;
  final String description;

  static CalculatorCategory? fromId(String id) {
    for (final category in values) {
      if (category.id == id) return category;
    }
    return null;
  }
}
