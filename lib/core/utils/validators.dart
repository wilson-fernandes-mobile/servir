import 'cnpj_utils.dart';

class Validators {
  Validators._();

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'E-mail inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Campo obrigatório';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  static String? Function(String?) confirmPassword(String? original) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'Campo obrigatório';
      if (value != original) return 'Senhas não coincidem';
      return null;
    };
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // opcional
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Telefone inválido';
    return null;
  }

  /// Valida CNPJ numérico (atual) **e** alfanumérico (novo formato jul/2026).
  /// Campo é opcional — devolve `null` se estiver vazio.
  static String? cnpj(String? value) {
    if (value == null || value.trim().isEmpty) return null; // opcional
    if (!CnpjUtils.isValid(value.trim())) return 'CNPJ inválido';
    return null;
  }
}

