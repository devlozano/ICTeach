class DiagnosticQuestion {
  final String prompt;
  final List<String> options;
  final int answer;
  final String competency;
  const DiagnosticQuestion(
    this.prompt,
    this.options,
    this.answer,
    this.competency,
  );
}

/// Instructional placement diagnostic, not a certification examination.
class PreAssessmentData {
  static const version = 1;
  static const questions = <DiagnosticQuestion>[
    DiagnosticQuestion(
      'Before opening a computer, what should you do?',
      [
        'Disconnect power and use ESD precautions',
        'Leave power connected',
        'Remove the CPU first',
        'Touch power supply internals',
      ],
      0,
      'COC1',
    ),
    DiagnosticQuestion(
      'Which component stores working data temporarily?',
      ['SSD', 'RAM', 'Power supply', 'Heat sink'],
      1,
      'COC1',
    ),
    DiagnosticQuestion(
      'What determines CPU compatibility?',
      [
        'Case color',
        'Monitor resolution',
        'Socket, chipset and firmware support',
        'Keyboard layout',
      ],
      2,
      'COC1',
    ),
    DiagnosticQuestion(
      'Before reinstalling an operating system, what is essential?',
      [
        'Delete all partitions immediately',
        'Verify backups and installation requirements',
        'Disconnect the CPU fan',
        'Disable cooling',
      ],
      1,
      'COC1',
    ),
    DiagnosticQuestion(
      'Which connector supplies main motherboard power?',
      ['RJ45', 'SATA data', 'USB-A', '24-pin ATX'],
      3,
      'COC1',
    ),
    DiagnosticQuestion(
      'A memory module does not fit. What should you do?',
      [
        'Push harder',
        'Cut the notch',
        'Check memory type and orientation',
        'Remove the clips',
      ],
      2,
      'COC1',
    ),
    DiagnosticQuestion(
      'Which device connects hosts within an Ethernet LAN?',
      ['Switch', 'Scanner', 'Projector', 'UPS'],
      0,
      'COC2',
    ),
    DiagnosticQuestion(
      'What are pins 1 and 2 in T568B order?',
      [
        'White-green and green',
        'White-orange and orange',
        'Blue and white-blue',
        'White-brown and brown',
      ],
      1,
      'COC2',
    ),
    DiagnosticQuestion(
      'Which address shares a /24 subnet with 192.168.1.10?',
      ['192.168.2.10', '10.0.0.10', '192.168.1.20', '172.16.1.10'],
      2,
      'COC2',
    ),
    DiagnosticQuestion(
      'What does a default gateway do?',
      [
        'Store passwords',
        'Supply power',
        'Set screen resolution',
        'Forward traffic to other networks',
      ],
      3,
      'COC2',
    ),
    DiagnosticQuestion(
      'Which command tests whether another IP host responds?',
      ['format', 'ping', 'rename', 'mkdir'],
      1,
      'COC2',
    ),
    DiagnosticQuestion(
      'Two computers use the same static IP. What should you investigate?',
      [
        'An IP address conflict',
        'Desktop wallpaper',
        'Display brightness',
        'Keyboard language',
      ],
      0,
      'COC2',
    ),
  ];
  static Map<String, dynamic> score(List<int> answers) {
    if (answers.length != questions.length ||
        answers.asMap().entries.any(
          (e) => e.value < 0 || e.value >= questions[e.key].options.length,
        )) {
      throw ArgumentError('Answer every diagnostic question.');
    }
    var correct = 0;
    final groups = <String, int>{'COC1': 0, 'COC2': 0};
    for (var i = 0; i < questions.length; i++) {
      if (answers[i] == questions[i].answer) {
        correct++;
        groups.update(questions[i].competency, (value) => value + 1);
      }
    }
    return {
      'score': correct,
      'totalQuestions': questions.length,
      'percentage': correct / questions.length * 100,
      'competencyScores': groups,
    };
  }

  static bool isComplete(Map<String, dynamic>? data) =>
      data?['version'] == version &&
      data?['completed'] == true &&
      data?['answers'] is List &&
      (data!['answers'] as List).length == questions.length;
}
