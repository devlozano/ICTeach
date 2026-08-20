import 'package:flutter_test/flutter_test.dart';

import 'package:icteach/data/simulation_data.dart';

void main() {
  test('COC simulation library includes the required bundle', () {
    final simulations = SimulationData.getAllSimulations();

    expect(simulations.length, 6);
    expect(simulations.map((sim) => sim.competency).toSet(), {'COC1', 'COC2'});
    expect(simulations.any((sim) => sim.id == 'sim_coc1_assembly'), isTrue);
    expect(simulations.any((sim) => sim.id == 'sim_coc2_topology'), isTrue);
  });
}
