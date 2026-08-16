import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/simulation_data.dart';
import 'simulation_page.dart';

class SimulationsListPage extends StatefulWidget {
  final String classId;
  final String className;

  const SimulationsListPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<SimulationsListPage> createState() => _SimulationsListPageState();
}

class _SimulationsListPageState extends State<SimulationsListPage> {
  String _selectedCompetency = 'COC1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: Text('Simulations - ${widget.className}'),
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTabButton('COC1', 'COC1'),
                _buildTabButton('COC2', 'COC2'),
              ],
            ),
          ),
        ),
      ),
      body: _buildSimulationsList(),
    );
  }

  Widget _buildTabButton(String label, String value) {
    final isSelected = _selectedCompetency == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCompetency = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0B2B4A) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color:
                    isSelected ? const Color(0xFF0B2B4A) : Colors.grey.shade300,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimulationsList() {
    final simulations =
        SimulationData.getSimulationsByCompetency(_selectedCompetency);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: simulations.length,
      itemBuilder: (context, index) {
        final sim = simulations[index];
        return _SimulationCard(
          simulation: sim,
          classId: widget.classId,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SimulationPage(
                  classId: widget.classId,
                  className: widget.className,
                  simulationId: sim.id,
                  title: sim.title,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SimulationCard extends StatelessWidget {
  final dynamic simulation;
  final String classId;
  final VoidCallback onTap;

  const _SimulationCard({
    required this.simulation,
    required this.classId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCompetencyColor(simulation.competency)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getSimulationIcon(simulation.type),
                  size: 30,
                  color: _getCompetencyColor(simulation.competency),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      simulation.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      simulation.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getCompetencyColor(simulation.competency)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            simulation.competency,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getCompetencyColor(simulation.competency),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            simulation.learningOutcome,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .collection('simulation_progress')
                              .doc('${classId}_${simulation.id}')
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return const SizedBox();
                            }
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            if (data == null) return const SizedBox();
                            final passed = data['passed'] ?? false;
                            final percentage = data['percentage'] ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: passed
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    passed ? Icons.check_circle : Icons.star,
                                    color:
                                        passed ? Colors.green : Colors.orange,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$percentage%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: passed
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCompetencyColor(String competency) {
    switch (competency) {
      case 'COC1':
        return Colors.blue;
      case 'COC2':
        return Colors.green;
      default:
        return Colors.purple;
    }
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
