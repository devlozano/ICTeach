import 'package:flutter_test/flutter_test.dart';
import 'package:icteach/data/simulation_data.dart';

void main() {
  test('simulation data contains valid scenarios', () {
    final simulations = SimulationData.getAllSimulations();
    expect(simulations, isNotEmpty);

    final simulation = simulations.first;
    expect(simulation.title, isNotEmpty);
    expect(simulation.items, isNotEmpty);
    expect(simulation.slots, hasLength(simulation.items.length));
  });
}
