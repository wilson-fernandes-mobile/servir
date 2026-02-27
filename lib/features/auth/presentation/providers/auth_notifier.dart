import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/sign_in_use_case.dart';
import '../../domain/usecases/sign_out_use_case.dart';
import '../../domain/usecases/sign_up_use_case.dart';

class AuthState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final UserEntity? user;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    UserEntity? user,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      user: clearUser ? null : user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, user];
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final SignOutUseCase _signOut;

  AuthNotifier({
    required SignInUseCase signIn,
    required SignUpUseCase signUp,
    required SignOutUseCase signOut,
  })  : _signIn = signIn,
        _signUp = signUp,
        _signOut = signOut,
        super(const AuthState());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _signIn(
      SignInParams(email: email, password: password),
    );
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        user: user,
        clearError: true,
      ),
    );
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String? phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _signUp(
      SignUpParams(name: name, email: email, phone: phone, password: password),
    );
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        user: user,
        clearError: true,
      ),
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _signOut();
    state = const AuthState();
  }

  /// Updates the local user state after an external operation (e.g., linking to a church).
  void updateUser(UserEntity user) {
    state = state.copyWith(user: user);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

