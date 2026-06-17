import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  // ✅ Add the missing methods here
  Future<void> deleteStudent(BuildContext context, String studentId) async {
    // Guard against empty studentId
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid student ID")));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId) // ✅ Use widget.classId
          .collection('students')
          .doc(studentId)
          .delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .collection('classes')
          .doc(widget.classId) // ✅ Use widget.classId
          .delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student removed from class")),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error removing student: $e")));
    }
  }

  void editStudent(
    BuildContext context,
    String studentId,
    Map<String, dynamic> data,
  ) {
    // Guard against empty studentId
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid student ID")));
      return;
    }

    final nameController = TextEditingController(
      text: data['name']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Student"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Student Name"),
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
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(studentId)
                      .update({'name': newName});

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Student name updated")),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.className} Roster"), // ✅ Use widget.className
        backgroundColor: const Color(0xFF428DEB),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId) // ✅ Use widget.classId
            .collection('students')
            .snapshots(),
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Error loading students: ${snapshot.error}"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          // Handle no data
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No data available"));
          }

          final students = snapshot.data!.docs;

          // Handle empty list
          if (students.isEmpty) {
            return const Center(child: Text("No students joined yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];

              // Get student ID safely
              final studentId = student.id ?? '';

              // Skip if studentId is empty
              if (studentId.isEmpty) {
                return const SizedBox();
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(studentId)
                    .get(),
                builder: (context, userSnap) {
                  // Handle loading state
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(Icons.person)),
                        title: Text("Loading..."),
                      ),
                    );
                  }

                  // Handle error or no data
                  if (userSnap.hasError ||
                      !userSnap.hasData ||
                      userSnap.data == null) {
                    return Card(
                      elevation: 3,
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(studentId),
                        subtitle: const Text("Student data not available"),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: "delete",
                              child: Text("Remove"),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == "delete") {
                              deleteStudent(context, studentId);
                            }
                          },
                        ),
                      ),
                    );
                  }

                  final user = userSnap.data!;
                  final data = user.data() as Map<String, dynamic>? ?? {};

                  // Safely get name and email with proper type conversion
                  final name = data['name']?.toString() ?? "Student";
                  final email = data['email']?.toString() ?? "";

                  return Card(
                    elevation: 3,
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(name),
                      subtitle: Text(email),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: "edit",
                            child: Text("Edit"),
                          ),
                          const PopupMenuItem(
                            value: "delete",
                            child: Text("Remove"),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == "edit") {
                            editStudent(context, studentId, data);
                          } else if (value == "delete") {
                            deleteStudent(context, studentId);
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
