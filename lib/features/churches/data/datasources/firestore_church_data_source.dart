import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../models/church_model.dart';
import 'church_remote_data_source.dart';

class FirestoreChurchDataSource implements ChurchRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirestoreChurchDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const _codeLength = 6;

  /// Generates a random [_codeLength]-character alphanumeric invite code.
  String _generateCode() {
    final rand = Random.secure();
    return List.generate(_codeLength, (_) => _chars[rand.nextInt(_chars.length)])
        .join();
  }

  /// Ensures the generated code doesn't already exist in Firestore.
  Future<String> _uniqueInviteCode() async {
    String code;
    bool exists;
    do {
      code = _generateCode();
      final snap = await _firestore
          .collection('churches')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      exists = snap.docs.isNotEmpty;
    } while (exists);
    return code;
  }

  @override
  Future<ChurchModel> createChurch({
    required String adminId,
    required String name,
    String? city,
    String? phone,
    String? cnpj,
  }) async {
    final inviteCode = await _uniqueInviteCode();
    final now = DateTime.now();
    final churchRef = _firestore.collection('churches').doc();
    final userRef = _firestore.collection('users').doc(adminId);

    final churchData = ChurchModel(
      id: churchRef.id,
      name: name,
      city: city,
      phone: phone,
      cnpj: cnpj,
      inviteCode: inviteCode,
      adminId: adminId,
      isActive: true,
      createdAt: now,
    );

    // Atomic write: create church + link admin user
    final batch = _firestore.batch();
    batch.set(churchRef, churchData.toFirestore());
    batch.update(userRef, {
      'churchId': churchRef.id,
      'role': 'admin',
    });
    await batch.commit();

    return churchData;
  }

  @override
  Future<ChurchModel> joinChurch({
    required String userId,
    required String inviteCode,
  }) async {
    final snap = await _firestore
        .collection('churches')
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw const ChurchNotFoundException('Código de convite inválido ou expirado.');
    }

    final churchDoc = snap.docs.first;
    final userRef = _firestore.collection('users').doc(userId);

    final batch = _firestore.batch();
    batch.update(userRef, {
      'churchId': churchDoc.id,
      'role': 'member',
    });
    await batch.commit();

    return ChurchModel.fromFirestore(churchDoc);
  }

  @override
  Future<ChurchModel> getChurchById(String churchId) async {
    final doc =
        await _firestore.collection('churches').doc(churchId).get();
    if (!doc.exists) {
      throw const ChurchNotFoundException('Organização não encontrada.');
    }
    return ChurchModel.fromFirestore(doc);
  }

  @override
  Future<List<UserEntity>> getChurchMembers(String churchId) async {
    final snap = await _firestore
        .collection('users')
        .where('churchId', isEqualTo: churchId)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> updateMemberRole(String userId, UserRole newRole) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'role': newRole.name});
  }
}

