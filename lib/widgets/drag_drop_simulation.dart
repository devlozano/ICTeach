import 'package:flutter/material.dart';

import '../models/simulation_model.dart' as sim_models;
import 'draggable_item_widget.dart';
import 'drop_target_widget.dart';

class DragDropSimulation extends StatefulWidget {
  final sim_models.Simulation simulation;
  final Function(int score, int total, bool passed) onComplete;

  const DragDropSimulation({
    super.key,
    required this.simulation,
    required this.onComplete,
  });

  @override
  State<DragDropSimulation> createState() => _DragDropSimulationState();
}

class _DragDropSimulationState extends State<DragDropSimulation> {
  late Map<String, String> _placements;
  late List<String> _availableItems;
  late List<String> _availableSlots;
  bool _isComplete = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _resetSimulation();
  }

  void _resetSimulation() {
    _placements = {};
    _availableItems = widget.simulation.items.map((i) => i.id).toList();
    _availableSlots = widget.simulation.slots.toList();
    _isComplete = false;
    _attempts = 0;
    setState(() {});
  }

  void _handleDrop(String itemId, String slotId) {
    if (_isComplete) return;
    if (_placements.containsKey(itemId)) return;
    if (!_availableSlots.contains(slotId)) return;

    if (_placements.containsValue(slotId)) {
      final existingItem = _placements.entries
          .firstWhere(
            (entry) => entry.value == slotId,
            orElse: () => const MapEntry('', ''),
          )
          .key;

      if (existingItem.isNotEmpty) {
        setState(() {
          _placements.remove(existingItem);
          _availableItems.add(existingItem);
        });
      }
    }

    setState(() {
      _placements[itemId] = slotId;
      _availableItems.remove(itemId);
      _availableSlots.remove(slotId);
    });

    if (_placements.length == widget.simulation.items.length) {
      _calculateScore();
    }
  }

  void _calculateScore() {
    int correct = 0;
    final total = widget.simulation.items.length;

    for (final item in widget.simulation.items) {
      final placedSlot = _placements[item.id];
      if (placedSlot == item.correctSlot) {
        correct++;
      }
    }

    setState(() {
      _isComplete = true;
      _attempts++;
    });

    final percentage = (correct / total * 100).round();
    final passed = percentage >= widget.simulation.passingScore;
    _showResultDialog(percentage, passed, correct, total);
    widget.onComplete(correct, total, passed);
  }

  void _showResultDialog(int percentage, bool passed, int correct, int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              passed ? Icons.check_circle : Icons.refresh,
              color: passed ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(passed ? 'Excellent!' : 'Keep Practicing!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You placed $correct out of $total items correctly.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: passed ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      passed ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    passed ? Icons.thumb_up : Icons.emoji_events,
                    color: passed ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Score: $percentage% (${widget.simulation.passingScore}% needed to pass)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: passed
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
            if (!passed) ...[
              const SizedBox(height: 8),
              const Text(
                'Review the correct placements and try again!',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (passed)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue'),
            ),
          if (!passed)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetSimulation();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.assignment,
                size: 20,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Place ${_placements.length}/${widget.simulation.items.length} items',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              if (_attempts > 0)
                Text(
                  'Attempts: $_attempts',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.simulation.slots.map((slotId) {
              String? placedItemId;
              for (final entry in _placements.entries) {
                if (entry.value == slotId) {
                  placedItemId = entry.key;
                  break;
                }
              }

              final item = placedItemId != null
                  ? widget.simulation.items
                      .firstWhere((i) => i.id == placedItemId)
                  : null;

              return DropTargetWidget(
                slotId: slotId,
                placedItem: item,
                isComplete: _isComplete,
                onDrop: _handleDrop,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        if (_availableItems.isNotEmpty) ...[
          const Text(
            'Available Components:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableItems.map((itemId) {
                final item =
                    widget.simulation.items.firstWhere((i) => i.id == itemId);
                return DraggableItemWidget(
                  item: item,
                  isComplete: _isComplete,
                );
              }).toList(),
            ),
          ),
        ],
        if (_availableItems.isEmpty && !_isComplete)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: Text(
                'All items placed! Checking your answers...',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Passing Score: ${widget.simulation.passingScore}%',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            if (!_isComplete)
              TextButton(
                onPressed: _resetSimulation,
                child: const Text('Reset'),
              ),
          ],
        ),
      ],
    );
  }
}
