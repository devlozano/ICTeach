import 'dart:io';

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

  test('every simulation item references an existing asset', () {
    final missingAssets = <String>[];

    for (final simulation in SimulationData.getAllSimulations()) {
      for (final item in simulation.items) {
        if (!File(item.imageUrl).existsSync()) {
          missingAssets.add('${simulation.id}: ${item.imageUrl}');
        }
      }
    }

    expect(
      missingAssets,
      isEmpty,
      reason: 'Missing simulation assets:\n${missingAssets.join('\n')}',
    );
  });
}
