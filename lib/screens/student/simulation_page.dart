import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  bool _isLoading = true;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _loadSimulation();
  }

  Future<void> _loadSimulation() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('simulations')
          .doc(widget.simulationId)
          .get();

      if (doc.exists) {
        setState(() {
          _simulation = sim_models.Simulation.fromFirestore(doc);
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    final simulation = SimulationData.getSimulationById(widget.simulationId);
    setState(() {
      _simulation = simulation;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: const Color(0xFF0B2B4A),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_simulation == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: const Color(0xFF0B2B4A),
          foregroundColor: Colors.white,
        ),
        body: const Center(
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
              Text(
                'Please try again later.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasStarted) {
      return _buildStartPage();
    }

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: Text(widget.className != null
            ? '${widget.title} • ${widget.className}'
            : widget.title),
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: 'Help',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Drag and drop the components to their correct positions. '
                      'You need ${_simulation!.passingScore}% to pass.',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildStartPage() {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: Text(widget.className != null
            ? '${widget.title} • ${widget.className}'
            : widget.title),
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getSimulationIcon(_simulation!.type),
                  size: 60,
                  color: Colors.blue.shade700,
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
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Competency', _simulation!.competency),
                    _buildInfoRow(
                        'Learning Outcome', _simulation!.learningOutcome),
                    _buildInfoRow(
                        'Items to Place', '${_simulation!.items.length}'),
                    _buildInfoRow(
                        'Time Limit', '${_simulation!.timeLimit} minutes'),
                    _buildInfoRow(
                        'Passing Score', '${_simulation!.passingScore}%'),
                    if (_simulation!.requiredSimulationId != null)
                      _buildInfoRow(
                        'Requirement',
                        'Complete previous simulation first',
                        warning: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _simulation!.isLocked
                      ? null
                      : () {
                          setState(() => _hasStarted = true);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _simulation!.isLocked
                        ? Colors.grey
                        : const Color(0xFF0B2B4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _simulation!.isLocked ? '🔒 Locked' : 'Start Simulation',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (_simulation!.isLocked) ...[
                const SizedBox(height: 8),
                const Text(
                  'Complete the required simulation first to unlock this.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
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

  Widget _buildInfoRow(String label, String value, {bool warning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: warning ? Colors.orange : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Play'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Drag a component from the bottom'),
            const SizedBox(height: 4),
            const Text('2. Drop it onto the correct target area'),
            const SizedBox(height: 4),
            const Text('3. All components must be placed'),
            const SizedBox(height: 4),
            Text('4. Get at least ${_simulation!.passingScore}% to pass'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _onComplete(int score, int total, bool passed) {
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
        'percentage': (score / total * 100).round(),
        'passed': passed,
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
        'attempts': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

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
