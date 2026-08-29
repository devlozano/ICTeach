import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/simulation_data.dart';
import '../../models/simulation_model.dart' as sim_models;
import '../../widgets/drag_drop_simulation.dart';

class SimulationPage extends StatefulWidget {
  final String classId;
  final String simulationId;
  final String title;
  final String? className;

  const SimulationPage({
    super.key,
    required this.classId,
    required this.simulationId,
    required this.title,
    this.className,
  });

  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  sim_models.Simulation? _simulation;
  List<sim_models.Simulation> _prerequisites = [];
  bool _isLoading = true;
  bool _hasStarted = false;
  bool _isCompleted = false;
  bool _prerequisiteCompleted = true;
  bool _feedbackSubmitted = false;

  @override
  void initState() {
    super.initState();

    _loadSimulation();
  }

  @override
  void dispose() {
    _setGameplayOrientation(false);
    super.dispose();
  }

  Future<void> _setGameplayOrientation(bool active) async {
    if (kIsWeb) return;
    await SystemChrome.setPreferredOrientations(
      active
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ],
    );
  }

  Future<void> _startGameplay() async {
    await _setGameplayOrientation(true);
    if (mounted) setState(() => _hasStarted = true);
  }

  Future<void> _loadSimulation() async {
    sim_models.Simulation? simulation;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('simulations')
          .doc(widget.simulationId)
          .get();
      if (doc.exists) simulation = sim_models.Simulation.fromFirestore(doc);
    } catch (_) {}

    simulation ??= SimulationData.getSimulationById(widget.simulationId);
    var completed = false;
    var prerequisiteCompleted = true;
    final prerequisites = simulation == null
        ? <sim_models.Simulation>[]
        : SimulationData.getPrerequisiteChain(simulation.id);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && simulation != null) {
      try {
        final progressRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('simulation_progress');
        final progress = await progressRef
            .doc('${widget.classId}_${simulation.id}')
            .get();
        completed =
            progress.data()?['completed'] == true &&
            progress.data()?['passed'] == true;

        if (simulation.requiredSimulationId != null) {
          final requiredProgress = await progressRef
              .doc('${widget.classId}_${simulation.requiredSimulationId}')
              .get();
          prerequisiteCompleted =
              requiredProgress.data()?['completed'] == true &&
              requiredProgress.data()?['passed'] == true;
        }
      } catch (_) {
        prerequisiteCompleted = simulation.requiredSimulationId == null;
      }
    } else {
      prerequisiteCompleted = simulation?.requiredSimulationId == null;
    }

    if (!mounted) return;
    setState(() {
      _simulation = simulation;
      _prerequisites = prerequisites;
      _isCompleted = completed;
      _prerequisiteCompleted = prerequisiteCompleted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _scaffold(const Center(child: CircularProgressIndicator()));
    }
    if (_simulation == null) {
      return _scaffold(
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Simulation not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Please try again later.'),
            ],
          ),
        ),
      );
    }
    if (_isCompleted) return _buildCompletedPage();
    if (!_hasStarted) return _buildStartPage();

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: _appBar(_simulation!.title, showHelp: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _notice(Icons.info_outline, _getInstructionText(), Colors.blue),
            if (_prerequisites.isNotEmpty) ...[
              const SizedBox(height: 16),
              _notice(
                Icons.lock,
                'Prerequisites: ${_prerequisites.map((item) => item.title).join(' -> ')}',
                Colors.orange,
              ),
            ],
            const SizedBox(height: 16),
            DragDropSimulation(
              simulation: _simulation!,
              onComplete: _onComplete,
            ),
          ],
        ),
      ),
    );
  }

  Scaffold _scaffold(Widget body) =>
      Scaffold(appBar: _appBar(widget.title), body: body);

  AppBar _appBar(String title, {bool showHelp = false}) => AppBar(
    title: Text(
      widget.className == null ? title : '$title • ${widget.className}',
    ),
    backgroundColor: const Color(0xFF0B2B4A),
    foregroundColor: Colors.white,
    automaticallyImplyLeading: !_isCompleted,
    actions: showHelp
        ? [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHelp,
              tooltip: 'Help',
            ),
          ]
        : null,
  );

  Widget _notice(IconData icon, String text, MaterialColor color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.shade200),
    ),
    child: Row(
      children: [
        Icon(icon, color: color.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color.shade800, fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Widget _buildStartPage() {
    final locked = _isLocked();
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: _appBar(_simulation!.title),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _competencyColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getSimulationIcon(_simulation!.type),
                  size: 60,
                  color: _competencyColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _simulation!.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _simulation!.description,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Competency', _simulation!.competency),
                    _buildInfoRow(
                      'Learning Outcome',
                      _simulation!.learningOutcome,
                    ),
                    _buildInfoRow(
                      'Items to Place',
                      '${_simulation!.items.length}',
                    ),
                    _buildInfoRow(
                      'Time Limit',
                      '${_simulation!.timeLimit} minutes',
                    ),
                    _buildInfoRow(
                      'Passing Score',
                      '${_simulation!.passingScore}%',
                    ),
                    if (_simulation!.requiredSimulationId != null)
                      _buildInfoRow(
                        'Requirement',
                        'Complete: ${_getPrerequisiteName()}',
                        warning: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: locked ? null : _startGameplay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: locked
                        ? Colors.grey
                        : const Color(0xFF0B2B4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    locked ? 'Locked' : 'Start Simulation',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (locked) ...[
                const SizedBox(height: 8),
                const Text(
                  'Complete the required simulation first to unlock this.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Simulations'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedPage() => Scaffold(
    backgroundColor: const Color(0xffF8FAFC),
    appBar: _appBar(_simulation!.title),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Simulation Completed!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your progress for "${_simulation!.title}" has been saved.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _feedbackSubmitted ? null : _showEvaluationDialog,
                icon: Icon(
                  _feedbackSubmitted ? Icons.check_circle : Icons.rate_review,
                ),
                label: Text(
                  _feedbackSubmitted
                      ? 'Evaluation submitted'
                      : 'Rate difficulty and give feedback',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _setGameplayOrientation(true);
                      if (!mounted) return;
                      setState(() {
                        _hasStarted = true;
                        _isCompleted = false;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to List'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B2B4A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _showEvaluationDialog() async {
    var difficulty = 3;
    final commentController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Activity evaluation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How difficult was this activity?'),
                Slider(
                  value: difficulty.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$difficulty / 5',
                  onChanged: (value) =>
                      setDialogState(() => difficulty = value.round()),
                ),
                Text(
                  const [
                    'Very easy',
                    'Easy',
                    'Appropriate',
                    'Difficult',
                    'Very difficult',
                  ][difficulty - 1],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'What should be improved? (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                await FirebaseFirestore.instance
                    .collection('activity_feedback')
                    .add({
                      'studentId': user.uid,
                      'classId': widget.classId,
                      'simulationId': widget.simulationId,
                      'simulationTitle': _simulation!.title,
                      'difficulty': difficulty,
                      'comment': commentController.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    commentController.dispose();
    if (submitted == true && mounted) {
      setState(() => _feedbackSubmitted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you. Your evaluation was saved.')),
      );
    }
  }

  Widget _buildInfoRow(String label, String value, {bool warning = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: warning ? Colors.orange : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );

  void _showHelp() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('How to Play'),
      content: Text(
        '1. Drag an item from the available components.\n\n2. Drop it onto the correct target.\n\n3. Place all items.\n\n4. Score at least ${_simulation!.passingScore}% to pass.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );

  Future<void> _onComplete(int score, int total, bool passed) async {
    if (passed) {
      await _setGameplayOrientation(false);
      if (mounted) setState(() => _isCompleted = true);
    }
    _saveProgress(score, total, passed);
  }

  Future<void> _saveProgress(int score, int total, bool passed) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('simulation_progress')
          .doc('${widget.classId}_${widget.simulationId}')
          .set({
            'classId': widget.classId,
            'simulationId': widget.simulationId,
            'score': score,
            'total': total,
            'percentage': total == 0 ? 0 : (score / total * 100).round(),
            'passed': passed,
            'completed': passed,
            'completedAt': passed ? FieldValue.serverTimestamp() : null,
            'attempts': FieldValue.increment(1),
          }, SetOptions(merge: true));
      if (passed) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('completed_content')
            .doc(widget.simulationId)
            .set({
              'classId': widget.classId,
              'contentId': widget.simulationId,
              'completedAt': FieldValue.serverTimestamp(),
            });
      }
      if (mounted && passed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {}
  }

  String _getInstructionText() =>
      'Drag and drop each item to its correct position. You need ${_simulation!.passingScore}% to pass.';
  bool _isLocked() => _simulation!.isLocked || !_prerequisiteCompleted;
  String _getPrerequisiteName() =>
      SimulationData.getSimulationById(
        _simulation!.requiredSimulationId ?? '',
      )?.title ??
      'Previous simulation';
  Color get _competencyColor =>
      _simulation!.competency == 'COC1' ? Colors.blue : Colors.green;

  IconData _getSimulationIcon(String type) {
    switch (type) {
      case 'assembly':
        return Icons.computer;
      case 'identification':
        return Icons.visibility;
      case 'networking':
        return Icons.wifi;
      case 'cabling':
        return Icons.linear_scale;
      default:
        return Icons.science;
    }
  }
}
