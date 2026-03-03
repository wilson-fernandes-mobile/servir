/// Constantes para compactação de imagens de perfil.
/// 
/// Ajuste esses valores para controlar o tamanho e qualidade das fotos:
/// - Valores menores = arquivos menores, mas qualidade pior
/// - Valores maiores = melhor qualidade, mas arquivos maiores
/// 
/// ⚠️ IMPORTANTE: Firestore tem limite de 1MB por documento!
/// O tamanho final da imagem em base64 deve ser < 900KB.
class ImageConstants {
  ImageConstants._();

  /// Largura mínima da imagem compactada (em pixels).
  /// Padrão: 256px
  /// 
  /// Valores sugeridos:
  /// - 128px = muito pequeno, arquivo ~20-40KB
  /// - 256px = pequeno, arquivo ~40-80KB (ATUAL)
  /// - 512px = médio, arquivo ~100-200KB
  /// - 1024px = grande, arquivo ~300-500KB
  static const int imageMinWidth = 256;

  /// Altura mínima da imagem compactada (em pixels).
  /// Padrão: 256px
  /// 
  /// Valores sugeridos:
  /// - 128px = muito pequeno
  /// - 256px = pequeno (ATUAL)
  /// - 512px = médio
  /// - 1024px = grande
  static const int imageMinHeight = 256;

  /// Qualidade da compactação JPEG (0-100).
  /// Padrão: 70
  /// 
  /// Valores sugeridos:
  /// - 50 = qualidade baixa, arquivo menor
  /// - 70 = qualidade média (ATUAL)
  /// - 85 = qualidade boa
  /// - 95 = qualidade alta, arquivo maior
  static const int imageQuality = 70;

  /// Tamanho máximo permitido para a imagem em base64 (em bytes).
  /// Padrão: 900000 (~900KB)
  /// 
  /// ⚠️ Firestore tem limite de 1MB por documento.
  /// Deixamos margem de segurança de ~100KB para outros campos.
  static const int maxBase64Size = 900000;
}

