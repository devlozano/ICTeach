import 'dart:async';
import 'dart:math';

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
  bool _preflightComplete = false;
  final Set<int> _safetyChecks = <int>{};
  Timer? _missionTimer;
  int _elapsedSeconds = 0;
  String? _focusedItemId;
  final TransformationController _cableZoomController =
      TransformationController();
  double _cableZoom = 1;
  int _identificationConfidence = 2;
  bool _osPreflightComplete = false;
  final Set<int> _osReadinessChecks = <int>{};
  String? _selectedResource;
  final FlutterTts _tts = FlutterTts();
  final Random _shuffleRandom = Random();

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
    _missionTimer?.cancel();
    _cableZoomController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _resetSimulation({bool notify = true}) {
    _placements = <String, String>{};
    final shuffledItems = [...widget.simulation.items]..shuffle(_shuffleRandom);
    _availableItems = shuffledItems.map((item) => item.id).toList();
    _availableSlots = widget.simulation.slots.toList();
    _isComplete = false;
    _mistakes = 0;
    _streak = 0;
    _xp = 0;
    _elapsedSeconds = 0;
    _focusedItemId = null;
    _selectedResource = null;

    _missionTimer?.cancel();
    final waitingForAssemblyCheck =
        widget.simulation.id == 'sim_coc1_assembly' && !_preflightComplete;
    final waitingForOsCheck =
        widget.simulation.id == 'sim_coc1_os_install' && !_osPreflightComplete;
    if (!waitingForAssemblyCheck && !waitingForOsCheck) {
      _preflightComplete = true;
      _startTimer();
    }

    if (notify && mounted) {
      _speak('Mission reset. Try to build a perfect streak.');
      setState(() {});
    }
  }

  void _startTimer() {
    _missionTimer?.cancel();
    _missionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isComplete) setState(() => _elapsedSeconds++);
    });
  }

  void _beginAssembly() {
    if (_safetyChecks.length != 3) return;
    setState(() => _preflightComplete = true);
    _startTimer();
    _speak('Safety check complete. Begin with the motherboard.');
  }

  void _beginOsInstallation() {
    if (_osReadinessChecks.length != 3) return;
    setState(() => _osPreflightComplete = true);
    _startTimer();
    _speak('Readiness confirmed. Begin with requirements and backup.');
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
    final profile = _resourceProfile(item);

    if (_selectedResource != profile.$1) {
      setState(() {
        _mistakes++;
        _streak = 0;
        _xp = (_xp - 2).clamp(0, 9999);
      });
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF9A3412),
            duration: const Duration(seconds: 4),
            content: Text(
              'Resource check failed for ${item.name}. Required: ${profile.$1}. Fastener/control: ${profile.$2}.',
            ),
          ),
        );
      return;
    }

    if (widget.simulation.type != 'identification' &&
        widget.simulation.type != 'networking' &&
        item.step > 0 &&
        item.step != _nextAssemblyStep) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      _speak('Complete step $_nextAssemblyStep first.');
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
      final feedback = _compatibilityFeedback(item, slotId);
      setState(() {
        _mistakes++;
        _streak = 0;
        final penalty = widget.simulation.type == 'identification'
            ? _identificationConfidence * 2
            : 2;
        _xp = (_xp - penalty).clamp(0, 9999);
      });
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      _speak(feedback);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.close_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.name} is incompatible with ${_slotName(slotId)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(feedback, style: const TextStyle(fontSize: 12)),
                      if (item.specification.isNotEmpty)
                        Text(
                          item.specification,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFB42318),
            duration: const Duration(seconds: 4),
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
      _selectedResource = null;
      _streak++;
      _xp += widget.simulation.type == 'identification'
          ? 6 + (_identificationConfidence * 3) + (_streak > 1 ? 2 : 0)
          : 10 + (_streak > 1 ? 2 : 0);
    });

    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
    _speak(
      _streak > 1
          ? 'Correct. $_streak move streak.'
          : 'Correct. ${item.name} placed.',
    );
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF047857),
          duration: const Duration(seconds: 3),
          content: Text('Verified: ${profile.$3}'),
        ),
      );

    if (_requiredItems.every((item) => _placements.containsKey(item.id))) {
      _calculateScore();
    }
  }

  (String, String, String) _resourceProfile(sim_models.DraggableItem item) {
    if (widget.simulation.id == 'sim_coc2_crimping') {
      return (
        'RJ45 crimper + cable stripper',
        'T568B pin ${item.step} channel',
        '${item.name} is straight, fully inserted to the plug face, and remains in the required T568B order before crimping.',
      );
    }
    switch (item.id) {
      case 'motherboard':
        return (
          'Phillips #2 + ESD strap',
          'Brass standoffs + M3 screws',
          'Every board hole sits on a matching standoff; screws are snug in a cross pattern with no extra standoff underneath.',
        );
      case 'cpu':
        return (
          'ESD strap + socket retention arm',
          'Socket load plate and retention lever',
          'The corner triangle and socket keys align; the CPU lies flat without force before the retention arm is locked.',
        );
      case 'cpu_fan':
        return (
          'Thermal paste + Phillips #2',
          'Cooler screws/push-pins in cross pattern',
          'Paste coverage is appropriate, cooler pressure is even, every fastener is locked, and CPU_FAN is connected.',
        );
      case 'ram':
        return (
          'Hands + DIMM latches',
          'Both slot retaining clips',
          'The DDR4 notch aligns, the module is evenly seated, both latches clamp fully, and no gold contacts remain exposed.',
        );
      case 'ram_ddr5_distractor':
        return (
          'Compatibility chart',
          'Do not force incompatible memory',
          'DDR generation, notch position, voltage, and motherboard support are confirmed before insertion.',
        );
      case 'gpu':
        return (
          'Phillips #2 + ESD strap',
          'PCIe retention latch + bracket screws',
          'The card is fully seated in PCIe x16, the latch is engaged, and the bracket is secured without chassis strain.',
        );
      case 'ssd':
        return (
          'Phillips #1 screwdriver',
          'M3 SSD screws',
          'The drive is level, secured with the correct short screws, and its connectors remain accessible.',
        );
      case 'psu':
        return (
          'Phillips #2 screwdriver',
          'Four 6-32 PSU chassis screws',
          'The PSU fan faces ventilation, all four rear screws are snug, and no cable is pinched.',
        );
      case 'assembly_test':
        return (
          'POST checklist + flashlight',
          'Final fastener and clearance inspection',
          'No loose screws remain; fans spin freely; POST completes; CPU, RAM, GPU, and storage are detected.',
        );
    }
    if (item.category == 'cable') {
      return (
        'Connector key + latch inspection',
        'Keyed plug fully seated; never forced',
        'Pin count, key shape, label, latch, polarity, routing, and strain relief all match the destination.',
      );
    }
    if (item.category == 'identification') {
      return (
        'ESD-safe magnifier',
        'Handle only by edges',
        'Classification is supported by observable form factor, contacts, sockets, ports, and component markings.',
      );
    }
    if (item.category == 'network') {
      return (
        'Network diagram + cable tester',
        'Correct port, address, or topology role',
        'Physical link, addressing, gateway, service reachability, and documentation are verified.',
      );
    }
    if (item.category == 'diagnostic') {
      return (
        'Diagnostic toolkit + service checklist',
        'Use approved test instrument/procedure',
        'Evidence is recorded, one variable is changed at a time, the repair is retested, and the result is documented.',
      );
    }
    return (
      'Manufacturer manual + job checklist',
      'Follow the approved procedure and controls',
      'The action meets client requirements, OHS guidance, manufacturer instructions, testing, and documentation requirements.',
    );
  }

  String _compatibilityFeedback(sim_models.DraggableItem item, String slotId) {
    if (item.id.contains('ddr5') && slotId == 'ram_slot') {
      return 'DDR5 cannot be installed in this DDR4 slot. Both use 288 pins, but the notch position, voltage, and electrical layout differ.';
    }
    if (item.id == 'gpu_power' && slotId == 'cpu_power_slot') {
      return 'A PCIe 6+2 plug is wired for a GPU. The CPU header requires an EPS12V 4+4 plug; forcing it can damage the board.';
    }
    if (item.id == 'cpu_power' && slotId == 'gpu_power_slot') {
      return 'This EPS12V 4+4 connector powers the CPU, not the GPU. Check the key shapes and cable label.';
    }
    if (item.id == 'sata_power_distractor' && slotId == 'sata_slot') {
      return 'This is the wider 15-pin SATA power plug. The motherboard port accepts the narrower 7-pin SATA data connector.';
    }
    if (item.id == 'power_cable') {
      return 'The 24-pin ATX connector only fits the motherboard main-power header. Match the long keyed socket and locking tab.';
    }
    if (widget.simulation.id == 'sim_coc2_crimping') {
      return '${item.name} does not match ${_slotName(slotId)} in the T568B color sequence.';
    }
    if (widget.simulation.id == 'sim_coc2_ipconfig') {
      return '${item.name} is assigned to another device. Check the host address and avoid duplicate IP assignments.';
    }
    if (widget.simulation.type == 'procedure') {
      return 'This action is out of sequence for ${_slotName(slotId)}. Follow the technical workflow one stage at a time.';
    }
    return '${item.name} does not match ${_slotName(slotId)}. ${item.tooltip}';
  }

  String _slotName(String slotId) {
    const names = <String, String>{
      'motherboard_tray': 'the motherboard tray',
      'cpu_socket': 'the CPU socket',
      'cpu_fan_mount': 'the cooler mount',
      'ram_slot': 'the DDR4 memory slot',
      'pcie_slot': 'the PCIe x16 slot',
      'storage_bay': 'the storage bay',
      'psu_mount': 'the PSU mount',
      'power_slot': 'the 24-pin ATX header',
      'cpu_power_slot': 'the 8-pin EPS12V CPU header',
      'gpu_power_slot': 'the GPU PCIe power socket',
      'sata_slot': 'the 7-pin SATA data port',
      'front_panel_slot': 'the front-panel header',
    };
    if (slotId.startsWith('pin')) {
      return 'RJ45 ${slotId.replaceFirst('pin', 'pin ')}';
    }
    return names[slotId] ?? slotId.replaceAll('_', ' ');
  }

  int get _nextAssemblyStep => _placements.length + 1;

  List<sim_models.DraggableItem> get _requiredItems =>
      widget.simulation.items.where((item) => item.isRequired).toList();

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
    final total = _requiredItems.length;

    for (final item in _requiredItems) {
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
    _missionTimer?.cancel();

    if (passed) {
      SystemSound.play(SystemSoundType.click);
      _speak(
        'Mission complete. Excellent work. You earned $_xp experience points.',
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
                    ? 'Mission cleared with $_xp XP and $_mistakes mistakes.'
                    : 'Mission score: $correct of $total. Mistakes: $_mistakes.',
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
    final incorrect = _requiredItems.where(
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
    if (widget.simulation.id == 'sim_coc1_assembly' && !_preflightComplete) {
      return _buildPreflight();
    }
    if (widget.simulation.id == 'sim_coc1_os_install' &&
        !_osPreflightComplete) {
      return _buildOsPreflight();
    }
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

  Widget _buildPreflight() {
    const checks = [
      (
        Icons.power_off_rounded,
        'Disconnect power',
        'PSU switch off and cable removed',
      ),
      (
        Icons.health_and_safety_outlined,
        'Use ESD protection',
        'Wear a grounded anti-static strap',
      ),
      (
        Icons.handyman_outlined,
        'Prepare the bench',
        'Clear screws, tools, and packaging',
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF101A24),
        borderRadius: BorderRadius.circular(18),
        image: const DecorationImage(
          image: AssetImage(
            'assets/simulations/pc-case-workbench-realistic.png',
          ),
          fit: BoxFit.cover,
          opacity: .22,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFF38BDF8), size: 38),
          const SizedBox(height: 12),
          const Text(
            'WORKSHOP PRE-FLIGHT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'A real technician makes the workstation safe before touching hardware.',
            style: TextStyle(color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < checks.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: _safetyChecks.contains(i),
                onChanged: (value) => setState(
                  () => value == true
                      ? _safetyChecks.add(i)
                      : _safetyChecks.remove(i),
                ),
                secondary: Icon(checks[i].$1, color: Colors.white),
                title: Text(
                  checks[i].$2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  checks[i].$3,
                  style: const TextStyle(color: Color(0xFF94A3B8)),
                ),
                activeColor: const Color(0xFF0EA5E9),
                checkColor: Colors.white,
                tileColor: Colors.black38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _safetyChecks.length == checks.length
                  ? _beginAssembly
                  : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                _safetyChecks.length == checks.length
                    ? 'Enter assembly bay'
                    : 'Complete all safety checks',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOsPreflight() {
    const checks = [
      (
        Icons.backup_outlined,
        'Backup verified',
        'Required user files open correctly from the backup destination',
      ),
      (
        Icons.usb_rounded,
        'Installer verified',
        'Approved ISO checksum and bootable USB have been confirmed',
      ),
      (
        Icons.power_outlined,
        'Deployment ready',
        'Hardware requirements, license, network, and stable power are ready',
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF071A33), Color(0xFF123E70)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                color: Color(0xFF7DD3FC),
                size: 32,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEPLOYMENT READINESS GATE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    Text(
                      'A clean installation can erase data. Confirm every control before continuing.',
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < checks.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: CheckboxListTile(
                value: _osReadinessChecks.contains(index),
                onChanged: (checked) => setState(
                  () => checked == true
                      ? _osReadinessChecks.add(index)
                      : _osReadinessChecks.remove(index),
                ),
                secondary: Icon(checks[index].$1, color: Colors.white),
                title: Text(
                  checks[index].$2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  checks[index].$3,
                  style: const TextStyle(
                    color: Color(0xFFB6C8DA),
                    fontSize: 11,
                  ),
                ),
                activeColor: const Color(0xFF0284C7),
                checkColor: Colors.white,
                tileColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _osReadinessChecks.length == checks.length
                  ? _beginOsInstallation
                  : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                _osReadinessChecks.length == checks.length
                    ? 'Start controlled installation'
                    : 'Complete all readiness checks',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final progress = _requiredItems.isEmpty
        ? 0.0
        : _placements.length / _requiredItems.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF254B6D)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.precision_manufacturing_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.simulation.competency}  •  PRACTICAL ACTIVITY',
                  style: const TextStyle(
                    color: Color(0xFFB8C8D8),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Progress ${_placements.length}/${_requiredItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Color(0xFF7DD3FC),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (widget.simulation.type == 'assembly' ||
              widget.simulation.type == 'procedure' ||
              widget.simulation.type == 'cabling')
            _hudChip(
              Icons.format_list_numbered_rounded,
              'Step $_nextAssemblyStep',
            ),
          const SizedBox(width: 4),
          _hudChip(
            Icons.stars_outlined,
            '$_xp XP',
            accent: const Color(0xFFBAE6FD),
          ),
          const SizedBox(width: 4),
          _hudChip(Icons.timer_outlined, _formattedElapsed),
          const SizedBox(width: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
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
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  String get _formattedElapsed {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _hudChip(IconData icon, String text, {Color accent = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: accent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartsPanel(double panelHeight) {
    final resources = widget.simulation.items
        .map((item) => _resourceProfile(item).$1)
        .toSet()
        .toList();
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
          Row(
            children: [
              Icon(
                widget.simulation.type == 'identification'
                    ? Icons.sell_outlined
                    : Icons.inventory_2_outlined,
                size: 18,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.simulation.type == 'identification'
                      ? 'EVIDENCE LABELS'
                      : 'COMPONENTS',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 14),
          Container(
            height: 58,
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: AssetImage(
                  'assets/simulations/technician-tool-tray-realistic.png',
                ),
                fit: BoxFit.cover,
                opacity: .18,
              ),
              color: const Color(0xFFEEF6FF),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: DropdownButtonFormField<String>(
              key: ValueKey(_selectedResource),
              initialValue: _selectedResource,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'SELECT TOOL / CONTROL',
                labelStyle: TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
                prefixIcon: Icon(Icons.handyman_outlined, size: 16),
                prefixIconConstraints: BoxConstraints(minWidth: 27),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                color: Color(0xFF102A43),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
              items: [
                for (final resource in resources)
                  DropdownMenuItem(
                    value: resource,
                    child: Text(
                      resource,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _selectedResource = value),
            ),
          ),
          const SizedBox(height: 6),
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
                : ListView.separated(
                    itemCount: _availableItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) => DraggableItemWidget(
                      item: widget.simulation.items.firstWhere(
                        (item) => item.id == _availableItems[index],
                      ),
                      isComplete: _isComplete,
                      compact: true,
                      labelOnly:
                          widget.simulation.type == 'identification' ||
                          widget.simulation.id == 'sim_coc1_os_install',
                      isFocused: _focusedItemId == _availableItems[index],
                      onInspect: () => setState(
                        () => _focusedItemId = _availableItems[index],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentPanel(double panelHeight) {
    final progress = _requiredItems.isEmpty
        ? 0
        : (_placements.length / _requiredItems.length * 100).round();
    final nextItem = _availableItems.isEmpty
        ? null
        : (_itemForStep(_nextAssemblyStep) ??
              widget.simulation.items.firstWhere(
                (item) => item.id == _availableItems.first,
              ));
    final inspectedItem = _focusedItemId == null
        ? null
        : widget.simulation.items
              .where((item) => item.id == _focusedItemId)
              .firstOrNull;
    final guidanceItem = inspectedItem ?? nextItem;
    final guidanceResource = guidanceItem == null
        ? null
        : _resourceProfile(guidanceItem);
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
                    '${_placements.length}/${_requiredItems.length}',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (inspectedItem != null)
                    Text(
                      inspectedItem.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  Text(
                    (inspectedItem ?? nextItem)?.tooltip.isNotEmpty == true
                        ? (inspectedItem ?? nextItem)!.tooltip
                        : 'Tap a component to inspect it, then drag it to the highlighted installation zone.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Color(0xFF334E68),
                    ),
                  ),
                  if ((inspectedItem ?? nextItem)?.specification.isNotEmpty ==
                      true) ...[
                    const SizedBox(height: 4),
                    Text(
                      (inspectedItem ?? nextItem)!.specification,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                  if (guidanceResource != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'RESOURCE  ${guidanceResource.$1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    Text(
                      'CONTROL  ${guidanceResource.$2}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (widget.simulation.type == 'identification') ...[
            const SizedBox(height: 6),
            _buildConfidencePanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidencePanel() {
    return _technicalPanel(
      title: 'CLAIM CONFIDENCE',
      icon: Icons.psychology_alt_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Higher confidence earns more XP, but a wrong classification costs more.',
            style: TextStyle(fontSize: 9, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var level = 1; level <= 3; level++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: level < 3 ? 4 : 0),
                    child: ChoiceChip(
                      label: Text(const ['LOW', 'MED', 'HIGH'][level - 1]),
                      selected: _identificationConfidence == level,
                      onSelected: (_) =>
                          setState(() => _identificationConfidence = level),
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
    final isCableLab = widget.simulation.id == 'sim_coc1_cabling';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = activityHeight;
        final scene = Stack(
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
                isCableLab
                    ? 'CABLE PORT LAB • PIN & KEY INSPECTION'
                    : widget.simulation.type == 'identification'
                    ? 'HARDWARE FORENSICS • SPECIMEN CLASSIFICATION'
                    : isAssembly
                    ? 'PC ASSEMBLY WORKBENCH'
                    : 'TECHNICAL LAB WORKBENCH',
              ),
            ),
            ...widget.simulation.slots.where(_shouldDisplaySlot).map((slotId) {
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
                  canAccept: (itemId) =>
                      widget.simulation.items
                          .firstWhere((candidate) => candidate.id == itemId)
                          .correctSlot ==
                      slotId,
                  specimenItem: widget.simulation.type == 'identification'
                      ? widget.simulation.items.firstWhere(
                          (candidate) => candidate.correctSlot == slotId,
                        )
                      : null,
                  onInspectSpecimen: widget.simulation.type == 'identification'
                      ? () => _showSpecimenInspection(slotId)
                      : null,
                  workflowMode: widget.simulation.id == 'sim_coc1_os_install',
                  width: targetSize.width,
                  height: targetSize.height,
                  immersive:
                      widget.simulation.id == 'sim_coc1_assembly' ||
                      isCableLab ||
                      widget.simulation.competency == 'COC2',
                ),
              );
            }),
          ],
        );

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
          child: isCableLab
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        transformationController: _cableZoomController,
                        minScale: 1,
                        maxScale: 3.5,
                        boundaryMargin: const EdgeInsets.all(160),
                        onInteractionUpdate: (_) {
                          final zoom = _cableZoomController.value
                              .getMaxScaleOnAxis();
                          if ((zoom - _cableZoom).abs() > .02) {
                            setState(() => _cableZoom = zoom);
                          }
                        },
                        child: scene,
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: _buildCableZoomControls(),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: _benchLabel(
                        'SCROLL / PINCH TO ZOOM • DRAG EMPTY SPACE TO PAN',
                      ),
                    ),
                  ],
                )
              : scene,
        );
      },
    );
  }

  void _showSpecimenInspection(String slotId) {
    final specimen = widget.simulation.items.firstWhere(
      (item) => item.correctSlot == slotId,
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.biotech_outlined,
                      color: Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'MAGNIFIED SPECIMEN ANALYSIS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                Container(
                  height: 230,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.asset(specimen.imageUrl, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'OBSERVABLE EVIDENCE',
                  style: TextStyle(
                    color: Color(0xFF7DD3FC),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  specimen.tooltip,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    height: 1.35,
                  ),
                ),
                if (specimen.specification.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    specimen.specification,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                const Text(
                  'Pinch or scroll to inspect contacts, connectors, chips, and form factor. Close this view, set your confidence, then classify the specimen.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCableZoomControls() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xE6111C27),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Zoom out',
            visualDensity: VisualDensity.compact,
            onPressed: () => _setCableZoom(_cableZoom - .35),
            icon: const Icon(Icons.remove, color: Colors.white),
          ),
          Text(
            '${(_cableZoom * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            tooltip: 'Zoom in',
            visualDensity: VisualDensity.compact,
            onPressed: () => _setCableZoom(_cableZoom + .35),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Reset view',
            visualDensity: VisualDensity.compact,
            onPressed: () => _setCableZoom(1),
            icon: const Icon(Icons.center_focus_strong, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _setCableZoom(double value) {
    final zoom = value.clamp(1.0, 3.5);
    setState(() => _cableZoom = zoom);
    _cableZoomController.value = Matrix4.diagonal3Values(zoom, zoom, 1);
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
    if (!_requiredItems.any((item) => item.correctSlot == slotId)) return false;
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
    if (widget.simulation.id == 'sim_coc1_os_install') {
      return Size(
        (benchWidth * .43).clamp(120.0, 300.0),
        (benchHeight * .13).clamp(48.0, 62.0),
      );
    }
    if (widget.simulation.id == 'sim_coc1_software_config') {
      return Size(
        (benchWidth * .25).clamp(115.0, 220.0),
        (benchHeight * .23).clamp(88.0, 145.0),
      );
    }
    if (widget.simulation.id == 'sim_coc2_crimping') {
      return Size(
        (benchWidth * .45).clamp(180.0, 420.0),
        (benchHeight * .032).clamp(13.0, 20.0),
      );
    }
    if (widget.simulation.id == 'sim_coc2_topology' ||
        widget.simulation.id == 'sim_coc2_ipconfig' ||
        widget.simulation.id == 'sim_coc2_diagnostics') {
      return Size(
        (benchWidth * .22).clamp(100.0, 210.0),
        (benchHeight * .25).clamp(82.0, 150.0),
      );
    }
    switch (slotId) {
      case 'motherboard_tray':
        // The matched ATX board is rendered in the same upright, top-down
        // orientation as the case. Keep its real proportions so the CPU,
        // DIMM and PCIe layers land over the sockets drawn on the board.
        return Size(
          (benchWidth * .36).clamp(150.0, 310.0),
          (benchHeight * .58).clamp(210.0, 360.0),
        );
      case 'cpu_target':
      case 'ram_target':
      case 'gpu_target':
      case 'motherboard_target':
      case 'storage_target':
      case 'psu_target':
        return Size(benchWidth * .27, benchHeight * .34);
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
    if (widget.simulation.id == 'sim_coc1_os_install') {
      final index = widget.simulation.slots.indexOf(slotId);
      final column = index % 2;
      final row = index ~/ 2;
      final raw = Offset(
        width * (column == 0 ? .05 : .52),
        height * (.14 + row * .17),
      );
      return _safeTargetPosition(raw, width, height, targetSize);
    }
    if (widget.simulation.id == 'sim_coc1_software_config') {
      final index = widget.simulation.slots.indexOf(slotId).clamp(0, 5);
      final column = index % 3;
      final row = index ~/ 3;
      final raw = Offset(
        width * (.08 + column * .31),
        height * (.43 + row * .28),
      );
      return _safeTargetPosition(raw, width, height, targetSize);
    }
    if (widget.simulation.id == 'sim_coc2_crimping') {
      final pin = int.tryParse(slotId.replaceFirst('pin', '')) ?? 1;
      final raw = Offset(width * .275, height * (.395 + (pin - 1) * .022));
      return _safeTargetPosition(raw, width, height, targetSize);
    }
    if (widget.simulation.id == 'sim_coc2_topology') {
      final raw =
          <String, Offset>{
            'modem_position': Offset(width * .14, height * .19),
            'router_position': Offset(width * .42, height * .19),
            'switch_position': Offset(width * .69, height * .19),
            'pc_position': Offset(width * .14, height * .56),
            'server_position': Offset(width * .42, height * .56),
            'printer_position': Offset(width * .69, height * .56),
          }[slotId] ??
          Offset(width * .14, height * .19);
      return _safeTargetPosition(raw, width, height, targetSize);
    }
    if (widget.simulation.id == 'sim_coc2_ipconfig') {
      final raw =
          <String, Offset>{
            'pc1_ip': Offset(width * .14, height * .19),
            'pc2_ip': Offset(width * .42, height * .19),
            'pc3_ip': Offset(width * .69, height * .19),
            'server_ip': Offset(width * .14, height * .56),
            'router_ip': Offset(width * .42, height * .56),
          }[slotId] ??
          Offset(width * .14, height * .19);
      return _safeTargetPosition(raw, width, height, targetSize);
    }
    if (widget.simulation.id == 'sim_coc2_diagnostics') {
      final index = widget.simulation.slots.indexOf(slotId).clamp(0, 5);
      final column = index % 3;
      final row = index ~/ 3;
      final raw = Offset(
        width * (.14 + column * .275),
        height * (.19 + row * .37),
      );
      return _safeTargetPosition(raw, width, height, targetSize);
    }
    final positions = <String, Offset>{
      'motherboard_tray': Offset(width * 0.22, height * 0.16),
      'cpu_socket': Offset(width * 0.35, height * 0.30),
      'cpu_fan_mount': Offset(width * 0.33, height * 0.26),
      'ram_slot': Offset(width * 0.53, height * 0.20),
      'pcie_slot': Offset(width * 0.24, height * 0.58),
      'storage_bay': Offset(width * 0.72, height * 0.50),
      'psu_mount': Offset(width * 0.13, height * 0.76),
      'power_slot': Offset(width * 0.48, height * 0.24),
      'cpu_power_slot': Offset(width * 0.25, height * 0.11),
      'gpu_power_slot': Offset(width * 0.42, height * 0.48),
      'sata_slot': Offset(width * 0.54, height * 0.61),
      'front_panel_slot': Offset(width * 0.38, height * 0.66),
      'cpu_target': Offset(width * .05, height * .17),
      'ram_target': Offset(width * .365, height * .17),
      'gpu_target': Offset(width * .68, height * .17),
      'motherboard_target': Offset(width * .05, height * .56),
      'storage_target': Offset(width * .365, height * .56),
      'psu_target': Offset(width * .68, height * .56),
    };

    final raw = positions[slotId] ?? _genericPosition(slotId, width, height);
    return _safeTargetPosition(raw, width, height, targetSize);
  }

  Offset _safeTargetPosition(
    Offset raw,
    double width,
    double height,
    Size targetSize,
  ) {
    double safeAxis(double value, double extent, double childExtent) {
      final available = extent - childExtent;
      if (available <= 0) return 0;
      if (available < 8) return available / 2;
      return value.clamp(4.0, available - 4.0).toDouble();
    }

    return Offset(
      safeAxis(raw.dx, width, targetSize.width),
      safeAxis(raw.dy, height, targetSize.height),
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
    if (widget.simulation.type == 'identification') {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF07111F), Color(0xFF0F2740), Color(0xFF07111F)],
          ),
        ),
        child: CustomPaint(painter: _EvidenceGridPainter()),
      );
    }
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
        return 'assets/simulations/pc-case-workbench-realistic.png';
      case 'sim_coc1_cabling':
        return 'assets/simulations/cable-management-workbench.png';
      case 'sim_coc1_identification':
        return 'assets/simulations/lab-kit.svg';
      case 'sim_coc1_os_install':
        return 'assets/simulations/laptop.svg';
      case 'sim_coc1_software_config':
        return 'assets/simulations/software-config-workbench-matched.png';
      case 'sim_coc1_maintenance':
        return 'assets/simulations/steps.svg';
      case 'sim_coc1_repair':
        return 'assets/simulations/support.svg';
      case 'sim_coc2_topology':
      case 'sim_coc2_ipconfig':
      case 'sim_coc2_diagnostics':
        return 'assets/simulations/coc2-network-lab-matched.png';
      case 'sim_coc2_crimping':
        return 'assets/simulations/coc2-rj45-workbench-matched.png';
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

class _EvidenceGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fine = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: .07)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), fine);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), fine);
    }
    final crosshair = Paint()
      ..color = const Color(0xFF7DD3FC).withValues(alpha: .16)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width / 2 - 22, size.height / 2),
      Offset(size.width / 2 + 22, size.height / 2),
      crosshair,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2 - 22),
      Offset(size.width / 2, size.height / 2 + 22),
      crosshair,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
