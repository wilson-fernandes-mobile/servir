import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erro no servidor.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Erro de autenticação.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Não encontrado.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Sem permissão para esta ação.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Erro desconhecido.']);
}

class ChurchFailure extends Failure {
  const ChurchFailure([super.message = 'Erro na organização.']);
}

