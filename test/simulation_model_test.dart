import 'package:flutter_test/flutter_test.dart';
import 'package:icteach/data/simulation_data.dart';

void main() {
  test('simulation data contains valid easy scenarios', () {
    expect(simulationLibrary, isNotEmpty);

    final simulation = simulationLibrary.first;
    expect(simulation.title, isNotEmpty);
    expect(simulation.steps, isNotEmpty);
    expect(simulation.steps.first.options, hasLength(greaterThanOrEqualTo(2)));
    expect(simulation.steps.first.correctIndex, isNotNull);
  });
}
