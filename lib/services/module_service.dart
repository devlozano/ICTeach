import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/module_model.dart';

class ModuleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get modules for a specific class (with ordering in memory)
  Stream<List<ModuleModel>> getModulesForClass(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('modules')
        // ✅ Remove orderBy to avoid index requirement
        .snapshots()
        .map((snapshot) {
          final modules = snapshot.docs
              .map((doc) => ModuleModel.fromFirestore(doc))
              .toList();
          // ✅ Sort in memory by 'order' field
          modules.sort((a, b) => a.order.compareTo(b.order));
          return modules;
        });
  }

  // Get published modules for students (with ordering in memory)
  Stream<List<ModuleModel>> getPublishedModulesForClass(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('modules')
        .where('isPublished', isEqualTo: true)
        // ✅ Remove orderBy to avoid index requirement
        .snapshots()
        .map((snapshot) {
          final modules = snapshot.docs
              .map((doc) => ModuleModel.fromFirestore(doc))
              .toList();
          // ✅ Sort in memory by 'order' field
          modules.sort((a, b) => a.order.compareTo(b.order));
          return modules;
        });
  }

  // Create a new module
  Future<void> createModule(ModuleModel module) async {
    final docRef = _firestore
        .collection('classes')
        .doc(module.classId)
        .collection('modules')
        .doc();

    await docRef.set({...module.toFirestore(), 'id': docRef.id});
  }

  // Update an existing module
  Future<void> updateModule(ModuleModel module) async {
    await _firestore
        .collection('classes')
        .doc(module.classId)
        .collection('modules')
        .doc(module.id)
        .update(module.toFirestore());
  }

  // Delete a module
  Future<void> deleteModule(String classId, String moduleId) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('modules')
        .doc(moduleId)
        .delete();
  }

  // Get a single module by ID
  Future<ModuleModel?> getModule(String classId, String moduleId) async {
    final doc = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('modules')
        .doc(moduleId)
        .get();

    if (doc.exists) {
      return ModuleModel.fromFirestore(doc);
    }
    return null;
  }

  // Toggle publish status
  Future<void> togglePublish(
    String classId,
    String moduleId,
    bool isPublished,
  ) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('modules')
        .doc(moduleId)
        .update({
          'isPublished': isPublished,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // Get module count for a class
  Future<int> getModuleCount(String classId) async {
    final snapshot = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('modules')
        .count()
        .get();
    // snapshot.count can be nullable on some SDK versions, default to 0
    return snapshot.count ?? 0;
  }

  // Reorder modules (optional)
  Future<void> reorderModules(String classId, List<String> moduleIds) async {
    final batch = _firestore.batch();

    for (int i = 0; i < moduleIds.length; i++) {
      final ref = _firestore
          .collection('classes')
          .doc(classId)
          .collection('modules')
          .doc(moduleIds[i]);
      batch.update(ref, {'order': i});
    }

    await batch.commit();
  }
}
