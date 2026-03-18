import '../../../data/models/point_model.dart';
import 'recognition_source.dart';
import 'recognition_status.dart';

/// Resultado emitido pelo motor de fusão para um ciclo de análise.
class RecognitionResult {
  final String pointId;
  final double confidence;
  final RecognitionSource source;
  final RecognitionStatus status;

  /// Ponto sugerido ou confirmado. Null quando status é [RecognitionStatus.idle]
  /// ou [RecognitionStatus.lost].
  final PointModel? point;

  const RecognitionResult({
    required this.pointId,
    required this.confidence,
    required this.source,
    required this.status,
    this.point,
  });

  /// Resultado vazio usado como estado inicial.
  const RecognitionResult.empty()
      : pointId = '',
        confidence = 0.0,
        source = RecognitionSource.none,
        status = RecognitionStatus.idle,
        point = null;

  @override
  String toString() =>
      'RecognitionResult($pointId, conf=$confidence, src=$source, '
      'status=$status)';
}
