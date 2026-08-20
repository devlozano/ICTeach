import '../models/simulation_model.dart';

class SimulationData {
  static DraggableItem _item({
    required String id,
    required String name,
    required String description,
    required String imageUrl,
    required String correctSlot,
    required String category,
    required int step,
    required String tooltip,
  }) => DraggableItem(
    id: id,
    name: name,
    description: description,
    imageUrl: imageUrl,
    correctSlot: correctSlot,
    category: category,
    step: step,
    tooltip: tooltip,
  );

  static Simulation _simulation({
    required String id,
    required String title,
    required String description,
    required String type,
    required String competency,
    required String learningOutcome,
    required List<DraggableItem> items,
    required int timeLimit,
    required String? requiredSimulationId,
  }) {
    final now = DateTime.now();
    return Simulation(
      id: id,
      title: title,
      description: description,
      type: type,
      competency: competency,
      learningOutcome: learningOutcome,
      items: items,
      slots: items.map((item) => item.correctSlot).toList(),
      timeLimit: timeLimit,
      passingScore: 80,
      isPublished: true,
      isLocked: false,
      requiredSimulationId: requiredSimulationId,
      createdAt: now,
      updatedAt: now,
    );
  }

  static Simulation getPcAssembly() => _simulation(
    id: 'sim_coc1_assembly',
    title: 'PC Assembly - COC1',
    description:
        'Assemble a computer system by placing components in the correct installation order.',
    type: 'assembly',
    competency: 'COC1',
    learningOutcome: 'LO1 - Assemble computer hardware',
    timeLimit: 15,
    requiredSimulationId: null,
    items: [
      _item(
        id: 'motherboard',
        name: 'Motherboard',
        description: 'Main circuit board - install first in the case',
        imageUrl: 'assets/simulations/motherboard.svg',
        correctSlot: 'motherboard_tray',
        category: 'motherboard',
        step: 1,
        tooltip: 'Install standoffs before mounting the motherboard.',
      ),
      _item(
        id: 'cpu',
        name: 'CPU',
        description: 'Central Processing Unit - align the gold triangle',
        imageUrl: 'assets/simulations/cpu.svg',
        correctSlot: 'cpu_socket',
        category: 'processor',
        step: 2,
        tooltip: 'Match the CPU triangle with the socket indicator.',
      ),
      _item(
        id: 'cpu_fan',
        name: 'CPU Cooler',
        description: 'Attach after CPU installation',
        imageUrl: 'assets/simulations/device.svg',
        correctSlot: 'cpu_fan_mount',
        category: 'cooling',
        step: 3,
        tooltip: 'Apply thermal paste before attaching the cooler.',
      ),
      _item(
        id: 'ram',
        name: 'RAM',
        description: 'Random Access Memory - align the notch',
        imageUrl: 'assets/simulations/ram.svg',
        correctSlot: 'ram_slot',
        category: 'memory',
        step: 4,
        tooltip: 'Press firmly until the clips click.',
      ),
      _item(
        id: 'gpu',
        name: 'GPU',
        description: 'Graphics card - install in the PCIe x16 slot',
        imageUrl: 'assets/simulations/gpu.svg',
        correctSlot: 'pcie_slot',
        category: 'graphics',
        step: 5,
        tooltip: 'Secure the bracket with screws.',
      ),
      _item(
        id: 'ssd',
        name: 'SSD Storage',
        description: 'Fast storage for the operating system and apps',
        imageUrl: 'assets/simulations/storage.svg',
        correctSlot: 'storage_bay',
        category: 'storage',
        step: 6,
        tooltip: 'Mount in the drive bay or M.2 slot.',
      ),
      _item(
        id: 'psu',
        name: 'Power Supply',
        description: 'Install last and connect all cables',
        imageUrl: 'assets/simulations/psu.svg',
        correctSlot: 'psu_mount',
        category: 'power',
        step: 7,
        tooltip: 'Face the fan toward the case ventilation.',
      ),
    ],
  );

