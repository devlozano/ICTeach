import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Migrate all students from enrolledStudentIds to students subcollection
  Future<void> migrateAllStudentsToSubcollection() async {
    try {
      print('🔄 Starting migration of students to subcollections...');

      // Get all classes
      final classesSnapshot = await _firestore.collection('classes').get();

      int totalClasses = 0;
      int totalStudents = 0;
      int migratedCount = 0;

      for (final classDoc in classesSnapshot.docs) {
        totalClasses++;
        final classId = classDoc.id;
        final data = classDoc.data();
        final enrolledStudentIds =
            List<String>.from(data['enrolledStudentIds'] ?? []);

        if (enrolledStudentIds.isEmpty) {
          print('📚 Class ${data['name']} has no students');
          continue;
        }

        print(
            '📚 Migrating ${enrolledStudentIds.length} students from class: ${data['name']}');

        for (final studentId in enrolledStudentIds) {
          try {
            // Get student info from users collection
            final userDoc =
                await _firestore.collection('users').doc(studentId).get();

            if (!userDoc.exists) {
              print('⚠️ User $studentId not found in users collection');
              continue;
            }

            final userData = userDoc.data() as Map<String, dynamic>? ?? {};
            final name = userData['name']?.toString() ??
                userData['displayName']?.toString() ??
                'Student';
            final email = userData['email']?.toString() ?? '';

            // ✅ Add student to class's students subcollection
            await _firestore
                .collection('classes')
                .doc(classId)
                .collection('students')
                .doc(studentId)
                .set({
              'uid': studentId,
              'name': name,
              'email': email,
              'joinedAt': FieldValue.serverTimestamp(),
              'status': 'active',
            });

            migratedCount++;
            print('   ✅ Migrated: $name ($studentId)');
          } catch (e) {
            print('   ❌ Error migrating student $studentId: $e');
          }
          totalStudents++;
        }
      }

      print('\n✅ Migration complete!');
      print('📊 Total classes processed: $totalClasses');
      print('📊 Total students processed: $totalStudents');
      print('📊 Successfully migrated: $migratedCount');
    } catch (e) {
      print('❌ Migration error: $e');
    }
  }

  // Migrate a single class
  Future<void> migrateClassStudents(String classId) async {
    try {
      print('🔄 Migrating students for class: $classId');

      final classDoc =
          await _firestore.collection('classes').doc(classId).get();

      if (!classDoc.exists) {
        print('❌ Class not found');
        return;
      }

      final data = classDoc.data() as Map<String, dynamic>? ?? {};
      final enrolledStudentIds =
          List<String>.from(data['enrolledStudentIds'] ?? []);
      final className = data['name'] ?? 'Unnamed Class';

      if (enrolledStudentIds.isEmpty) {
        print('📚 Class $className has no students');
        return;
      }

      print('📚 Found ${enrolledStudentIds.length} students in $className');

      for (final studentId in enrolledStudentIds) {
        try {
          final userDoc =
              await _firestore.collection('users').doc(studentId).get();

          if (!userDoc.exists) {
            print('⚠️ User $studentId not found');
            continue;
          }

          final userData = userDoc.data() as Map<String, dynamic>? ?? {};
          final name = userData['name']?.toString() ?? 'Student';
          final email = userData['email']?.toString() ?? '';

          await _firestore
              .collection('classes')
              .doc(classId)
              .collection('students')
              .doc(studentId)
              .set({
            'uid': studentId,
            'name': name,
            'email': email,
            'joinedAt': FieldValue.serverTimestamp(),
            'status': 'active',
          });

          print('   ✅ Migrated: $name');
        } catch (e) {
          print('   ❌ Error: $e');
        }
      }

      print('✅ Migration complete for class: $className');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

// Add this to migration_service.dart
  Future<void> fixClassNames() async {
    try {
      print('🔄 Fixing class names...');

      final classesSnapshot = await _firestore.collection('classes').get();

      int fixedCount = 0;
      for (final doc in classesSnapshot.docs) {
        final data = doc.data();
        final id = doc.id;

        // Check if className exists but name doesn't
        if (data.containsKey('className') && !data.containsKey('name')) {
          final className = data['className']?.toString() ?? 'Untitled Class';

          // Add the name field
          await _firestore.collection('classes').doc(id).update({
            'name': className,
          });
          fixedCount++;
          print('✅ Fixed class: $className');
        }
      }

      print('✅ Fixed $fixedCount classes');
    } catch (e) {
      print('❌ Error fixing class names: $e');
    }
  }

// In migration_service.dart
  Future<void> migrateMissingStudentsToSubcollection() async {
    try {
      print('🔄 Migrating missing students to subcollections...');

      // Get all classes
      final classesSnapshot = await _firestore.collection('classes').get();

      int totalFixed = 0;

      for (final classDoc in classesSnapshot.docs) {
        final classId = classDoc.id;
        final data = classDoc.data();
        final enrolledStudentIds =
            List<String>.from(data['enrolledStudentIds'] ?? []);

        if (enrolledStudentIds.isEmpty) continue;

        print('📚 Processing class: ${data['name']}');
        print('   Found ${enrolledStudentIds.length} enrolled students');

        // Check each student in the subcollection
        for (final studentId in enrolledStudentIds) {
          // Check if student exists in subcollection
          final subDoc = await _firestore
              .collection('classes')
              .doc(classId)
              .collection('students')
              .doc(studentId)
              .get();

          if (!subDoc.exists) {
            // Student is missing from subcollection - add them
            print('   ⚠️ Student $studentId missing from subcollection');

            // Try to get student info from users collection
            final userDoc =
                await _firestore.collection('users').doc(studentId).get();

            String name = 'Student ${studentId.substring(0, 6)}';
            String email = '';
            String role = 'student';

            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>? ?? {};
              name = userData['name']?.toString() ??
                  userData['displayName']?.toString() ??
                  'Student ${studentId.substring(0, 6)}';
              email = userData['email']?.toString() ?? '';
              role = userData['role']?.toString() ?? 'student';
            }

            // Add to subcollection
            await _firestore
                .collection('classes')
                .doc(classId)
                .collection('students')
                .doc(studentId)
                .set({
              'uid': studentId,
              'name': name,
              'email': email,
              'role': role,
              'joinedAt': FieldValue.serverTimestamp(),
              'status': 'active',
            });

            totalFixed++;
            print('   ✅ Added $name to subcollection');
          }
        }
      }

      print('✅ Migration complete! Fixed $totalFixed students');
    } catch (e) {
      print('❌ Migration error: $e');
    }
  }

  // Fix a single student
  Future<void> addStudentToClass(String classId, String studentId) async {
    try {
      // Get student info
      final userDoc = await _firestore.collection('users').doc(studentId).get();

      if (!userDoc.exists) {
        print('❌ User $studentId not found');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final name = userData['name']?.toString() ?? 'Student';
      final email = userData['email']?.toString() ?? '';

      // Add to class subcollection
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .set({
        'uid': studentId,
        'name': name,
        'email': email,
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      // Add to enrolledStudentIds if not already there
      await _firestore.collection('classes').doc(classId).update({
        'enrolledStudentIds': FieldValue.arrayUnion([studentId]),
      });

      print('✅ Added student $name to class');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}
