import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/church_entity.dart';
import '../../domain/repositories/church_repository.dart';
import '../datasources/church_remote_data_source.dart';

class ChurchRepositoryImpl implements ChurchRepository {
  final ChurchRemoteDataSource _dataSource;

  ChurchRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, ChurchEntity>> createChurch({
    required String adminId,
    required String name,
    String? city,
    String? phone,
    String? cnpj,
  }) async {
    try {
      final church = await _dataSource.createChurch(
        adminId: adminId,
        name: name,
        city: city,
        phone: phone,
        cnpj: cnpj,
      );
      return Right(church);
    } on ChurchNotFoundException catch (e) {
      return Left(ChurchFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ChurchFailure('Erro ao criar organização: $e'));
    }
  }

  @override
  Future<Either<Failure, ChurchEntity>> joinChurch({
    required String userId,
    required String inviteCode,
  }) async {
    try {
      final church = await _dataSource.joinChurch(
        userId: userId,
        inviteCode: inviteCode,
      );
      return Right(church);
    } on ChurchNotFoundException catch (e) {
      return Left(ChurchFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ChurchFailure('Erro ao entrar na organização: $e'));
    }
  }

  @override
  Future<Either<Failure, ChurchEntity>> getChurchById(String churchId) async {
    try {
      final church = await _dataSource.getChurchById(churchId);
      return Right(church);
    } on ChurchNotFoundException catch (e) {
      return Left(ChurchFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ChurchFailure('Erro ao buscar organização: $e'));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getChurchMembers(
      String churchId) async {
    try {
      final members = await _dataSource.getChurchMembers(churchId);
      return Right(members);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro ao buscar membros: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateMemberRole(
      String userId, UserRole newRole) async {
    try {
      await _dataSource.updateMemberRole(userId, newRole);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro ao atualizar cargo: $e'));
    }
  }
}

