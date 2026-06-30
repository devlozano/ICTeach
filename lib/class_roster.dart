import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClassRosterPage extends StatefulWidget {
  final String classId;
  final String className;

  const ClassRosterPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassRosterPage> createState() => _ClassRosterPageState();
}

class _ClassRosterPageState extends State<ClassRosterPage> {
  String _classCode = '';
  String _teacherName = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _trainers = [];

  @override
  void initState() {
    super.initState();
    _fetchClassData();
    _loadRoster();
  }

  Future<void> _fetchClassData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _classCode = data['classCode']?.toString() ?? '';
            _teacherName = data['teacherName']?.toString() ?? 'Unknown Teacher';
          });
        }
      }
    } catch (e) {
      print('Error fetching class data: $e');
    }
  }

  Future<void> _loadRoster() async {
    setState(() => _isLoading = true);
    try {
      // ✅ Get the class document to get all enrolled IDs
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();

      if (!classDoc.exists) {
        print('❌ Class document not found');
        setState(() => _isLoading = false);
        return;
      }

      final data = classDoc.data() as Map<String, dynamic>? ?? {};
      final enrolledIds = List<String>.from(data['enrolledStudentIds'] ?? []);

      print('📊 Total enrolled IDs: ${enrolledIds.length}');
      print('📊 Enrolled IDs: $enrolledIds');

      if (enrolledIds.isEmpty) {
        print('⚠️ No enrolled users found');
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Fetch ALL users from the users collection to get their names
      final allUsersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      // Create a map of userId -> userData for quick lookup
      final Map<String, Map<String, dynamic>> usersMap = {};
      for (final doc in allUsersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>? ?? {};
        final uid = userData['uid']?.toString() ?? doc.id;
        usersMap[uid] = userData;
        usersMap[doc.id] = userData; // Also index by document ID
      }

      print('📊 Found ${usersMap.length} users in users collection');
      print('📊 User IDs: ${usersMap.keys.join(', ')}');

      // ✅ Separate students and trainers
      final List<Map<String, dynamic>> students = [];
      final List<Map<String, dynamic>> trainers = [];

      for (final userId in enrolledIds) {
        print('🔍 Looking for user: $userId');

        // Try to find the user in the usersMap
        Map<String, dynamic>? userData = usersMap[userId];

        // If not found, try to find by checking if any user has this as their uid field
        if (userData == null) {
          for (final entry in usersMap.entries) {
            if (entry.value['uid']?.toString() == userId) {
              userData = entry.value;
              print(
                  '   ✅ Found user by uid field: ${userData?['displayName']}');
              break;
            }
          }
        }

        if (userData != null) {
          // ✅ User found - get their name from the users collection
          String name = userData['displayName']?.toString() ?? '';
          if (name.isEmpty) {
            name = userData['name']?.toString() ?? '';
          }
          if (name.isEmpty) {
            // Try building from firstName + lastName
            final firstName = userData['firstName']?.toString() ?? '';
            final lastName = userData['lastName']?.toString() ?? '';
            if (firstName.isNotEmpty || lastName.isNotEmpty) {
              name = '$firstName $lastName'.trim();
            }
          }
          if (name.isEmpty) {
            name = 'Unknown User';
          }

          final email = userData['email']?.toString() ?? '';
          final role = userData['role']?.toString() ?? 'student';

          print('   👤 Found: $name, Role: $role, Email: $email');

          final userInfo = {
            'id': userId,
            'name': name,
            'email': email,
            'role': role,
            'data': userData,
          };

          if (role.toLowerCase() == 'trainer') {
            trainers.add(userInfo);
          } else {
            students.add(userInfo);
          }
        } else {
          // ✅ User not found - try checking the students subcollection
          print(
              '   ⚠️ User not found in users collection, checking subcollection...');

          final subDoc = await FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId)
              .collection('students')
              .doc(userId)
              .get();

          String name = 'Unknown User';
          String email = '';

          if (subDoc.exists) {
            final subData = subDoc.data() as Map<String, dynamic>? ?? {};
            name = subData['name']?.toString() ?? 'Unknown User';
            email = subData['email']?.toString() ?? '';
            print('   📋 Found in subcollection: $name');
          } else {
            name = 'Student ${userId.substring(0, 6)}';
            print('   📋 No data found, using: $name');
          }

          students.add({
            'id': userId,
            'name': name,
            'email': email,
            'role': 'student',
            'data': {},
          });
        }
      }

      // ✅ Sort students by name
      students
          .sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
      trainers
          .sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

      setState(() {
        _students = students;
        _trainers = trainers;
        _isLoading = false;
      });

      print(
          '📊 Final counts - Students: ${students.length}, Trainers: ${trainers.length}');
      print('📊 Student names: ${students.map((s) => s['name']).join(', ')}');
      print('📊 Trainer names: ${trainers.map((t) => t['name']).join(', ')}');
    } catch (e) {
      print('❌ Error loading roster: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> deleteStudent(BuildContext context, String studentId) async {
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid user ID")));
      return;
    }

    try {
      // Delete from subcollection
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(studentId)
          .delete();

      // Delete from user's classes subcollection if exists
      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .collection('classes')
          .doc(widget.classId)
          .delete();

      // Remove from enrolledStudentIds array
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .update({
        'enrolledStudentIds': FieldValue.arrayRemove([studentId]),
      });

      // Refresh the list
      await _loadRoster();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User removed from class")),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error removing user: $e")),
      );
    }
  }

  void editStudent(
    BuildContext context,
    String studentId,
    Map<String, dynamic> data,
  ) {
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid user ID")));
      return;
    }

    final nameController = TextEditingController(
      text: data['displayName']?.toString() ?? data['name']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit User"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Name cannot be empty")),
                  );
                  return;
                }

                try {
                  // Update in users collection
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(studentId)
                      .update({
                    'displayName': newName,
                    'name': newName,
                  });

                  // Update in students subcollection if exists
                  await FirebaseFirestore.instance
                      .collection('classes')
                      .doc(widget.classId)
                      .collection('students')
                      .doc(studentId)
                      .update({'name': newName});

                  // Refresh the list
                  await _loadRoster();

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Name updated")),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error updating name: $e")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _copyClassCode(BuildContext context) {
    if (_classCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No class code available")));
      return;
    }

    Clipboard.setData(ClipboardData(text: _classCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Class code "$_classCode" copied!',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.className,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_teacherName.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 12,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _teacherName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
          ],
        ),
        backgroundColor: const Color(0xFF428DEB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_classCode.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'copy') {
                    _copyClassCode(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 18, color: Color(0xFF428DEB)),
                        SizedBox(width: 8),
                        Text('Copy Class Code'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: double.infinity,
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Class Code',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _classCode.isNotEmpty ? _classCode : 'Loading...',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_classCode.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.shade300,
                                ),
                              ),
                              child: Text(
                                'Share with students',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_classCode.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _copyClassCode(context),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF428DEB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_students.isEmpty && _trainers.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No users joined yet",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Share the class code to invite students and trainers",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Trainers Section
                    if (_trainers.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Trainers (${_trainers.length})',
                                style: TextStyle(
                                  color: Colors.purple.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '👑 Class Trainers',
                              style: TextStyle(
                                color: Colors.purple.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._trainers.map((trainer) => _buildUserCard(
                            context,
                            trainer,
                            isTrainer: true,
                          )),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],

                    // Students Section
                    if (_students.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Students (${_students.length})',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '🎓 Enrolled Students',
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._students.map((student) => _buildUserCard(
                            context,
                            student,
                            isTrainer: false,
                          )),
                    ],
                  ],
                ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    Map<String, dynamic> user, {
    required bool isTrainer,
  }) {
    final userId = user['id'] ?? '';
    final name = user['name'] ?? 'Unknown User';
    final email = user['email'] ?? '';
    final data = user['data'] ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isTrainer
              ? Colors.purple.shade100
              : const Color(0xFF428DEB).withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              color:
                  isTrainer ? Colors.purple.shade700 : const Color(0xFF428DEB),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isTrainer)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '👑 Trainer',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          email.isNotEmpty ? email : 'No email',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: "edit",
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    size: 18,
                    color: Color(0xFF428DEB),
                  ),
                  SizedBox(width: 8),
                  Text("Edit"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: "delete",
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                  SizedBox(width: 8),
                  Text("Remove"),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == "edit") {
              editStudent(context, userId, data);
            } else if (value == "delete") {
              deleteStudent(context, userId);
            }
          },
        ),
      ),
    );
  }
}
