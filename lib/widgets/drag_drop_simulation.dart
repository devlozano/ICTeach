import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  int _mistakes = 0;
  int _streak = 0;
  int _xp = 0;
  bool _voiceEnabled = true;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _resetSimulation(notify: false);
    _configureVoice();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speak('Mission started. Drag each pictured part to the correct target.');
    });
  }

  Future<void> _configureVoice() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1.0);
    await _tts.setVolume(0.9);
  }

  Future<void> _speak(String message) async {
    if (!_voiceEnabled) return;
    await _tts.stop();
    await _tts.speak(message);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _resetSimulation({bool notify = true}) {
    _placements = <String, String>{};
    final orderedItems = [...widget.simulation.items]
      ..sort((a, b) {
        if (a.step == 0 && b.step == 0) return 0;
        if (a.step == 0) return 1;
        if (b.step == 0) return -1;
        return a.step.compareTo(b.step);
      });
    _availableItems = orderedItems.map((item) => item.id).toList();
    _availableSlots = widget.simulation.slots.toList();
    _isComplete = false;
    _mistakes = 0;
    _streak = 0;
    _xp = 0;

    if (notify && mounted) {
      _speak('Mission reset. Try to build a perfect streak.');
      setState(() {});
    }
  }

  void _handleDrop(String itemId, String slotId) {
    if (_isComplete ||
        !_availableItems.contains(itemId) ||
        !_availableSlots.contains(slotId)) {
      return;
    }

    final item = widget.simulation.items.firstWhere(
      (simulationItem) => simulationItem.id == itemId,
    );

    if (item.step > 0 && item.step != _nextAssemblyStep) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      _speak('Complete step  first.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Install step $_nextAssemblyStep first: '
            '${_itemForStep(_nextAssemblyStep)?.name ?? 'the next component'}.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (item.correctSlot != slotId) {
      setState(() {
        _mistakes++;
        _streak = 0;
        _xp = (_xp - 2).clamp(0, 9999);
      });
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      _speak('Not quite. ${item.name} belongs in a different target.');
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.close_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Wrong target for ${item.name}. Try again.'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFB42318),
            duration: const Duration(milliseconds: 1400),
          ),
        );
      return;
    }

    setState(() {
      final existingItemId = _placements.entries
          .where((entry) => entry.value == slotId)
          .map((entry) => entry.key)
          .firstOrNull;

      if (existingItemId != null) {
        _placements.remove(existingItemId);

        if (!_availableItems.contains(existingItemId)) {
          _availableItems.add(existingItemId);
        }
      }

      _placements[itemId] = slotId;
      _availableItems.remove(itemId);
      _availableSlots.remove(slotId);
      _streak++;
      _xp += 10 + (_streak > 1 ? 2 : 0);
    });

    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
    _speak(
      _streak > 1
          ? 'Correct. $_streak move streak.'
          : 'Correct. ${item.name} placed.',
    );

    if (_placements.length == widget.simulation.items.length) {
      _calculateScore();
    }
  }

  int get _nextAssemblyStep => _placements.length + 1;

  sim_models.DraggableItem? _itemForStep(int step) {
    for (final item in widget.simulation.items) {
      if (item.step == step) {
        return item;
      }
    }

    return null;
  }

  void _calculateScore() {
    var correct = 0;
    final total = widget.simulation.items.length;

    for (final item in widget.simulation.items) {
      if (_placements[item.id] == item.correctSlot) {
        correct++;
      }
    }

    final scoredCorrect = (correct - _mistakes).clamp(0, total);
    final percentage = total == 0 ? 0 : (scoredCorrect / total * 100).round();
    final passed = percentage >= widget.simulation.passingScore;

    setState(() {
      _isComplete = true;
    });

    if (passed) {
      SystemSound.play(SystemSoundType.click);
      _speak(
        'Mission complete. Excellent work. You earned  experience points.',
      );
    } else {
      SystemSound.play(SystemSoundType.alert);
      _speak('Mission incomplete. Review the hints and try again.');
    }
    _showResultDialog(percentage, passed, scoredCorrect, total);

    widget.onComplete(scoredCorrect, total, passed);
  }

  void _showResultDialog(int percentage, bool passed, int correct, int total) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
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
                passed
                    ? 'Mission cleared with  XP and  mistakes.'
                    : 'Mission score: $correct of $total. Mistakes: .',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: passed ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: passed
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      passed ? Icons.thumb_up : Icons.emoji_events,
                      color: passed ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Score: $percentage% '
                        '(${widget.simulation.passingScore}% needed to pass)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: passed
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!passed) ...[
                const SizedBox(height: 8),
                Text(
                  _incorrectFeedback,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            if (passed)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Continue'),
              ),
            if (!passed)
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _resetSimulation();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Retry'),
              ),
          ],
        );
      },
    );
  }

  String get _incorrectFeedback {
    final incorrect = widget.simulation.items.where(
      (item) => _placements[item.id] != item.correctSlot,
    );
    return [
      'Review these errors before retrying:',
      for (final item in incorrect)
        '- ${item.name}: ${item.tooltip.isEmpty ? 'Check the correct target and sequence.' : item.tooltip}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inventoryWidth = constraints.maxWidth >= 1150
            ? 185.0
            : constraints.maxWidth >= 850
            ? 165.0
            : 140.0;
        final guidanceWidth = constraints.maxWidth >= 1150
            ? 210.0
            : constraints.maxWidth >= 850
            ? 185.0
            : 150.0;
        final availableActivityHeight = constraints.maxHeight - 122;
        final activityHeight = constraints.maxHeight.isFinite
            ? availableActivityHeight.clamp(210.0, 520.0)
            : 440.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBar(),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: inventoryWidth,
                  child: _buildPartsPanel(activityHeight),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildWorkbench(activityHeight)),
                const SizedBox(width: 8),
                SizedBox(
                  width: guidanceWidth,
                  child: _buildAssessmentPanel(activityHeight),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: Color(0xFF627487),
                ),
                const SizedBox(width: 6),
                Text(
                  'Required competency score: ${widget.simulation.passingScore}%',
                  style: const TextStyle(
                    color: Color(0xFF627487),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (!_isComplete)
                  OutlinedButton.icon(
                    onPressed: _resetSimulation,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Reset activity'),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBar() {
    final progress = widget.simulation.items.isEmpty
        ? 0.0
        : _placements.length / widget.simulation.items.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF254B6D)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.precision_manufacturing_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.simulation.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.simulation.competency}  •  PRACTICAL ACTIVITY',
                  style: const TextStyle(
                    color: Color(0xFFB8C8D8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Progress ${_placements.length}/${widget.simulation.items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Color(0xFF7DD3FC),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          if (widget.simulation.type == 'assembly')
            _hudChip(
              Icons.format_list_numbered_rounded,
              'Step $_nextAssemblyStep',
            ),
          const SizedBox(width: 7),
          _hudChip(
            Icons.stars_outlined,
            '$_xp XP',
            accent: const Color(0xFFBAE6FD),
          ),
          const SizedBox(width: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: _voiceEnabled
                ? 'Mute voice guidance'
                : 'Enable voice guidance',
            onPressed: () {
              setState(() => _voiceEnabled = !_voiceEnabled);
              if (_voiceEnabled) {
                SystemSound.play(SystemSoundType.click);
                _speak('Voice guidance enabled.');
              } else {
                _tts.stop();
              }
            },
            icon: Icon(
              _voiceEnabled
                  ? Icons.volume_up_outlined
                  : Icons.volume_off_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudChip(IconData icon, String text, {Color accent = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartsPanel(double panelHeight) {
    return Container(
      height: panelHeight,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFDCE3EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'COMPONENTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 14),
          Expanded(
            child: _availableItems.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          color: Colors.green,
                          size: 34,
                        ),
                        SizedBox(height: 7),
                        Text(
                          'All components installed',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      for (
                        var index = 0;
                        index < _availableItems.length;
                        index++
                      ) ...[
                        Expanded(
                          child: DraggableItemWidget(
                            item: widget.simulation.items.firstWhere(
                              (item) => item.id == _availableItems[index],
                            ),
                            isComplete: _isComplete,
                            compact: true,
                          ),
                        ),
                        if (index < _availableItems.length - 1)
                          const SizedBox(height: 4),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentPanel(double panelHeight) {
    final progress = widget.simulation.items.isEmpty
        ? 0
        : (_placements.length / widget.simulation.items.length * 100).round();
    final nextItem = _availableItems.isEmpty
        ? null
        : (_itemForStep(_nextAssemblyStep) ??
              widget.simulation.items.firstWhere(
                (item) => item.id == _availableItems.first,
              ));
    return SizedBox(
      height: panelHeight,
      child: Column(
        children: [
          Expanded(
            child: _technicalPanel(
              title: 'ACTIVITY STATUS',
              icon: Icons.monitor_heart_outlined,
              expandChild: true,
              child: GridView.count(
                crossAxisCount: 2,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                children: [
                  _metricTile(
                    'Installed',
                    '${_placements.length}/${widget.simulation.items.length}',
                    Icons.build_outlined,
                  ),
                  _metricTile(
                    'Progress',
                    '$progress%',
                    Icons.donut_large_rounded,
                  ),
                  _metricTile('Score', '$_xp XP', Icons.assessment_outlined),
                  _metricTile(
                    'Errors',
                    '$_mistakes',
                    Icons.error_outline_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (panelHeight >= 340) ...[
            const SizedBox(height: 6),
            _technicalPanel(
              title: 'TECHNICAL NOTE',
              icon: Icons.lightbulb_outline_rounded,
              child: Text(
                nextItem?.tooltip.isNotEmpty == true
                    ? nextItem!.tooltip
                    : 'Review the component image and target label before placing it.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: Color(0xFF334E68),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _technicalPanel({
    required String title,
    required IconData icon,
    required Widget child,
    bool expandChild = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xC7FFFFFF),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFDCE3EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: const Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43),
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 14),
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE3E9EF)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF486581)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF102A43),
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Color(0xFF627487)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkbench(double activityHeight) {
    final isAssembly = widget.simulation.type == 'assembly';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = activityHeight;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xff24282b),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xff4b5358), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildWorkbenchBackground(),
                ),
              ),
              Positioned(
                left: 14,
                top: 12,
                child: _benchLabel(
                  isAssembly
                      ? 'PC ASSEMBLY WORKBENCH'
                      : 'TECHNICAL LAB WORKBENCH',
                ),
              ),
              ...widget.simulation.slots.where(_shouldDisplaySlot).map((
                slotId,
              ) {
                final item = _placedItemFor(slotId);
                final targetSize = _targetSize(slotId, width, height);
                final position = _targetPosition(
                  slotId,
                  width,
                  height,
                  targetSize,
                );

                return Positioned(
                  left: position.dx,
                  top: position.dy,
                  child: DropTargetWidget(
                    slotId: slotId,
                    placedItem: item,
                    isComplete: _isComplete,
                    onDrop: _handleDrop,
                    width: targetSize.width,
                    height: targetSize.height,
                    immersive:
                        widget.simulation.id == 'sim_coc1_assembly' ||
                        widget.simulation.id == 'sim_coc1_cabling',
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  sim_models.DraggableItem? _placedItemFor(String slotId) {
    for (final entry in _placements.entries) {
      if (entry.value == slotId) {
        for (final item in widget.simulation.items) {
          if (item.id == entry.key) {
            return item;
          }
        }
      }
    }

    return null;
  }

  bool _shouldDisplaySlot(String slotId) {
    if (widget.simulation.id != 'sim_coc1_assembly') return true;

    switch (slotId) {
      case 'cpu_socket':
        return _placements.containsKey('motherboard') ||
            _placements.containsKey('cpu');
      case 'cpu_fan_mount':
        return _placements.containsKey('cpu') ||
            _placements.containsKey('cpu_fan');
      default:
        return true;
    }
  }

  Size _targetSize(String slotId, double benchWidth, double benchHeight) {
    switch (slotId) {
      case 'motherboard_tray':
        final motherboardWidth = (benchWidth * .43).clamp(145.0, 330.0);
        return Size(motherboardWidth, motherboardWidth * .75);
      case 'pcie_slot':
        return Size((benchWidth * .38).clamp(120.0, 260.0), benchHeight * .13);
      case 'psu_mount':
        return Size((benchWidth * .25).clamp(95.0, 180.0), benchHeight * .18);
      case 'ram_slot':
        return Size((benchWidth * .07).clamp(38.0, 58.0), benchHeight * .30);
      case 'cpu_socket':
        return Size.square((benchHeight * .13).clamp(48.0, 68.0));
      case 'cpu_fan_mount':
        return Size.square((benchHeight * .21).clamp(70.0, 108.0));
      case 'storage_bay':
        return Size(benchWidth * .13, benchHeight * .14);
      case 'power_slot':
        return Size(benchWidth * .22, benchHeight * .18);
      case 'cpu_power_slot':
        return Size(benchWidth * .18, benchHeight * .15);
      case 'gpu_power_slot':
        return Size(benchWidth * .22, benchHeight * .17);
      case 'sata_slot':
        return Size(benchWidth * .24, benchHeight * .18);
      case 'front_panel_slot':
        return Size(benchWidth * .22, benchHeight * .18);
      default:
        return Size((benchWidth * .22).clamp(80.0, 120.0), 82);
    }
  }

  Offset _targetPosition(
    String slotId,
    double width,
    double height,
    Size targetSize,
  ) {
    final positions = <String, Offset>{
      'motherboard_tray': Offset(width * 0.22, height * 0.19),
      'cpu_socket': Offset(width * 0.35, height * 0.34),
      'cpu_fan_mount': Offset(width * 0.33, height * 0.30),
      'ram_slot': Offset(width * 0.56, height * 0.25),
      'pcie_slot': Offset(width * 0.25, height * 0.62),
      'storage_bay': Offset(width * 0.72, height * 0.50),
      'psu_mount': Offset(width * 0.13, height * 0.76),
      'power_slot': Offset(width * 0.48, height * 0.24),
      'cpu_power_slot': Offset(width * 0.25, height * 0.11),
      'gpu_power_slot': Offset(width * 0.42, height * 0.48),
      'sata_slot': Offset(width * 0.54, height * 0.61),
      'front_panel_slot': Offset(width * 0.38, height * 0.66),
    };

    final raw = positions[slotId] ?? _genericPosition(slotId, width, height);
    final maxX = width - targetSize.width - 4;
    final maxY = height - targetSize.height - 4;
    return Offset(
      raw.dx.clamp(4.0, maxX < 4.0 ? 4.0 : maxX),
      raw.dy.clamp(4.0, maxY < 4.0 ? 4.0 : maxY),
    );
  }

  Offset _genericPosition(String slotId, double width, double height) {
    final index = widget.simulation.slots.indexOf(slotId);
    final columns = width < 520 ? 2 : 3;
    final cellWidth = (width - 28) / columns;

    return Offset(
      14 + (index % columns) * cellWidth,
      58 + (index ~/ columns) * 112.0,
    );
  }

  Widget _buildWorkbenchBackground() {
    final asset = _workbenchImage;
    if (asset.endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        fit: BoxFit.cover,
        colorFilter: const ColorFilter.mode(
          Color(0x18000000),
          BlendMode.darken,
        ),
        placeholderBuilder: (_) => Container(color: const Color(0xFF26323A)),
      );
    }
    return Image.asset(
      asset,
      fit: BoxFit.fill,
      color: Colors.black.withValues(alpha: 0.10),
      colorBlendMode: BlendMode.darken,
      errorBuilder: (_, _, _) => Container(color: const Color(0xFF26323A)),
    );
  }

  String get _workbenchImage {
    switch (widget.simulation.id) {
      case 'sim_coc1_assembly':
        return 'assets/simulations/empty-pc-case.png';
      case 'sim_coc1_cabling':
        return 'assets/simulations/cable-management-workbench.png';
      case 'sim_coc1_identification':
        return 'assets/simulations/lab-kit.svg';
      case 'sim_coc1_os_install':
      case 'sim_coc1_software_config':
        return 'assets/simulations/laptop.svg';
      case 'sim_coc1_maintenance':
        return 'assets/simulations/steps.svg';
      case 'sim_coc1_repair':
        return 'assets/simulations/support.svg';
      case 'sim_coc2_topology':
        return 'assets/simulations/classroom.svg';
      case 'sim_coc2_crimping':
        return 'assets/simulations/switch.jpg';
      case 'sim_coc2_ipconfig':
        return 'assets/simulations/router.jpg';
      case 'sim_coc2_diagnostics':
        return 'assets/simulations/device.svg';
      default:
        return 'assets/simulations/whiteboard.svg';
    }
  }

  Widget _benchLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
