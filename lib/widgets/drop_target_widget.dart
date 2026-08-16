import 'package:flutter/material.dart';

import '../models/simulation_model.dart';

class DropTargetWidget extends StatelessWidget {
  final String slotId;
  final DraggableItem? placedItem;
  final bool isComplete;
  final Function(String, String) onDrop;

  const DropTargetWidget({
    super.key,
    required this.slotId,
    this.placedItem,
    required this.isComplete,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = placedItem != null;

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        onDrop(details.data, slotId);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 120,
          height: 100,
          decoration: BoxDecoration(
            color: isFilled
                ? _getColorForCategory(placedItem!.category)
                    .withValues(alpha: 0.1)
                : (candidateData.isNotEmpty
                    ? Colors.blue.shade50
                    : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFilled
                  ? _getColorForCategory(placedItem!.category)
                  : (candidateData.isNotEmpty
                      ? Colors.blue
                      : Colors.grey.shade300),
              width: isFilled ? 2 : 1,
            ),
            boxShadow: [
              if (candidateData.isNotEmpty)
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
            ],
          ),
          child: isFilled
              ? Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getIconForCategory(placedItem!.category),
                            color: _getColorForCategory(placedItem!.category),
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            placedItem!.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _getColorForCategory(placedItem!.category),
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isComplete)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: placedItem!.correctSlot == slotId
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                placedItem!.correctSlot == slotId ? '✓' : '✗',
                                style: TextStyle(
                                  color: placedItem!.correctSlot == slotId
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isComplete)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: placedItem!.correctSlot == slotId
                                ? Colors.green
                                : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            placedItem!.correctSlot == slotId
                                ? Icons.check
                                : Icons.close,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.drag_handle,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSlotLabel(slotId),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
        );
      },
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

  String _getSlotLabel(String slotId) {
    switch (slotId) {
      case 'cpu_socket':
        return 'CPU Socket';
      case 'ram_slot':
        return 'RAM Slot';
      case 'pcie_slot':
        return 'PCIe Slot';
      case 'psu_mount':
        return 'PSU Mount';
      case 'storage_bay':
        return 'Storage Bay';
      case 'motherboard_tray':
        return 'Motherboard Tray';
      case 'cpu_target':
      case 'ram_target':
      case 'gpu_target':
      case 'psu_target':
      case 'motherboard_target':
      case 'storage_target':
        return 'Label Here';
      case 'router_position':
        return 'Router';
      case 'switch_position':
        return 'Switch';
      case 'pc_position':
        return 'PC';
      case 'server_position':
        return 'Server';
      case 'printer_position':
        return 'Printer';
      case 'modem_position':
        return 'Modem';
      default:
        return 'Drop Here';
    }
  }
}
