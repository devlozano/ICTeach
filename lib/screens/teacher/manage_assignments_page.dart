import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';
import 'create_assignment_page.dart';
import 'assignment_submissions_page.dart';

class ManageAssignmentsPage extends StatefulWidget {
  final String classId;
  final String className;

  const ManageAssignmentsPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ManageAssignmentsPage> createState() => _ManageAssignmentsPageState();
}

class _ManageAssignmentsPageState extends State<ManageAssignmentsPage> {
  final AssignmentService _assignmentService = AssignmentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: Text('Assignments - ${widget.className}'),
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateAssignmentPage(classId: widget.classId),
                ),
              );
              if (result == true && mounted) {
                setState(() {});
              }
            },
            icon: const Icon(Icons.add),
            tooltip: 'Create Assignment',
          ),
        ],
      ),
      body: StreamBuilder<List<AssignmentModel>>(
        stream: _assignmentService.getAssignmentsForClass(widget.classId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final assignments = snapshot.data ?? [];

          if (assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No assignments yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first assignment',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CreateAssignmentPage(classId: widget.classId),
                        ),
                      );
                      if (result == true && mounted) {
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Assignment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B2B4A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return _AssignmentCard(
                assignment: assignment,
                onEdit: () => _editAssignment(assignment),
                onDelete: () => _deleteAssignment(assignment),
                onTogglePublish: () => _togglePublish(assignment),
                onViewSubmissions: () => _viewSubmissions(assignment),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateAssignmentPage(classId: widget.classId),
            ),
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _editAssignment(AssignmentModel assignment) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature coming soon!')),
    );
  }

  Future<void> _deleteAssignment(AssignmentModel assignment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Are you sure you want to delete "${assignment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _assignmentService.deleteAssignment(
            widget.classId, assignment.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Assignment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error deleting assignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePublish(AssignmentModel assignment) async {
    try {
      await _assignmentService.togglePublish(
        widget.classId,
        assignment.id,
        !assignment.isPublished,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            assignment.isPublished
                ? 'Assignment unpublished'
                : 'Assignment published',
          ),
          backgroundColor:
              assignment.isPublished ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewSubmissions(AssignmentModel assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentSubmissionsPage(
          classId: widget.classId,
          assignmentId: assignment.id,
          assignmentTitle: assignment.title,
        ),
      ),
    );
  }
}

// ✅ FIXED: Assignment Card with no overflow
class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublish;
  final VoidCallback onViewSubmissions;

  const _AssignmentCard({
    required this.assignment,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
    required this.onViewSubmissions,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = assignment.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;
    final isDueSoon = daysLeft >= 0 && daysLeft <= 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2B4A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Color(0xFF0B2B4A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            assignment.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // ✅ FIXED: Status badge moved next to title
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: assignment.isPublished
                                ? Colors.green.shade100
                                : Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            assignment.isPublished ? 'Published' : 'Draft',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: assignment.isPublished
                                  ? Colors.green.shade800
                                  : Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: isOverdue ? Colors.red : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${assignment.dueDate.day}/${assignment.dueDate.month}/${assignment.dueDate.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isOverdue ? Colors.red : Colors.grey.shade600,
                          ),
                        ),
                        if (!isOverdue) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDueSoon
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$daysLeft days left',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isDueSoon
                                    ? Colors.orange.shade800
                                    : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Overdue',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            assignment.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // ✅ FIXED: Wrapped in Row with proper spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Max Score: ${assignment.maxScore}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // ✅ FIXED: Action buttons with smaller size
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onViewSubmissions,
                    icon: const Icon(Icons.assessment, size: 18),
                    tooltip: 'View Submissions',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: onTogglePublish,
                    icon: Icon(
                      assignment.isPublished
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 18,
                      color:
                          assignment.isPublished ? Colors.green : Colors.grey,
                    ),
                    tooltip: assignment.isPublished ? 'Unpublish' : 'Publish',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Delete',
                    color: Colors.red,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
