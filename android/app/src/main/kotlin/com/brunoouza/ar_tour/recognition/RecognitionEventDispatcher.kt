package com.brunoouza.ar_tour.recognition

import android.util.Log
import com.brunoouza.ar_tour.models.RecognitionCandidate
import com.brunoouza.ar_tour.models.RecognitionResult
import com.brunoouza.ar_tour.models.RecognitionResultStatus
import io.flutter.plugin.common.EventChannel

/**
 * Singleton que despacha eventos do pipeline de reconhecimento para o Flutter.
 *
 * O sink é gerenciado pelo StreamHandler registrado no MainActivity.
 * A HybridArActivity apenas chama os métodos dispatch* — não precisa conhecer
 * o FlutterEngine nem configurar o EventChannel diretamente.
 *
 * Fluxo:
 *   MainActivity.configureFlutterEngine → EventChannel.setStreamHandler
 *   onListen → RecognitionEventDispatcher.setSink(events)
 *   HybridArActivity → dispatch*() → sink.success(data)
 *   onCancel → RecognitionEventDispatcher.clearSink()
 */
object RecognitionEventDispatcher {

    private const val TAG = "EventDispatcher"

    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    /** Define o sink ativo — chamado pelo StreamHandler em onListen. */
    fun setSink(sink: EventChannel.EventSink?) {
        eventSink = sink
        Log.d(TAG, if (sink != null) "EventSink conectado" else "EventSink desconectado")
    }

    /** Remove o sink — chamado pelo StreamHandler em onCancel. */
    fun clearSink() {
        eventSink = null
        Log.d(TAG, "EventSink limpo")
    }

    // ── Métodos de despacho ───────────────────────────────────────────────────

    /** Marker ARCore detectado. */
    fun dispatchMarkerDetected(pointId: String, markerRef: String, confidence: Float) {
        send(mapOf(
            "type"       to RecognitionConstants.EVENT_MARKER_DETECTED,
            "pointId"    to pointId,
            "markerRef"  to markerRef,
            "confidence" to confidence
        ))
        Log.d(TAG, "Marker detectado: pointId=$pointId markerRef=$markerRef conf=$confidence")
    }

    /** Despacha resultado baseado no status da fusão. */
    fun dispatchResult(result: RecognitionResult) {
        when (result.status) {
            RecognitionResultStatus.CONFIRMED ->
                dispatchConfirmed(result.pointId, result.pointName, result.confidence, result.source.name)
            RecognitionResultStatus.SUGGESTION ->
                dispatchSuggestion(result.pointId, result.pointName, result.confidence)
            RecognitionResultStatus.NONE -> { /* Abaixo do threshold — não emitir */ }
        }
    }

    /** Reconhecimento confirmado automaticamente (score >= THRESHOLD_AUTO). */
    fun dispatchConfirmed(pointId: String, pointName: String, score: Float, source: String) {
        send(mapOf(
            "type"      to RecognitionConstants.EVENT_CONFIRMED,
            "pointId"   to pointId,
            "pointName" to pointName,
            "score"     to score,
            "source"    to source
        ))
        Log.d(TAG, "CONFIRMADO: $pointId (score=$score, src=$source)")
    }

    /** Sugestão para o usuário confirmar (score entre THRESHOLD_SUGGEST e THRESHOLD_AUTO). */
    fun dispatchSuggestion(pointId: String, pointName: String, score: Float) {
        send(mapOf(
            "type"      to RecognitionConstants.EVENT_SUGGESTION,
            "pointId"   to pointId,
            "pointName" to pointName,
            "score"     to score
        ))
        Log.d(TAG, "Sugestão: $pointId (score=$score)")
    }

    /** Reconhecimento perdido — marker saiu do campo de visão. */
    fun dispatchLost(pointId: String) {
        send(mapOf(
            "type"    to RecognitionConstants.EVENT_LOST,
            "pointId" to pointId
        ))
        Log.d(TAG, "Reconhecimento perdido: $pointId")
    }

    /** Atualização de localização GPS. */
    fun dispatchLocationUpdate(lat: Double, lon: Double, accuracy: Float) {
        send(mapOf(
            "type"     to RecognitionConstants.EVENT_LOCATION_UPDATE,
            "lat"      to lat,
            "lon"      to lon,
            "accuracy" to accuracy
        ))
    }

    /** Sessão ARCore não pôde ser iniciada (FatalException, etc.). */
    fun dispatchSessionFailed(message: String) {
        send(mapOf(
            "type" to RecognitionConstants.EVENT_SESSION_FAILED,
            "message" to message
        ))
        Log.w(TAG, "Sessão AR falhou: $message")
    }

    /** Informações de debug do pipeline (visível no RecognitionDebugPanel). */
    fun dispatchDebug(message: String, candidates: List<RecognitionCandidate> = emptyList()) {
        send(mapOf(
            "type"       to RecognitionConstants.EVENT_DEBUG,
            "message"    to message,
            "candidates" to candidates.map { it.toMap() }
        ))
    }

    // ── Envio seguro (main thread safe) ──────────────────────────────────────

    private fun send(data: Map<String, Any?>) {
        val sink = eventSink ?: run {
            Log.w(TAG, "EventSink nulo — evento descartado: ${data["type"]}")
            return
        }
        try {
            sink.success(data)
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao enviar evento ${data["type"]}: ${e.message}")
        }
    }
}
