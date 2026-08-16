// lib/screens/admin/manage_lrn_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ManageLRNPage extends StatefulWidget {
  final bool useStandaloneScaffold;

  const ManageLRNPage({
    super.key,
    this.useStandaloneScaffold = true,
  });

  @override
  State<ManageLRNPage> createState() => _ManageLRNPageState();
}

class _ManageLRNPageState extends State<ManageLRNPage> {
  bool _isUploading = false;
  final TextEditingController _lrnController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  Future<void> _uploadCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() => _isUploading = true);
        final file = File(result.files.single.path!);
        final csvData = await file.readAsString();
        final lines = csvData.split('\n').skip(1);

        final batch = FirebaseFirestore.instance.batch();
        int count = 0;

        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(',');
          if (parts.length >= 3) {
            final lrn = parts[0].trim();
            final firstName = parts[1].trim();
            final lastName = parts[2].trim();
            final middleName = parts.length > 3 ? parts[3].trim() : '';

            final docRef = FirebaseFirestore.instance
                .collection('lrn_master_list')
                .doc(lrn);
            batch.set(docRef, {
              'firstName': firstName,
              'lastName': lastName,
              'middleName': middleName,
              'isRegistered': false,
              'uploadedAt': FieldValue.serverTimestamp(),
            });
            count++;
          }
        }

        await batch.commit();
        _showSnackBar('✅ Uploaded $count LRN records!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Error uploading: $e', Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listSection = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lrn_master_list')
          .orderBy('uploadedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox(
            height: 240,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.numbers, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No LRN records found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Upload CSV or add manually',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 440,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final lrn = docs[index].id;
              final isRegistered = data['isRegistered'] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRegistered
                        ? Colors.green.shade100
                        : Colors.amber.shade100,
                    child: Icon(
                      isRegistered ? Icons.check : Icons.pending,
                      color: isRegistered ? Colors.green : Colors.amber,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    lrn,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  subtitle: Text(
                    '${data['firstName']} ${data['lastName']}${data['middleName'] != null ? ' ${data['middleName']}' : ''}',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isRegistered
                          ? Colors.green.shade100
                          : Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isRegistered ? 'Registered' : 'Pending',
                      style: TextStyle(
                        color: isRegistered
                            ? Colors.green.shade800
                            : Colors.amber.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    final pageContent = Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.upload_file, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Upload CSV File',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : ElevatedButton.icon(
                            onPressed: _uploadCSV,
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Upload CSV'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B2B4A),
                              foregroundColor: Colors.white,
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'CSV Format: LRN, First Name, Last Name, Middle Name (Optional)',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        listSection,
      ],
    );

    if (!widget.useStandaloneScaffold) {
      return SizedBox(
        width: double.infinity,
        child: pageContent,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Manage LRN Master List'),
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddLRNDialog(),
            tooltip: 'Add LRN',
          ),
        ],
      ),
      body: pageContent,
    );
  }

  void _showAddLRNDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add LRN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _lrnController,
              decoration: const InputDecoration(
                labelText: 'LRN',
                hintText: '12-digit LRN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final lrn = _lrnController.text.trim();
              final firstName = _firstNameController.text.trim();
              final lastName = _lastNameController.text.trim();

              if (lrn.isEmpty || firstName.isEmpty || lastName.isEmpty) {
                _showSnackBar('Please fill all required fields', Colors.orange);
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('lrn_master_list')
                    .doc(lrn)
                    .set({
                  'firstName': firstName,
                  'lastName': lastName,
                  'isRegistered': false,
                  'uploadedAt': FieldValue.serverTimestamp(),
                });

                _showSnackBar('✅ LRN added successfully!', Colors.green);
                Navigator.pop(context);
                _lrnController.clear();
                _firstNameController.clear();
                _lastNameController.clear();
              } catch (e) {
                _showSnackBar('Error: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B2B4A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
