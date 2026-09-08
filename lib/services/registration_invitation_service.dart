import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationInvitationService {
  RegistrationInvitationService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  Future<void> validateLrn(String lrn) async {
    if (!RegExp(r'^[0-9]{12}$').hasMatch(lrn)) {
      throw const FormatException('Enter a valid 12-digit LRN.');
    }
    final record = await _db
        .collection('lrn_master_list')
        .doc(lrn)
        .get(const GetOptions(source: Source.server));
    if (!record.exists || record.data()?['isRegistered'] != false) {
      throw const FormatException(
        'This LRN is not available for registration. Check the number and try again.',
      );
    }
  }

  Future<void> claim({
    required String uid,
    required String lrn,
    required Map<String, dynamic> profile,
  }) async {
    final batch = _db.batch();
    batch.set(_db.collection('users').doc(uid), profile);
    batch.set(_db.collection('students').doc(uid), profile);
    batch.update(_db.collection('lrn_master_list').doc(lrn), {
      'isRegistered': true,
      'registeredAt': FieldValue.serverTimestamp(),
      'registeredUid': uid,
    });
    await batch.commit();
  }
}
