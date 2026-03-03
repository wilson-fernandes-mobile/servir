import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../../core/errors/exceptions.dart';

/// Alternativa ao Firebase Storage que salva a foto como base64 no Firestore.
/// ⚠️ NÃO RECOMENDADO PARA PRODUÇÃO - Use apenas para testes sem plano Blaze.
/// Limitação: Firestore tem limite de 1MB por documento.
abstract class FirestorePhotoDataSource {
  Future<String> uploadProfilePhotoAsBase64(String userId, String imagePath);
}

class FirestorePhotoDataSourceImpl implements FirestorePhotoDataSource {
  final FirebaseFirestore _firestore;

  FirestorePhotoDataSourceImpl(this._firestore);

  @override
  Future<String> uploadProfilePhotoAsBase64(String userId, String imagePath) async {
    try {
      // Compacta a imagem MUITO para caber no limite de 1MB do Firestore
      final compressedBytes = await _compressImage(imagePath);
      
      if (compressedBytes == null) {
        throw const ServerException();
      }

      // Converte para base64
      final base64Image = base64Encode(compressedBytes);
      
      // Verifica o tamanho (Firestore tem limite de ~1MB por documento)
      if (base64Image.length > 900000) { // ~900KB para ter margem
        throw const ServerException();
      }

      // Salva no Firestore
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': 'data:image/jpeg;base64,$base64Image',
      });

      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      if (e is ServerException) rethrow;
      throw const ServerException();
    }
  }

  /// Compacta MUITO a imagem para caber no Firestore (limite de 1MB).
  /// - Redimensiona para máximo 256x256 (bem pequeno)
  /// - Qualidade 70%
  /// - Formato JPEG
  Future<Uint8List?> _compressImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      // Compacta MUITO para caber no Firestore
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 256,
        minHeight: 256,
        quality: 70,
        format: CompressFormat.jpeg,
      );
      
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      return null;
    }
  }
}

