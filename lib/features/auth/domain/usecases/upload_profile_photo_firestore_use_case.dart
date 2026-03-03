import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/firestore_photo_data_source.dart';

/// Use case alternativo que salva a foto no Firestore como base64.
/// ⚠️ Use apenas se não tiver o plano Blaze do Firebase.
class UploadProfilePhotoFirestoreUseCase {
  final FirestorePhotoDataSource _firestorePhotoDataSource;

  UploadProfilePhotoFirestoreUseCase(this._firestorePhotoDataSource);

  Future<Either<Failure, String>> call(String userId, String imagePath) async {
    try {
      final photoUrl = await _firestorePhotoDataSource.uploadProfilePhotoAsBase64(userId, imagePath);
      return Right(photoUrl);
    } on ServerException {
      return const Left(ServerFailure('Erro ao fazer upload da foto. A imagem pode ser muito grande.'));
    } catch (e) {
      return const Left(ServerFailure('Erro inesperado ao fazer upload da foto'));
    }
  }
}

