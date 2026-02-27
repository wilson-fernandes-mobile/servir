import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/ministry_entity.dart';
import '../../domain/repositories/ministry_repository.dart';
import '../datasources/ministry_remote_data_source.dart';

class MinistryRepositoryImpl implements MinistryRepository {
  final MinistryRemoteDataSource _dataSource;
  MinistryRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<MinistryEntity>>> getMinistriesByChurchId(
      String churchId) async {
    try {
      final result = await _dataSource.getMinistriesByChurchId(churchId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MinistryEntity>> createMinistry({
    required String name,
    String? description,
    required String churchId,
  }) async {
    try {
      final result = await _dataSource.createMinistry(
        name: name,
        description: description,
        churchId: churchId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MinistryEntity>> joinMinistry({
    required String userId,
    required String inviteCode,
    required String churchId,
  }) async {
    try {
      final result = await _dataSource.joinMinistry(
        userId: userId,
        inviteCode: inviteCode,
        churchId: churchId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addMemberToMinistry(
      String ministryId, String userId) async {
    try {
      await _dataSource.addMemberToMinistry(ministryId, userId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addLeaderToMinistry(
      String ministryId, String userId) async {
    try {
      await _dataSource.addLeaderToMinistry(ministryId, userId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeLeaderFromMinistry(
      String ministryId, String userId) async {
    try {
      await _dataSource.removeLeaderFromMinistry(ministryId, userId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeLeaderFromAllMinistries(
      String churchId, String userId) async {
    try {
      await _dataSource.removeLeaderFromAllMinistries(churchId, userId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMinistry(String ministryId) async {
    try {
      await _dataSource.deleteMinistry(ministryId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateMinistryRoles(
      String ministryId, List<String> roles) async {
    try {
      await _dataSource.updateMinistryRoles(ministryId, roles);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MinistryEntity?>> getMinistryById(
      String ministryId) async {
    try {
      final result = await _dataSource.getMinistryById(ministryId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<MinistryEntity?> watchMinistryById(String ministryId) {
    return _dataSource.watchMinistryById(ministryId);
  }
}

