import 'package:flutter/material.dart';
import '../services/content_access_service.dart';

class ContentAccessGate extends StatefulWidget {
  final String classId;
  final String contentType;
  final String contentId;
  final WidgetBuilder builder;
  final Future<bool> Function(String)? staffLoader;
  final Stream<List<Map<String, dynamic>>> Function(String)? locksLoader;
  const ContentAccessGate({
    super.key,
    required this.classId,
    required this.contentType,
    this.contentId = '*',
    required this.builder,
    this.staffLoader,
    this.locksLoader,
  });
  @override
  State<ContentAccessGate> createState() => _ContentAccessGateState();
}

class _ContentAccessGateState extends State<ContentAccessGate> {
  late Future<bool> _staff;
  late Stream<List<Map<String, dynamic>>> _locks;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ContentAccessGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) _load();
  }

  void _load() {
    _staff = (widget.staffLoader ?? ContentAccessService.isClassStaff)(
      widget.classId,
    );
    _locks =
        widget.locksLoader?.call(widget.classId) ??
        ContentAccessService.locks(
          widget.classId,
        ).map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }

  Widget _message(String message, {bool retry = false}) => Scaffold(
    appBar: AppBar(title: const Text('Content access')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (retry)
              TextButton(
                onPressed: () => setState(_load),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _staff,
    builder: (context, staff) {
      if (staff.hasError) {
        return _message(
          'Unable to verify access. Check your connection and try again.',
          retry: true,
        );
      }
      if (!staff.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (staff.data == true) return widget.builder(context);
      return StreamBuilder<List<Map<String, dynamic>>>(
        stream: _locks,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(
              'Unable to load content access. Please try again.',
              retry: true,
            );
          }
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (ContentAccessService.isLocked(
            snapshot.data!,
            widget.contentType,
            widget.contentId,
          )) {
            return _message(
              'Your teacher or trainer has locked this activity. It will become available when they unlock it.',
            );
          }
          return widget.builder(context);
        },
      );
    },
  );
}
