import '../../../data/models/point_model.dart';

/// Candidato a ser reconhecido no pipeline híbrido.
///
/// Contém o ponto e os scores parciais de cada componente,
/// além do score final calculado pelo [RecognitionFusionManager].
class RecognitionCandidate {
  final PointModel point;

  /// Score de proximidade geográfica [0.0, 1.0].
  /// 1.0 = usuário está exatamente sobre o ponto; 0.0 = fora do raio.
  final double geoScore;

  /// Score do marker ARCore [0.0, 1.0].
  /// 1.0 = marker detectado em TrackingState.TRACKING.
  final double markerScore;

  /// Score visual por ORB/OpenCV [0.0, 1.0].
  /// 0.0 enquanto OpenCV não estiver integrado.
  final double visualScore;

  /// Score final ponderado: marker*0.55 + geo*0.20 + visual*0.25
  final double finalScore;

  const RecognitionCandidate({
    required this.point,
    this.geoScore = 0.0,
    this.markerScore = 0.0,
    this.visualScore = 0.0,
    this.finalScore = 0.0,
  });

  RecognitionCandidate copyWith({
    double? geoScore,
    double? markerScore,
    double? visualScore,
    double? finalScore,
  }) =>
      RecognitionCandidate(
        point: point,
        geoScore: geoScore ?? this.geoScore,
        markerScore: markerScore ?? this.markerScore,
        visualScore: visualScore ?? this.visualScore,
        finalScore: finalScore ?? this.finalScore,
      );

  @override
  String toString() =>
      'RecognitionCandidate(${point.id}, geo=$geoScore, marker=$markerScore, '
      'visual=$visualScore, final=$finalScore)';
}
