import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/storage_data_source.dart';

class UploadProfilePhotoUseCase {
  final StorageDataSource _storageDataSource;
  final FirebaseFirestore _firestore;

  UploadProfilePhotoUseCase(this._storageDataSource, this._firestore);

  Future<Either<Failure, String>> call(String userId, String imagePath) async {
    try {
      // 1. Faz upload da imagem compactada para o Storage
      final photoUrl = await _storageDataSource.uploadProfilePhoto(userId, imagePath);
      
      // 2. Atualiza o documento do usuário com a URL da foto
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': photoUrl,
      });
      
      return Right(photoUrl);
    } on ServerException {
      return const Left(ServerFailure('Erro ao fazer upload da foto'));
    } catch (e) {
      return const Left(ServerFailure('Erro inesperado ao fazer upload da foto'));
    }
  }
}

