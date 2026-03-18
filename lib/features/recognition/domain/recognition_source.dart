/// Origem que dominou a decisão de reconhecimento.
enum RecognitionSource {
  /// Reconhecimento baseado exclusivamente no marker ARCore.
  markerOnly,

  /// Reconhecimento baseado em geolocalização + comparação visual.
  contextual,

  /// Reconhecimento híbrido com contribuição de marker + geo + visual.
  hybrid,

  /// Nenhuma fonte com score suficiente.
  none,
}
