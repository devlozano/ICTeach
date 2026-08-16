import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/simulation_model.dart';

class DraggableItemWidget extends StatelessWidget {
  final DraggableItem item;
  final bool isComplete;

  const DraggableItemWidget({
    super.key,
    required this.item,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: item.id,
      feedback: Material(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: 110,
          height: 82,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForCategory(item.category),
                color: _getColorForCategory(item.category),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildItemCard(),
      ),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
      },
      child: _buildItemCard(),
    );
  }

  Widget _buildItemCard() {
    return Container(
      width: 110,
      height: 82,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForCategory(item.category),
            color: _getColorForCategory(item.category),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            item.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'processor':
        return Icons.memory;
      case 'memory':
        return Icons.storage;
      case 'graphics':
        return Icons.important_devices;
      case 'power':
        return Icons.power;
      case 'storage':
        return Icons.save;
      case 'motherboard':
        return Icons.settings_ethernet;
      case 'network':
        return Icons.wifi;
      case 'cable':
        return Icons.linear_scale;
      default:
        return Icons.device_hub;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'processor':
        return Colors.purple;
      case 'memory':
        return Colors.blue;
      case 'graphics':
        return Colors.green;
      case 'power':
        return Colors.orange;
      case 'storage':
        return Colors.red;
      case 'motherboard':
        return Colors.cyan;
      case 'network':
        return Colors.indigo;
      case 'cable':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
