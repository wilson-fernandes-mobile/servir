import 'package:flutter/services.dart';

/// Utilitários para CNPJ — compatível com o formato numérico atual e com o
/// novo formato **alfanumérico** (Receita Federal, julho/2026).
///
/// Novo formato: `AA.AAA.AAA/AAAA-DV`
///   • Posições 0–11 (raiz + ordem): A–Z e 0–9
///   • Posições 12–13 (dígitos verificadores): apenas 0–9
///   • Cálculo do DV: módulo 11 usando valor ASCII para letras (A=10 … Z=35)
class CnpjUtils {
  CnpjUtils._();

  // Pesos para o 1.º dígito verificador (12 elementos, posições 0–11)
  static const _w1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  // Pesos para o 2.º dígito verificador (13 elementos, posições 0–12)
  static const _w2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  /// Remove máscara e retorna os 14 caracteres brutos em maiúsculo.
  static String strip(String cnpj) =>
      cnpj.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

  /// Formata 14 caracteres brutos como `AA.AAA.AAA/AAAA-DV`.
  /// Devolve o valor original se não tiver exatamente 14 caracteres.
  static String format(String cnpj) {
    final raw = strip(cnpj);
    if (raw.length != 14) return cnpj;
    return '${raw.substring(0, 2)}.${raw.substring(2, 5)}.'
        '${raw.substring(5, 8)}/${raw.substring(8, 12)}-${raw.substring(12)}';
  }

  /// Valor numérico de um caractere para o cálculo módulo 11.
  ///   • '0'–'9' → 0–9
  ///   • 'A'–'Z' → 10–35  (codeUnit − 55)
  static int _charValue(String c) {
    final code = c.codeUnitAt(0);
    if (code >= 48 && code <= 57) return code - 48; // dígito
    return code - 55; // letra maiúscula
  }

  /// Calcula um dígito verificador a partir dos [weights] fornecidos.
  /// [raw] deve ter exatamente `weights.length` caracteres.
  static int _calcDv(String raw, List<int> weights) {
    int sum = 0;
    for (int i = 0; i < weights.length; i++) {
      sum += _charValue(raw[i]) * weights[i];
    }
    final rem = sum % 11;
    return rem < 2 ? 0 : 11 - rem;
  }

  /// Retorna `true` se o CNPJ (com ou sem máscara) for válido, aceitando
  /// tanto o formato numérico quanto o novo alfanumérico.
  static bool isValid(String cnpj) {
    final raw = strip(cnpj);

    // Deve ter exatamente 14 caracteres
    if (raw.length != 14) return false;

    // Os dois últimos (DV) devem ser dígitos
    if (!RegExp(r'^[0-9]{2}$').hasMatch(raw.substring(12))) return false;

    // CNPJs com todos os caracteres iguais são inválidos (ex: "00000000000000")
    if (raw.split('').every((c) => c == raw[0])) return false;

    // Verifica 1.º DV
    final dv1 = _calcDv(raw.substring(0, 12), _w1);
    if (dv1 != int.parse(raw[12])) return false;

    // Verifica 2.º DV (usa os 12 primeiros + DV1 como 13.º elemento)
    final dv2 = _calcDv(raw.substring(0, 13), _w2);
    if (dv2 != int.parse(raw[13])) return false;

    return true;
  }
}

/// [TextInputFormatter] que aplica automaticamente a máscara de CNPJ
/// `AA.AAA.AAA/AAAA-DV`, aceitando letras (A–Z) e dígitos (0–9).
///
/// Compatível com o formato numérico atual e com o novo alfanumérico.
class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extrai apenas alfanuméricos e converte para maiúsculo
    final raw = newValue.text
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();

    // Limita a 14 caracteres brutos
    final limited = raw.length > 14 ? raw.substring(0, 14) : raw;

    final masked = _applyMask(limited);

    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }

  /// Aplica a máscara progressivamente conforme o usuário digita.
  String _applyMask(String raw) {
    final buf = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i == 2 || i == 5) buf.write('.');
      if (i == 8) buf.write('/');
      if (i == 12) buf.write('-');
      buf.write(raw[i]);
    }
    return buf.toString();
  }
}

