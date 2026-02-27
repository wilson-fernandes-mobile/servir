import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/church_entity.dart';
import '../../domain/usecases/create_church_use_case.dart';
import '../../domain/usecases/join_church_use_case.dart';
import '../../domain/usecases/update_member_role_use_case.dart';

class ChurchState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final ChurchEntity? church;

  const ChurchState({
    this.isLoading = false,
    this.errorMessage,
    this.church,
  });

  ChurchState copyWith({
    bool? isLoading,
    String? errorMessage,
    ChurchEntity? church,
    bool clearError = false,
  }) {
    return ChurchState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      church: church ?? this.church,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, church];
}

class ChurchNotifier extends StateNotifier<ChurchState> {
  final CreateChurchUseCase _createChurch;
  final JoinChurchUseCase _joinChurch;
  final UpdateMemberRoleUseCase _updateMemberRole;

  ChurchNotifier({
    required CreateChurchUseCase createChurch,
    required JoinChurchUseCase joinChurch,
    required UpdateMemberRoleUseCase updateMemberRole,
  })  : _createChurch = createChurch,
        _joinChurch = joinChurch,
        _updateMemberRole = updateMemberRole,
        super(const ChurchState());

  Future<bool> createChurch({
    required String adminId,
    required String name,
    String? city,
    String? phone,
    String? cnpj,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _createChurch(
      CreateChurchParams(
        adminId: adminId,
        name: name,
        city: city,
        phone: phone,
        cnpj: cnpj,
      ),
    );
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (church) {
        state = state.copyWith(isLoading: false, church: church, clearError: true);
        return true;
      },
    );
  }

  Future<bool> joinChurch({
    required String userId,
    required String inviteCode,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _joinChurch(
      JoinChurchParams(userId: userId, inviteCode: inviteCode),
    );
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (church) {
        state = state.copyWith(isLoading: false, church: church, clearError: true);
        return true;
      },
    );
  }

  Future<bool> updateMemberRole(String userId, UserRole newRole) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _updateMemberRole(
      UpdateMemberRoleParams(userId: userId, newRole: newRole),
    );
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false, clearError: true);
        return true;
      },
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

