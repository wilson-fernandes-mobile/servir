import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

import '../../../../core/errors/exceptions.dart';

abstract class StorageDataSource {
  /// Faz upload de uma foto de perfil compactada para o Firebase Storage.
  /// Retorna a URL pública da imagem.
  Future<String> uploadProfilePhoto(String userId, String imagePath);
  
  /// Deleta a foto de perfil do usuário.
  Future<void> deleteProfilePhoto(String userId);
}

class FirebaseStorageDataSource implements StorageDataSource {
  final FirebaseStorage _storage;

  FirebaseStorageDataSource(this._storage);

  @override
  Future<String> uploadProfilePhoto(String userId, String imagePath) async {
    try {
      // Compacta a imagem antes do upload
      final compressedBytes = await _compressImage(imagePath);
      
      if (compressedBytes == null) {
        throw const ServerException();
      }

      // Define o caminho no Storage
      final ref = _storage.ref().child('users/$userId/profile.jpg');
      
      // Faz upload da imagem compactada
      final uploadTask = ref.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      
      // Retorna a URL pública
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw const ServerException();
    }
  }

  @override
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      final ref = _storage.ref().child('users/$userId/profile.jpg');
      await ref.delete();
    } catch (e) {
      // Ignora erro se o arquivo não existir
      if (e is! FirebaseException || e.code != 'object-not-found') {
        throw const ServerException();
      }
    }
  }

  /// Compacta a imagem para economizar espaço no Storage.
  /// - Redimensiona para máximo 512x512
  /// - Qualidade 85%
  /// - Formato JPEG
  Future<Uint8List?> _compressImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      // Compacta a imagem
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 512,
        minHeight: 512,
        quality: 85,
        format: CompressFormat.jpeg,
      );
      
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      return null;
    }
  }
}

