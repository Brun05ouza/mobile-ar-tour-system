package com.brunoouza.ar_tour.models

/**
 * Resultado emitido pelo [RecognitionFusionManager] após um ciclo de análise.
 *
 * @param pointId    ID do ponto reconhecido (vazio se nenhum)
 * @param pointName  Nome legível do ponto
 * @param confidence Score final de confiança [0.0, 1.0]
 * @param source     Componente que dominou a decisão
 * @param status     Ação resultante da decisão
 * @param candidate  Candidato completo com scores parciais (para debug)
 */
data class RecognitionResult(
    val pointId: String,
    val pointName: String,
    val confidence: Float,
    val source: RecognitionSource,
    val status: RecognitionResultStatus,
    val candidate: RecognitionCandidate? = null
) {
    /** Converte para Map para serialização no EventChannel. */
    fun toMap(): Map<String, Any?> = mapOf(
        "pointId"    to pointId,
        "pointName"  to pointName,
        "confidence" to confidence,
        "source"     to source.name,
        "status"     to status.name,
        "candidate"  to candidate?.toMap()
    )

    companion object {
        /** Resultado vazio — nenhum reconhecimento. */
        fun none() = RecognitionResult(
            pointId    = "",
            pointName  = "",
            confidence = 0f,
            source     = RecognitionSource.NONE,
            status     = RecognitionResultStatus.NONE
        )
    }
}

/** Origem que dominou a decisão de reconhecimento. */
enum class RecognitionSource {
    /** Reconhecimento pelo marker ARCore. */
    MARKER_ONLY,
    /** Reconhecimento por geolocalização + visual. */
    CONTEXTUAL,
    /** Fusão de marker + geo + visual. */
    HYBRID,
    /** Nenhuma fonte com score suficiente. */
    NONE
}

/** Ação que o Flutter deve executar com base no resultado. */
enum class RecognitionResultStatus {
    /** Confirmar automaticamente (score >= THRESHOLD_AUTO). */
    CONFIRMED,
    /** Exibir sugestão ao usuário (score >= THRESHOLD_SUGGEST). */
    SUGGESTION,
    /** Score insuficiente — não fazer nada. */
    NONE
}
