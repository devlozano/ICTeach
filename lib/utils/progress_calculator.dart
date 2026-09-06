class ProgressStats {
  final double quizPercent;
  final double modulePercent;
  final double simulationPercent;
  final double assessmentPercent;
  final double overallPercent;

  const ProgressStats({
    required this.quizPercent,
    required this.modulePercent,
    required this.simulationPercent,
    required this.assessmentPercent,
    required this.overallPercent,
  });
}

class ProgressCalculator {
  static ProgressStats calculate({
    required int quizCompleted,
    required int quizTotal,
    required int moduleCompleted,
    required int moduleTotal,
    required int simulationCompleted,
    required int simulationTotal,
    required int assessmentCompleted,
    required int assessmentTotal,
  }) {
    final quizPercent = _percentage(quizCompleted, quizTotal);
    final modulePercent = _percentage(moduleCompleted, moduleTotal);
    final simulationPercent = _percentage(simulationCompleted, simulationTotal);
    final assessmentPercent = _percentage(assessmentCompleted, assessmentTotal);

    final average =
        [
          quizPercent,
          modulePercent,
          simulationPercent,
          assessmentPercent,
        ].reduce((sum, value) => sum + value) /
        4;

    return ProgressStats(
      quizPercent: quizPercent,
      modulePercent: modulePercent,
      simulationPercent: simulationPercent,
      assessmentPercent: assessmentPercent,
      overallPercent: average,
    );
  }

  static double _percentage(int completed, int total) {
    if (total <= 0) {
      return 0.0;
    }

    return ((completed / total) * 100).clamp(0.0, 100.0);
  }
}
