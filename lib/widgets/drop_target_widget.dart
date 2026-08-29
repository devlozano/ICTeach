import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/simulation_model.dart';

class DropTargetWidget extends StatelessWidget {
  final String slotId;
  final DraggableItem? placedItem;
  final bool isComplete;
  final Function(String, String) onDrop;
  final double width;
  final double height;
  final bool immersive;

  const DropTargetWidget({
    super.key,
    required this.slotId,
    this.placedItem,
    required this.isComplete,
    required this.onDrop,
    this.width = 120,
    this.height = 100,
    this.immersive = false,
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
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: immersive && isFilled
                ? Colors.transparent
                : isFilled
                ? _getColorForCategory(
                    placedItem!.category,
                  ).withValues(alpha: 0.1)
                : (candidateData.isNotEmpty
                      ? Colors.blue.withValues(alpha: 0.22)
                      : immersive
                      ? Colors.black.withValues(alpha: 0.22)
                      : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(immersive ? 5 : 10),
            border: Border.all(
              color: immersive && isFilled
                  ? Colors.transparent
                  : isFilled
                  ? _getColorForCategory(placedItem!.category)
                  : (candidateData.isNotEmpty
                        ? Colors.blue
                        : immersive
                        ? Colors.white70
                        : Colors.grey.shade300),
              width: isFilled ? (immersive ? 0 : 2) : 1,
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
              ? immersive
                    ? Center(
                        child: _buildImage(
                          placedItem!,
                          imageWidth: width,
                          imageHeight: height,
                        ),
                      )
                    : Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildImage(
                                  placedItem!,
                                  imageWidth: width * 0.88,
                                  imageHeight: height * 0.76,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  placedItem!.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _getColorForCategory(
                                      placedItem!.category,
                                    ),
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
                                      placedItem!.correctSlot == slotId
                                          ? '✓'
                                          : '✗',
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
                      _getSlotIcon(slotId),
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSlotLabel(slotId),
                      style: TextStyle(
                        fontSize: 11,
                        color: immersive ? Colors.white : Colors.grey.shade500,
                        fontWeight: immersive
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildImage(
    DraggableItem item, {
    required double imageWidth,
    required double imageHeight,
  }) {
    if (immersive && slotId == 'ram_slot') {
      return SizedBox(
        width: imageWidth,
        height: imageHeight,
        child: RotatedBox(
          quarterTurns: 1,
          child: _buildFittedImage(
            item,
            imageWidth: imageHeight,
            imageHeight: imageWidth,
          ),
        ),
      );
    }
    return _buildFittedImage(
      item,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  Widget _buildFittedImage(
    DraggableItem item, {
    required double imageWidth,
    required double imageHeight,
  }) {
    if (item.imageUrl.endsWith('.svg')) {
      return SvgPicture.asset(
        item.imageUrl,
        width: imageWidth,
        height: imageHeight,
        fit: BoxFit.contain,
      );
    }
    return Image.asset(
      item.imageUrl,
      width: imageWidth,
      height: imageHeight,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.devices_other_rounded, color: Color(0xFF486581)),
    );
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

  IconData _getSlotIcon(String slotId) {
    if (slotId.contains('cpu') || slotId.contains('processor')) {
      return Icons.memory_rounded;
    }
    if (slotId.contains('ram') || slotId.contains('storage')) {
      return Icons.storage_rounded;
    }
    if (slotId.contains('power') || slotId.contains('psu')) {
      return Icons.power_rounded;
    }
    if (slotId.contains('router') ||
        slotId.contains('switch') ||
        slotId.contains('network') ||
        slotId.contains('gateway') ||
        slotId.contains('dns')) {
      return Icons.lan_outlined;
    }
    if (slotId.contains('pin') || slotId.contains('cable')) {
      return Icons.cable_rounded;
    }
    if (slotId.contains('install') ||
        slotId.contains('config') ||
        slotId.contains('stage')) {
      return Icons.build_circle_outlined;
    }
    if (slotId.contains('check') || slotId.contains('test')) {
      return Icons.troubleshoot_rounded;
    }
    return Icons.add_circle_outline_rounded;
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
