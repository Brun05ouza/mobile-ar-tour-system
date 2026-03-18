package com.brunoouza.ar_tour.models

/**
 * Candidato a reconhecimento no pipeline híbrido.
 *
 * Contém o identificador do ponto e os scores parciais de cada componente,
 * além do score final calculado pelo [RecognitionFusionManager].
 *
 * @param pointId        ID do ponto (ex: "point_001")
 * @param pointName      Nome legível para logs e UI
 * @param latitude       Coordenada do ponto
 * @param longitude      Coordenada do ponto
 * @param imageReference Referência do marker ARCore (ex: "marker_01")
 * @param geoScore       Score de proximidade [0.0, 1.0]
 * @param markerScore    Score do marker ARCore [0.0, 1.0]
 * @param visualScore    Score visual OpenCV/ORB [0.0, 1.0] — 0.0 enquanto não integrado
 * @param finalScore     Score ponderado final calculado pelo FusionManager
 */
data class RecognitionCandidate(
    val pointId: String,
    val pointName: String,
    val latitude: Double,
    val longitude: Double,
    val imageReference: String,
    val geoScore: Float = 0f,
    val markerScore: Float = 0f,
    val visualScore: Float = 0f,
    val finalScore: Float = 0f
) {
    /** Converte para Map para serialização no EventChannel. */
    fun toMap(): Map<String, Any> = mapOf(
        "pointId"        to pointId,
        "pointName"      to pointName,
        "geoScore"       to geoScore,
        "markerScore"    to markerScore,
        "visualScore"    to visualScore,
        "finalScore"     to finalScore
    )
}
