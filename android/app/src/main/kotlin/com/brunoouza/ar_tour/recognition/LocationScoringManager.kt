package com.brunoouza.ar_tour.recognition

import android.location.Location
import android.util.Log
import com.brunoouza.ar_tour.models.RecognitionCandidate
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Calcula scores de proximidade geográfica e filtra candidatos por raio.
 *
 * Score linear: score = max(0, 1 - distância/raio)
 * Quanto mais próximo, maior o score. Pontos fora do raio ficam com score 0
 * e são excluídos da lista de candidatos.
 */
object LocationScoringManager {

    private const val TAG = "LocationScoring"

    /**
     * Filtra [allPoints] pelo raio e retorna [RecognitionCandidate]s com geoScore.
     *
     * @param allPoints  Lista de todos os pontos (id, name, lat, lon, imageRef)
     * @param userLocation Posição atual do usuário (null → lista vazia)
     * @param radiusMeters Raio de busca em metros
     */
    fun filterCandidates(
        allPoints: List<PointData>,
        userLocation: Location?,
        radiusMeters: Double = RecognitionConstants.GEO_RADIUS_METERS
    ): List<RecognitionCandidate> {
        if (userLocation == null) {
            Log.w(TAG, "Localização nula — sem candidatos geográficos")
            return emptyList()
        }

        val candidates = allPoints.mapNotNull { p ->
            val dist = haversineMeters(
                userLocation.latitude, userLocation.longitude,
                p.latitude, p.longitude
            )
            if (dist > radiusMeters) return@mapNotNull null

            val score = computeScore(dist, radiusMeters)
            Log.d(TAG, "Candidato '${p.name}': dist=${dist.toInt()}m, geoScore=$score")

            RecognitionCandidate(
                pointId        = p.id,
                pointName      = p.name,
                latitude       = p.latitude,
                longitude      = p.longitude,
                imageReference = p.imageReference,
                geoScore       = score
            )
        }

        Log.d(TAG, "${candidates.size} candidato(s) dentro do raio de ${radiusMeters.toInt()}m")
        return candidates
    }

    /**
     * Calcula score linear de proximidade [0.0, 1.0].
     *
     * score = max(0, 1 - distância/raio)
     */
    fun computeScore(distanceMeters: Double, radiusMeters: Double): Float {
        return (1.0 - distanceMeters / radiusMeters).coerceIn(0.0, 1.0).toFloat()
    }

    /** Distância haversine entre dois pontos geográficos, em metros. */
    fun haversineMeters(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val r = 6_371_000.0
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val a = sin(dLat / 2).pow(2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) * sin(dLon / 2).pow(2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return r * c
    }
}

/**
 * Dados mínimos de um ponto necessários para o scoring geográfico.
 * Desacopla o scoring de JSON parsing e do PointModel.
 */
data class PointData(
    val id: String,
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val imageReference: String
)