  static Simulation getCableManagement() => _simulation(
    id: 'sim_coc1_cabling',
    title: 'Cable Management - COC1',
    description:
        'Connect each cable to its correct location for reliable power and airflow.',
    type: 'cabling',
    competency: 'COC1',
    learningOutcome: 'LO1 - Assemble computer hardware',
    timeLimit: 10,
    requiredSimulationId: 'sim_coc1_assembly',
    items: [
      _item(
        id: 'power_cable',
        name: '24-pin Motherboard Cable',
        description: 'Main motherboard power connector',
        imageUrl: 'assets/simulations/device.svg',
        correctSlot: 'power_slot',
        category: 'cable',
        step: 1,
        tooltip: 'The largest connector from the PSU.',
      ),
      _item(
        id: 'cpu_power',
        name: '4+4 pin CPU Cable',
        description: 'Provides power to the CPU',
        imageUrl: 'assets/simulations/cpu.svg',
        correctSlot: 'cpu_power_slot',
        category: 'cable',
        step: 2,
        tooltip: 'Connect near the CPU socket.',
      ),
      _item(
        id: 'gpu_power',
        name: '6+2 pin PCIe Cable',
        description: 'Provides power to the graphics card',
        imageUrl: 'assets/simulations/gpu.svg',
        correctSlot: 'gpu_power_slot',
        category: 'cable',
        step: 3,
        tooltip: 'High-end GPUs may require multiple cables.',
      ),
      _item(
        id: 'sata_cable',
        name: 'SATA Data Cable',
        description: 'Connects storage drives to the motherboard',
        imageUrl: 'assets/simulations/storage.svg',
        correctSlot: 'sata_slot',
        category: 'cable',
        step: 4,
        tooltip: 'The L-shaped connector fits one way.',
      ),
      _item(
        id: 'front_panel',
        name: 'Front Panel Connectors',
        description: 'Connects power, reset, and LED controls',
        imageUrl: 'assets/simulations/steps.svg',
        correctSlot: 'front_panel_slot',
        category: 'cable',
        step: 5,
        tooltip: 'Use the motherboard manual for the pin layout.',
      ),
    ],
  );

  static Simulation getHardwareIdentification() => _simulation(
    id: 'sim_coc1_identification',
    title: 'Hardware Identification - COC1',
    description:
        'Identify each computer component by placing its label on the correct target.',
    type: 'identification',
    competency: 'COC1',
    learningOutcome: 'LO1 - Identify computer parts',
    timeLimit: 8,
    requiredSimulationId: 'sim_coc1_assembly',
    items: [
      _item(
        id: 'cpu_label',
        name: 'CPU',
        description: 'The brain of the computer',
        imageUrl: 'assets/simulations/cpu.svg',
        correctSlot: 'cpu_target',
        category: 'identification',
        step: 1,
        tooltip: 'Processor with pins or contact pads.',
      ),
      _item(
        id: 'ram_label',
        name: 'RAM',
        description: 'Temporary memory for running programs',
        imageUrl: 'assets/simulations/ram.svg',
        correctSlot: 'ram_target',
        category: 'identification',
        step: 2,
        tooltip: 'A small stick with memory chips.',
      ),
      _item(
        id: 'gpu_label',
        name: 'GPU',
        description: 'Processes graphics and video output',
        imageUrl: 'assets/simulations/gpu.svg',
        correctSlot: 'gpu_target',
        category: 'identification',
        step: 3,
        tooltip: 'A card with fans and display ports.',
      ),
      _item(
        id: 'motherboard_label',
        name: 'Motherboard',
        description: 'Main circuit board connecting components',
        imageUrl: 'assets/simulations/motherboard.svg',
        correctSlot: 'motherboard_target',
        category: 'identification',
        step: 4,
        tooltip: 'Large board with many connectors.',
      ),
      _item(
        id: 'ssd_label',
        name: 'SSD',
        description: 'Fast storage for files and the operating system',
        imageUrl: 'assets/simulations/storage.svg',
        correctSlot: 'storage_target',
        category: 'identification',
        step: 5,
        tooltip: 'Small flat rectangular drive.',
      ),
      _item(
        id: 'psu_label',
        name: 'PSU',
        description: 'Converts AC power to DC power',
        imageUrl: 'assets/simulations/psu.svg',
        correctSlot: 'psu_target',
        category: 'identification',
        step: 6,
        tooltip: 'A box with a fan and cables.',
      ),
    ],
  );

