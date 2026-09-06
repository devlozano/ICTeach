import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolYearService {
  /// Class documents are authoritative; membership copies may predate rollover.
  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  activeMemberships(String uid) async {
    final db = FirebaseFirestore.instance;
    final memberships = await db
        .collection('users')
        .doc(uid)
        .collection('classes')
        .get();
    final active = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final membership in memberships.docs) {
      final classroom = await db.collection('classes').doc(membership.id).get();
      if (classroom.exists && classroom.data()?['status'] != 'archived')
        active.add(membership);
    }
    active.sort(
      (a, b) =>
          ((b.data()['joinedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0)
              .compareTo(
                (a.data()['joinedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                    0,
              ),
    );
    return active;
  }
}
