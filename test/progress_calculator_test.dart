import 'package:flutter_test/flutter_test.dart';
import 'package:icteach/utils/progress_calculator.dart';

void main() {
  test('calculates overall progress percentages for each learning category',
      () {
    final stats = ProgressCalculator.calculate(
      quizCompleted: 3,
      quizTotal: 5,
      moduleCompleted: 4,
      moduleTotal: 8,
      simulationCompleted: 2,
      simulationTotal: 4,
      assessmentCompleted: 1,
      assessmentTotal: 3,
    );

    expect(stats.quizPercent, closeTo(60.0, 0.0001));
    expect(stats.modulePercent, closeTo(50.0, 0.0001));
    expect(stats.simulationPercent, closeTo(50.0, 0.0001));
    expect(stats.assessmentPercent, closeTo(33.3333333333, 0.0001));
    expect(stats.overallPercent, closeTo(48.3333333333, 0.0001));
  });

  test('returns zero progress when totals are missing', () {
    final stats = ProgressCalculator.calculate(
      quizCompleted: 0,
      quizTotal: 0,
      moduleCompleted: 0,
      moduleTotal: 0,
      simulationCompleted: 0,
      simulationTotal: 0,
      assessmentCompleted: 0,
      assessmentTotal: 0,
    );

    expect(stats.quizPercent, 0.0);
    expect(stats.modulePercent, 0.0);
    expect(stats.simulationPercent, 0.0);
    expect(stats.assessmentPercent, 0.0);
    expect(stats.overallPercent, 0.0);
  });
}
