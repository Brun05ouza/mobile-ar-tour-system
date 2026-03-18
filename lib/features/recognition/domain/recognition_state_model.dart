import '../../../data/models/point_model.dart';
import 'recognition_candidate.dart';
import 'recognition_status.dart';

/// Estado imutável do sistema de reconhecimento híbrido.
///
/// Gerenciado pelo [RecognitionNotifier] via Riverpod.
class RecognitionStateModel {
  /// Estado atual do pipeline.
  final RecognitionStatus status;

  /// Pontos próximos filtrados por raio geográfico.
  final List<RecognitionCandidate> nearbyCandidates;

  /// Ponto sugerido com score médio (aguarda confirmação do usuário).
  final PointModel? suggestedPoint;

  /// Ponto confirmado com score alto (card aberto automaticamente).
  final PointModel? confirmedPoint;

  /// Score de confiança do melhor candidato atual [0.0, 1.0].
  final double recognitionConfidence;

  /// True se um marker ARCore foi detectado no frame atual.
  final bool markerDetected;

  /// True se a localização GPS foi obtida com sucesso.
  final bool locationLoaded;

  /// Última mensagem de debug do pipeline (visível no RecognitionDebugPanel).
  final String lastDebugMessage;

  /// Latitude/longitude do usuário, se disponíveis.
  final double? userLat;
  final double? userLon;

  const RecognitionStateModel({
    this.status = RecognitionStatus.idle,
    this.nearbyCandidates = const [],
    this.suggestedPoint,
    this.confirmedPoint,
    this.recognitionConfidence = 0.0,
    this.markerDetected = false,
    this.locationLoaded = false,
    this.lastDebugMessage = '',
    this.userLat,
    this.userLon,
  });

  const RecognitionStateModel.initial() : this();

  RecognitionStateModel copyWith({
    RecognitionStatus? status,
    List<RecognitionCandidate>? nearbyCandidates,
    PointModel? suggestedPoint,
    bool clearSuggested = false,
    PointModel? confirmedPoint,
    bool clearConfirmed = false,
    double? recognitionConfidence,
    bool? markerDetected,
    bool? locationLoaded,
    String? lastDebugMessage,
    double? userLat,
    double? userLon,
  }) =>
      RecognitionStateModel(
        status: status ?? this.status,
        nearbyCandidates: nearbyCandidates ?? this.nearbyCandidates,
        suggestedPoint:
            clearSuggested ? null : (suggestedPoint ?? this.suggestedPoint),
        confirmedPoint:
            clearConfirmed ? null : (confirmedPoint ?? this.confirmedPoint),
        recognitionConfidence:
            recognitionConfidence ?? this.recognitionConfidence,
        markerDetected: markerDetected ?? this.markerDetected,
        locationLoaded: locationLoaded ?? this.locationLoaded,
        lastDebugMessage: lastDebugMessage ?? this.lastDebugMessage,
        userLat: userLat ?? this.userLat,
        userLon: userLon ?? this.userLon,
      );
}
