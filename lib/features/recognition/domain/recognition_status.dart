/// Estados do pipeline de reconhecimento híbrido.
///
/// Fluxo normal: idle → analyzing → suggestion/confirmed
/// Ao perder tracking: confirmed/suggestion → lost → analyzing
enum RecognitionStatus {
  /// Câmera aberta, aguardando início da análise ou sem candidatos próximos.
  idle,

  /// Pipeline ativo, analisando frames e localização.
  analyzing,

  /// Score ≥ threshold de sugestão mas < threshold de confirmação automática.
  suggestion,

  /// Score ≥ threshold de confirmação — card aberto automaticamente.
  confirmed,

  /// Reconhecimento previamente confirmado foi perdido (marker saiu do campo).
  lost,
}
