// lib/utils/class_utils.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassUtils {
  static String getClassName(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return 'Untitled Class';

    // Try multiple possible field names
    return data['name']?.toString() ??
        data['className']?.toString() ??
        data['title']?.toString() ??
        'Untitled Class';
  }

  static String getClassNameFromData(Map<String, dynamic> data) {
    return data['name']?.toString() ??
        data['className']?.toString() ??
        data['title']?.toString() ??
        'Untitled Class';
  }
}
