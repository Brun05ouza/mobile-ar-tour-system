package com.brunoouza.ar_tour.recognition

import android.util.Log
import com.brunoouza.ar_tour.models.RecognitionCandidate
import com.brunoouza.ar_tour.models.RecognitionResult
import com.brunoouza.ar_tour.models.RecognitionResultStatus
import com.brunoouza.ar_tour.models.RecognitionSource

/**
 * Motor de fusão dos sinais de reconhecimento.
 *
 * Regra de fusão:
 *   scoreFinal = marker * WEIGHT_MARKER + geo * WEIGHT_GEO + visual * WEIGHT_VISUAL
 *
 * Regra especial (marker domina):
 *   Se markerScore >= 0.9, o marker sozinho garante CONFIRMED independentemente dos
 *   outros scores. Isso é necessário porque em ambiente de desenvolvimento/teste
 *   o GPS pode não estar disponível (geoScore=0) e o visual ainda é placeholder (0),
 *   mas o marker foi fisicamente reconhecido pela câmera — deve confirmar.
 *
 * Sem marker detectado:
 *   scoreFinal >= THRESHOLD_AUTO   → CONFIRMED
 *   scoreFinal >= THRESHOLD_SUGGEST → SUGGESTION
 *   scoreFinal <  THRESHOLD_SUGGEST → NONE
 */
object RecognitionFusionManager {

    private const val TAG = "FusionManager"

    /**
     * Combina os scores de [candidate] e retorna o [RecognitionResult].
     */
    fun fuse(candidate: RecognitionCandidate): RecognitionResult {
        val markerScore = candidate.markerScore
        val geoScore    = candidate.geoScore
        val visualScore = candidate.visualScore

        // Regra especial: marker detectado fisicamente → confirma imediatamente.
        // O score final reportado é 1.0 para indicar alta confiança ao Flutter.
        if (markerScore >= 0.9f) {
            val scoreFinal = 1.0f
            Log.d(TAG, "Marker dominante '${candidate.pointId}': score=1.0 → CONFIRMED")
            return RecognitionResult(
                pointId    = candidate.pointId,
                pointName  = candidate.pointName,
                confidence = scoreFinal,
                source     = RecognitionSource.MARKER_ONLY,
                status     = RecognitionResultStatus.CONFIRMED,
                candidate  = candidate.copy(finalScore = scoreFinal)
            )
        }

        // Fusão contextual (sem marker): geo + visual
        val scoreFinal = markerScore * RecognitionConstants.WEIGHT_MARKER +
                         geoScore    * RecognitionConstants.WEIGHT_GEO +
                         visualScore * RecognitionConstants.WEIGHT_VISUAL

        val status = when {
            scoreFinal >= RecognitionConstants.THRESHOLD_AUTO    -> RecognitionResultStatus.CONFIRMED
            scoreFinal >= RecognitionConstants.THRESHOLD_SUGGEST -> RecognitionResultStatus.SUGGESTION
            else                                                  -> RecognitionResultStatus.NONE
        }

        Log.d(TAG, "Fusão contextual '${candidate.pointId}': " +
                "marker=$markerScore geo=$geoScore visual=$visualScore " +
                "→ final=$scoreFinal status=$status")

        return RecognitionResult(
            pointId    = candidate.pointId,
            pointName  = candidate.pointName,
            confidence = scoreFinal,
            source     = RecognitionSource.CONTEXTUAL,
            status     = status,
            candidate  = candidate.copy(finalScore = scoreFinal)
        )
    }

    /**
     * Aplica fusão em todos os candidatos e retorna o melhor resultado.
     */
    fun fuseAll(candidates: List<RecognitionCandidate>): RecognitionResult {
        if (candidates.isEmpty()) return RecognitionResult.none()

        val results = candidates.map { fuse(it) }
        val best = results.maxByOrNull { it.confidence } ?: return RecognitionResult.none()

        if (best.status == RecognitionResultStatus.NONE) {
            Log.d(TAG, "Nenhum candidato acima do threshold mínimo (${RecognitionConstants.THRESHOLD_SUGGEST})")
        }

        return best
    }
}
