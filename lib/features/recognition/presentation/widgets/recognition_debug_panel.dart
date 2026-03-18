import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/recognition_candidate.dart';
import '../../domain/recognition_state_model.dart';

/// Painel de debug do pipeline de reconhecimento.
///
/// Visível apenas em modo debug ([kDebugMode]).
/// Exibe: localização, candidatos próximos, scores por candidato,
/// origem da decisão e última mensagem de debug.
class RecognitionDebugPanel extends StatelessWidget {
  final RecognitionStateModel state;

  const RecognitionDebugPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DEBUG',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'status: ${state.status.name}',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Localização
          _row('GPS',
              state.locationLoaded
                  ? '${state.userLat?.toStringAsFixed(4) ?? '-'}, '
                      '${state.userLon?.toStringAsFixed(4) ?? '-'}'
                  : 'não disponível'),

          // Candidatos
          _row('Candidatos', '${state.nearbyCandidates.length} próximos'),

          // Confidence
          _row('Confiança',
              '${(state.recognitionConfidence * 100).toStringAsFixed(1)}%'),

          // Marker / Visual
          _row('Marker', state.markerDetected ? 'detectado' : 'não'),

          // Candidatos com scores
          if (state.nearbyCandidates.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'SCORES POR CANDIDATO',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            ...state.nearbyCandidates
                .map((c) => _candidateRow(c))
                .toList(),
          ],

          // Última mensagem de debug
          if (state.lastDebugMessage.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                state.lastDebugMessage,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 10),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _candidateRow(RecognitionCandidate c) {
    final score = c.finalScore;
    final color = score >= 0.9
        ? Colors.greenAccent
        : score >= 0.65
            ? Colors.amberAccent
            : Colors.white38;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              c.point.name,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'g=${c.geoScore.toStringAsFixed(2)} '
            'm=${c.markerScore.toStringAsFixed(2)} '
            'v=${c.visualScore.toStringAsFixed(2)} '
            'f=${score.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
