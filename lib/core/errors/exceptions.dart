class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Erro no servidor.']);
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Erro de autenticação.']);
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException([this.message = 'Não encontrado.']);
}

class PermissionException implements Exception {
  final String message;
  const PermissionException([this.message = 'Sem permissão para esta ação.']);
}

class ChurchNotFoundException implements Exception {
  final String message;
  const ChurchNotFoundException([this.message = 'Organização não encontrada.']);
}

class MinistryNotFoundException implements Exception {
  final String message;
  const MinistryNotFoundException([this.message = 'Ministério não encontrado.']);
}

