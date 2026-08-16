import '../models/simulation_model.dart';

class SimulationData {
  static Simulation getComputerAssembly() {
    final items = [
      DraggableItem(
        id: 'cpu',
        name: 'CPU',
        description: 'Central Processing Unit - The brain of the computer',
        imageUrl: 'assets/simulations/cpu.png',
        correctSlot: 'cpu_socket',
        category: 'processor',
      ),
      DraggableItem(
        id: 'ram',
        name: 'RAM',
        description: 'Random Access Memory - Temporary data storage',
        imageUrl: 'assets/simulations/ram.png',
        correctSlot: 'ram_slot',
        category: 'memory',
      ),
      DraggableItem(
        id: 'gpu',
        name: 'GPU',
        description: 'Graphics Processing Unit - Handles graphics rendering',
        imageUrl: 'assets/simulations/gpu.png',
        correctSlot: 'pcie_slot',
        category: 'graphics',
      ),
      DraggableItem(
        id: 'psu',
        name: 'Power Supply Unit',
        description: 'Converts AC power to DC power for components',
        imageUrl: 'assets/simulations/psu.png',
        correctSlot: 'psu_mount',
        category: 'power',
      ),
      DraggableItem(
        id: 'storage',
        name: 'Storage Drive',
        description: 'Permanent data storage (SSD/HDD)',
        imageUrl: 'assets/simulations/storage.png',
        correctSlot: 'storage_bay',
        category: 'storage',
      ),
      DraggableItem(
        id: 'motherboard',
        name: 'Motherboard',
        description: 'Main circuit board connecting all components',
        imageUrl: 'assets/simulations/motherboard.png',
        correctSlot: 'motherboard_tray',
        category: 'motherboard',
      ),
    ];

    final slots = [
      'cpu_socket',
      'ram_slot',
      'pcie_slot',
      'psu_mount',
      'storage_bay',
      'motherboard_tray',
    ];

    return Simulation(
      id: 'sim_coc1_assembly',
      title: 'COC1: Computer Assembly',
      description:
          'Drag and drop the computer components to their correct positions on the motherboard.',
      type: 'assembly',
      competency: 'COC1',
      learningOutcome: 'LO1',
      items: items,
      slots: slots,
      timeLimit: 15,
      passingScore: 80,
      isPublished: true,
      isLocked: false,
      requiredSimulationId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Simulation getHardwareIdentification() {
    final items = [
      DraggableItem(
        id: 'cpu_label',
        name: 'CPU',
        description: 'Central Processing Unit',
        imageUrl: 'assets/simulations/cpu_label.png',
        correctSlot: 'cpu_target',
        category: 'label',
      ),
      DraggableItem(
        id: 'ram_label',
        name: 'RAM',
        description: 'Random Access Memory',
        imageUrl: 'assets/simulations/ram_label.png',
        correctSlot: 'ram_target',
        category: 'label',
      ),
      DraggableItem(
        id: 'gpu_label',
        name: 'GPU',
        description: 'Graphics Processing Unit',
        imageUrl: 'assets/simulations/gpu_label.png',
        correctSlot: 'gpu_target',
        category: 'label',
      ),
      DraggableItem(
        id: 'psu_label',
        name: 'PSU',
        description: 'Power Supply Unit',
        imageUrl: 'assets/simulations/psu_label.png',
        correctSlot: 'psu_target',
        category: 'label',
      ),
      DraggableItem(
        id: 'motherboard_label',
        name: 'Motherboard',
        description: 'Main circuit board',
        imageUrl: 'assets/simulations/motherboard_label.png',
        correctSlot: 'motherboard_target',
        category: 'label',
      ),
      DraggableItem(
        id: 'storage_label',
        name: 'Storage Drive',
        description: 'SSD/HDD for data storage',
        imageUrl: 'assets/simulations/storage_label.png',
        correctSlot: 'storage_target',
        category: 'label',
      ),
    ];

    final slots = [
      'cpu_target',
      'ram_target',
      'gpu_target',
      'psu_target',
      'motherboard_target',
      'storage_target',
    ];

    return Simulation(
      id: 'sim_coc1_identification',
      title: 'COC1: Hardware Identification',
      description:
          'Drag and drop the correct labels to identify each computer component.',
      type: 'identification',
      competency: 'COC1',
      learningOutcome: 'LO2',
      items: items,
      slots: slots,
      timeLimit: 10,
      passingScore: 80,
      isPublished: true,
      isLocked: false,
      requiredSimulationId: 'sim_coc1_assembly',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Simulation getNetworkSetup() {
    final items = [
      DraggableItem(
        id: 'router',
        name: 'Router',
        description: 'Connects multiple networks and routes data',
        imageUrl: 'assets/simulations/router.png',
        correctSlot: 'router_position',
        category: 'network',
      ),
      DraggableItem(
        id: 'switch',
        name: 'Switch',
        description: 'Connects devices within the same network',
        imageUrl: 'assets/simulations/switch.png',
        correctSlot: 'switch_position',
        category: 'network',
      ),
      DraggableItem(
        id: 'pc',
        name: 'Computer',
        description: 'Client device on the network',
        imageUrl: 'assets/simulations/pc.png',
        correctSlot: 'pc_position',
        category: 'network',
      ),
      DraggableItem(
        id: 'server',
        name: 'Server',
        description: 'Provides services to other computers',
        imageUrl: 'assets/simulations/server.png',
        correctSlot: 'server_position',
        category: 'network',
      ),
      DraggableItem(
        id: 'printer',
        name: 'Printer',
        description: 'Network shared printer',
        imageUrl: 'assets/simulations/printer.png',
        correctSlot: 'printer_position',
        category: 'network',
      ),
      DraggableItem(
        id: 'modem',
        name: 'Modem',
        description: 'Connects to Internet Service Provider',
        imageUrl: 'assets/simulations/modem.png',
        correctSlot: 'modem_position',
        category: 'network',
      ),
    ];

    final slots = [
      'router_position',
      'switch_position',
      'pc_position',
      'server_position',
      'printer_position',
      'modem_position',
    ];

    return Simulation(
      id: 'sim_coc2_networking',
      title: 'COC2: Network Setup',
      description:
          'Drag and drop the network devices to create a functional network topology.',
      type: 'networking',
      competency: 'COC2',
      learningOutcome: 'LO1',
      items: items,
      slots: slots,
      timeLimit: 20,
      passingScore: 80,
      isPublished: true,
      isLocked: false,
      requiredSimulationId: 'sim_coc1_identification',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Simulation getCableManagement() {
    final items = [
      DraggableItem(
        id: 'cable1',
        name: 'UTP Cable',
        description: 'Unshielded Twisted Pair - Standard Ethernet cable',
        imageUrl: 'assets/simulations/utp.png',
        correctSlot: 'utp_slot',
        category: 'cable',
      ),
      DraggableItem(
        id: 'cable2',
        name: 'Fiber Optic',
        description: 'Fiber optic cable for high speed connections',
        imageUrl: 'assets/simulations/fiber.png',
        correctSlot: 'fiber_slot',
        category: 'cable',
      ),
      DraggableItem(
        id: 'cable3',
        name: 'RJ45 Connector',
        description: 'Ethernet connector for UTP cables',
        imageUrl: 'assets/simulations/rj45.png',
        correctSlot: 'rj45_slot',
        category: 'cable',
      ),
      DraggableItem(
        id: 'cable4',
        name: 'Patch Panel',
        description: 'Centralized cable management panel',
        imageUrl: 'assets/simulations/patch.png',
        correctSlot: 'patch_slot',
        category: 'cable',
      ),
    ];

    final slots = [
      'utp_slot',
      'fiber_slot',
      'rj45_slot',
      'patch_slot',
    ];

    return Simulation(
      id: 'sim_coc2_cabling',
      title: 'COC2: Cable Management',
      description:
          'Drag and drop the correct cables and connectors to their appropriate locations.',
      type: 'cabling',
      competency: 'COC2',
      learningOutcome: 'LO2',
      items: items,
      slots: slots,
      timeLimit: 10,
      passingScore: 80,
      isPublished: true,
      isLocked: false,
      requiredSimulationId: 'sim_coc2_networking',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static List<Simulation> getAllSimulations() {
    return [
      getComputerAssembly(),
      getHardwareIdentification(),
      getNetworkSetup(),
      getCableManagement(),
    ];
  }

  static List<Simulation> getSimulationsByCompetency(String competency) {
    return getAllSimulations()
        .where((sim) => sim.competency == competency)
        .toList();
  }

  static Simulation? getSimulationById(String id) {
    try {
      return getAllSimulations().firstWhere((sim) => sim.id == id);
    } catch (_) {
      return null;
    }
  }
}
