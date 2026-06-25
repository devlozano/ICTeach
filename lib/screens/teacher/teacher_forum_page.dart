import 'package:flutter/material.dart';
import '../student/forums_page.dart';

class TeacherForumPage extends StatelessWidget {
  final String classId;
  final String className;

  const TeacherForumPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    // Reuse the same forum page but with moderation features
    return ForumsPage(
      classId: classId,
      className: className,
    );
  }
}
