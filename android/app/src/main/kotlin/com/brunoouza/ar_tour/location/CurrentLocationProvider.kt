package com.brunoouza.ar_tour.location

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.os.Looper
import android.util.Log
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

/**
 * Provedor de localização contínua usando FusedLocationProviderClient.
 *
 * Failsafe:
 *   - Se o GPS estiver desativado, [lastLocation] permanece null.
 *   - Erros de permissão não propagam exceção — apenas logam e param silenciosamente.
 *   - O chamador deve verificar permissões antes de chamar [start].
 *
 * Ciclo de vida: chame [start] ao abrir a Activity, [stop] ao pausar/destruir.
 */
class CurrentLocationProvider(context: Context) {

    companion object {
        private const val TAG = "LocationProvider"
        private const val UPDATE_INTERVAL_MS = 5_000L
        private const val FASTEST_INTERVAL_MS = 2_000L
    }

    private val client: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)

    /** Última localização conhecida. Null até a primeira atualização. */
    @Volatile
    var lastLocation: Location? = null
        private set

    /** Callback invocado a cada nova posição recebida. */
    var onLocationUpdate: ((Location) -> Unit)? = null

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            val loc = result.lastLocation ?: return
            lastLocation = loc
            Log.d(TAG, "Localização atualizada: lat=${loc.latitude}, lon=${loc.longitude}, acc=${loc.accuracy}m")
            onLocationUpdate?.invoke(loc)
        }
    }

    private val locationRequest = LocationRequest.Builder(
        Priority.PRIORITY_HIGH_ACCURACY,
        UPDATE_INTERVAL_MS
    )
        .setMinUpdateIntervalMillis(FASTEST_INTERVAL_MS)
        .build()

    /**
     * Inicia as atualizações de localização.
     *
     * Requer permissão ACCESS_FINE_LOCATION já concedida.
     */
    @SuppressLint("MissingPermission")
    fun start() {
        try {
            // Tenta obter última localização conhecida imediatamente
            client.lastLocation.addOnSuccessListener { loc ->
                if (loc != null) {
                    lastLocation = loc
                    Log.d(TAG, "Última localização conhecida: lat=${loc.latitude}, lon=${loc.longitude}")
                    onLocationUpdate?.invoke(loc)
                }
            }

            client.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )
            Log.d(TAG, "Atualizações de localização iniciadas")
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao iniciar localização: ${e.message}")
        }
    }

    /** Para as atualizações de localização. Deve ser chamado em onPause/onDestroy. */
    fun stop() {
        try {
            client.removeLocationUpdates(locationCallback)
            Log.d(TAG, "Atualizações de localização paradas")
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao parar localização: ${e.message}")
        }
    }
}
