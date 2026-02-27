import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

/// Firebase implementation of [AuthRemoteDataSource].
/// All Firebase references are confined to this class only.
class FirebaseAuthDataSource implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  const FirebaseAuthDataSource({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _auth = firebaseAuth,
        _firestore = firestore;

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) throw const AuthException('Usuário não encontrado.');

      final now = DateTime.now();
      final device = await _getDeviceDescription();

      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': Timestamp.fromDate(now),
        'lastDevice': device,
      });

      return UserModel.fromFirestore(doc).copyWith(
        lastLoginAt: now,
        lastDevice: device,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const ServerException();
    }
  }

  @override
  Future<UserEntity> signUpWithEmail({
    required String name,
    required String email,
    required String? phone,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final now = DateTime.now();
      final device = await _getDeviceDescription();

      final user = UserModel(
        id: uid,
        name: name,
        email: email,
        phone: phone,
        role: UserRole.member,
        isActive: true,
        createdAt: now,
        lastLoginAt: now,
        lastDevice: device,
      );
      await _firestore.collection('users').doc(uid).set(user.toFirestore());
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const ServerException();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      } catch (_) {
        return null;
      }
    });
  }

  Future<String> _getDeviceDescription() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (kIsWeb) {
        final info = await plugin.webBrowserInfo;
        final browser = info.browserName.name;
        final os = info.platform ?? 'Web';
        return '$browser · $os';
      }
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return '${info.brand} ${info.model} · Android ${info.version.release}';
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return '${info.name} · iOS ${info.systemVersion}';
      }
      if (Platform.isWindows) {
        final info = await plugin.windowsInfo;
        return 'Windows · ${info.computerName}';
      }
      if (Platform.isMacOS) {
        final info = await plugin.macOsInfo;
        return 'macOS ${info.osRelease} · ${info.computerName}';
      }
      return 'Desconhecido';
    } catch (_) {
      return 'Desconhecido';
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nenhum usuário encontrado com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      default:
        return 'Erro de autenticação. Tente novamente.';
    }
  }
}