  static Simulation getNetworkTopology() => _simulation(
    id: 'sim_coc2_topology',
    title: 'Network Topology - COC2',
    description:
        'Build a functional network by placing devices in their correct positions.',
    type: 'networking',
    competency: 'COC2',
    learningOutcome: 'LO1 - Install network cables',
    timeLimit: 12,
    requiredSimulationId: 'sim_coc1_identification',
    items: [
      _item(
        id: 'router',
        name: 'Router',
        description: 'Routes data between networks',
        imageUrl: 'assets/simulations/router.svg',
        correctSlot: 'router_position',
        category: 'network',
        step: 1,
        tooltip: 'Connects the local network to the ISP.',
      ),
      _item(
        id: 'switch',
        name: 'Network Switch',
        description: 'Connects devices in one network',
        imageUrl: 'assets/simulations/switch.svg',
        correctSlot: 'switch_position',
        category: 'network',
        step: 2,
        tooltip: 'Distributes connections to local devices.',
      ),
      _item(
        id: 'pc',
        name: 'Computer',
        description: 'End-user device on the network',
        imageUrl: 'assets/simulations/pc.svg',
        correctSlot: 'pc_position',
        category: 'network',
        step: 3,
        tooltip: 'A workstation or client device.',
      ),
      _item(
        id: 'server',
        name: 'Server',
        description: 'Provides services to network devices',
        imageUrl: 'assets/simulations/server.svg',
        correctSlot: 'server_position',
        category: 'network',
        step: 4,
        tooltip: 'Provides centralized resources.',
      ),
      _item(
        id: 'printer',
        name: 'Network Printer',
        description: 'Shared printing device',
        imageUrl: 'assets/simulations/device.svg',
        correctSlot: 'printer_position',
        category: 'network',
        step: 5,
        tooltip: 'Available to authorized network users.',
      ),
      _item(
        id: 'modem',
        name: 'Modem',
        description: 'Connects the network to the ISP',
        imageUrl: 'assets/simulations/router.svg',
        correctSlot: 'modem_position',
        category: 'network',
        step: 0,
        tooltip: 'The first device in the Internet connection chain.',
      ),
    ],
  );

  static Simulation getRj45Crimping() => _simulation(
    id: 'sim_coc2_crimping',
    title: 'RJ45 Cable Crimping - COC2',
    description:
        'Arrange the wires in the correct T568B order for a straight-through cable.',
    type: 'cabling',
    competency: 'COC2',
    learningOutcome: 'LO1 - Install network cables',
    timeLimit: 10,
    requiredSimulationId: 'sim_coc2_topology',
    items: List.generate(8, (index) {
      final pin = index + 1;
      const colors = [
        'White/Orange',
        'Orange',
        'White/Green',
        'Blue',
        'White/Blue',
        'Green',
        'White/Brown',
        'Brown',
      ];
      return _item(
        id: 'wire$pin',
        name: '${colors[index]} (Pin $pin)',
        description: 'T568B wire for pin $pin',
        imageUrl: 'assets/simulations/device.svg',
        correctSlot: 'pin$pin',
        category: 'cable',
        step: pin,
        tooltip: 'T568B standard: ${colors[index]}.',
      );
    }),
  );

  static Simulation getIpConfiguration() => _simulation(
    id: 'sim_coc2_ipconfig',
    title: 'IP Configuration - COC2',
    description:
        'Assign the correct IP addresses to each device in the network.',
    type: 'networking',
    competency: 'COC2',
    learningOutcome: 'LO3 - Set-up network protocols',
    timeLimit: 10,
    requiredSimulationId: 'sim_coc2_topology',
    items: [
      _ip('ip_pc1', 'PC 1: 192.168.1.10', 'pc1_ip', 1),
      _ip('ip_pc2', 'PC 2: 192.168.1.11', 'pc2_ip', 2),
      _ip('ip_pc3', 'PC 3: 192.168.1.12', 'pc3_ip', 3),
      _ip('ip_server', 'Server: 192.168.1.1', 'server_ip', 4),
      _ip('ip_router', 'Router: 192.168.1.254', 'router_ip', 5),
    ],
  );

  static DraggableItem _ip(String id, String name, String slot, int step) =>
      _item(
        id: id,
        name: name,
        description: 'Assign this address to the correct network device',
        imageUrl: 'assets/simulations/device.svg',
        correctSlot: slot,
        category: 'network',
        step: step,
        tooltip: 'Keep all devices on the same private subnet.',
      );

  static Simulation getComputerAssembly() => getPcAssembly();
  static Simulation getNetworkSetup() => getNetworkTopology();

  static List<Simulation> getAllSimulations() => [
    getPcAssembly(),
    getCableManagement(),
    getHardwareIdentification(),
    getNetworkTopology(),
    getRj45Crimping(),
    getIpConfiguration(),
  ];

  static List<Simulation> getSimulationsByCompetency(String competency) =>
      getAllSimulations().where((sim) => sim.competency == competency).toList();

  static Simulation? getSimulationById(String id) {
    for (final simulation in getAllSimulations()) {
      if (simulation.id == id) return simulation;
    }
    return null;
  }

  static List<Simulation> getSimulationsByLearningOutcome(
    String learningOutcome,
  ) => getAllSimulations()
      .where((sim) => sim.learningOutcome.contains(learningOutcome))
      .toList();

  static List<Simulation> getPrerequisiteChain(String simulationId) {
    final chain = <Simulation>[];
    var current = getSimulationById(simulationId);
    final visited = <String>{};
    while (current?.requiredSimulationId != null && visited.add(current!.id)) {
      final prerequisite = getSimulationById(current.requiredSimulationId!);
      if (prerequisite == null) break;
      chain.insert(0, prerequisite);
      current = prerequisite;
    }
    return chain;
  }
}
