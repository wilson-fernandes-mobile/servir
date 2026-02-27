import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/ministry_model.dart';
import 'ministry_remote_data_source.dart';
import '../../domain/entities/ministry_entity.dart';

class FirestoreMinistryDataSource implements MinistryRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirestoreMinistryDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const _codeLength = 6;

  String _generateCode() {
    final rand = Random.secure();
    return List.generate(_codeLength, (_) => _chars[rand.nextInt(_chars.length)])
        .join();
  }

  Future<String> _uniqueInviteCode() async {
    String code;
    bool exists;
    do {
      code = _generateCode();
      final snap = await _firestore
          .collection('ministries')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      exists = snap.docs.isNotEmpty;
    } while (exists);
    return code;
  }

  @override
  Future<List<MinistryEntity>> getMinistriesByChurchId(String churchId) async {
    // orderBy('name') alongside multiple where-clauses requires a composite
    // Firestore index. Sort in Dart instead to avoid the index dependency.
    final snap = await _firestore
        .collection('ministries')
        .where('churchId', isEqualTo: churchId)
        .where('isActive', isEqualTo: true)
        .get();
    final list = snap.docs
        .map((doc) => MinistryModel.fromFirestore(doc))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<MinistryEntity> createMinistry({
    required String name,
    String? description,
    required String churchId,
  }) async {
    final inviteCode = await _uniqueInviteCode();
    final now = DateTime.now();
    final ref = _firestore.collection('ministries').doc();
    final model = MinistryModel(
      id: ref.id,
      name: name,
      description: description,
      churchId: churchId,
      inviteCode: inviteCode,
      leaderIds: const [],
      memberIds: const [],
      isActive: true,
      createdAt: now,
    );
    await ref.set(model.toFirestore());
    return model;
  }

  @override
  Future<MinistryEntity> joinMinistry({
    required String userId,
    required String inviteCode,
    required String churchId,
  }) async {
    final snap = await _firestore
        .collection('ministries')
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .where('churchId', isEqualTo: churchId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw const MinistryNotFoundException(
          'Código de convite inválido ou expirado.');
    }

    final ministryDoc = snap.docs.first;
    await ministryDoc.reference.update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });

    final updated = await ministryDoc.reference.get();
    return MinistryModel.fromFirestore(updated);
  }

  @override
  Future<void> addMemberToMinistry(String ministryId, String userId) async {
    await _firestore.collection('ministries').doc(ministryId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<void> addLeaderToMinistry(String ministryId, String userId) async {
    await _firestore.collection('ministries').doc(ministryId).update({
      'leaderIds': FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<void> removeLeaderFromMinistry(
      String ministryId, String userId) async {
    await _firestore.collection('ministries').doc(ministryId).update({
      'leaderIds': FieldValue.arrayRemove([userId]),
    });
  }

  @override
  Future<void> removeLeaderFromAllMinistries(
      String churchId, String userId) async {
    final snap = await _firestore
        .collection('ministries')
        .where('churchId', isEqualTo: churchId)
        .where('leaderIds', arrayContains: userId)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'leaderIds': FieldValue.arrayRemove([userId]),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> deleteMinistry(String ministryId) async {
    await _firestore.collection('ministries').doc(ministryId).delete();
  }

  @override
  Future<void> updateMinistryRoles(
      String ministryId, List<String> roles) async {
    await _firestore
        .collection('ministries')
        .doc(ministryId)
        .update({'roles': roles});
  }

  @override
  Future<MinistryEntity?> getMinistryById(String ministryId) async {
    final doc = await _firestore
        .collection('ministries')
        .doc(ministryId)
        .get();
    if (!doc.exists) return null;
    return MinistryModel.fromFirestore(doc);
  }

  @override
  Stream<MinistryEntity?> watchMinistryById(String ministryId) {
    return _firestore
        .collection('ministries')
        .doc(ministryId)
        .snapshots()
        .map((doc) => doc.exists ? MinistryModel.fromFirestore(doc) : null);
  }
}

