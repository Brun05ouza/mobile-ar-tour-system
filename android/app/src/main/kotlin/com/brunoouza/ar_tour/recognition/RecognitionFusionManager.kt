package com.brunoouza.ar_tour.recognition

import android.util.Log
import com.brunoouza.ar_tour.models.RecognitionCandidate
import com.brunoouza.ar_tour.models.RecognitionResult
import com.brunoouza.ar_tour.models.RecognitionResultStatus
import com.brunoouza.ar_tour.models.RecognitionSource

/**
 * Motor de fusão dos sinais de reconhecimento.
 *
 * Combina os scores de cada componente usando pesos configurados em
 * [RecognitionConstants] e decide a ação resultante:
 *
 *   scoreFinal = marker * WEIGHT_MARKER + geo * WEIGHT_GEO + visual * WEIGHT_VISUAL
 *
 * Regras especiais:
 *   - Se markerScore >= 0.9: source = MARKER_ONLY e score domina
 *   - scoreFinal >= THRESHOLD_AUTO   → CONFIRMED
 *   - scoreFinal >= THRESHOLD_SUGGEST → SUGGESTION
 *   - scoreFinal <  THRESHOLD_SUGGEST → NONE
 *
 * Extensão futura: adicionar novos componentes de score sem alterar a interface.
 */
object RecognitionFusionManager {

    private const val TAG = "FusionManager"

    /**
     * Combina os scores de [candidate] e retorna o [RecognitionResult].
     *
     * @param candidate Candidato com scores parciais já preenchidos.
     */
    fun fuse(candidate: RecognitionCandidate): RecognitionResult {
        val markerScore  = candidate.markerScore
        val geoScore     = candidate.geoScore
        val visualScore  = candidate.visualScore

        // Se marker detectado com alta confiança, ele domina a decisão
        val (source, scoreFinal) = if (markerScore >= 0.9f) {
            // Marker domina: usa apenas o peso do marker, complementado pelo geo
            // para evitar falsos positivos em locais diferentes
            val combined = markerScore * RecognitionConstants.WEIGHT_MARKER +
                           geoScore    * RecognitionConstants.WEIGHT_GEO +
                           visualScore * RecognitionConstants.WEIGHT_VISUAL
            RecognitionSource.MARKER_ONLY to combined
        } else {
            // Fusão contextual: geo + visual
            val combined = markerScore * RecognitionConstants.WEIGHT_MARKER +
                           geoScore    * RecognitionConstants.WEIGHT_GEO +
                           visualScore * RecognitionConstants.WEIGHT_VISUAL
            RecognitionSource.CONTEXTUAL to combined
        }

        val status = when {
            scoreFinal >= RecognitionConstants.THRESHOLD_AUTO    -> RecognitionResultStatus.CONFIRMED
            scoreFinal >= RecognitionConstants.THRESHOLD_SUGGEST -> RecognitionResultStatus.SUGGESTION
            else                                                  -> RecognitionResultStatus.NONE
        }

        Log.d(TAG, "Fusão '${candidate.pointId}': " +
                "marker=$markerScore geo=$geoScore visual=$visualScore " +
                "→ final=$scoreFinal src=$source status=$status")

        return RecognitionResult(
            pointId    = candidate.pointId,
            pointName  = candidate.pointName,
            confidence = scoreFinal,
            source     = source,
            status     = status,
            candidate  = candidate.copy(finalScore = scoreFinal)
        )
    }

    /**
     * Aplica fusão em todos os candidatos e retorna o melhor resultado.
     *
     * Retorna [RecognitionResult.none] se nenhum candidato atingir o threshold mínimo.
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
