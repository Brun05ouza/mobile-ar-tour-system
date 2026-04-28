package com.brunoouza.ar_tour.recognition

/**
 * Constantes centralizadas do sistema de reconhecimento híbrido.
 *
 * Altere aqui para calibrar o comportamento do pipeline sem tocar
 * na lógica de cada manager.
 *
 * Pesos de fusão (devem somar 1.0):
 *   WEIGHT_MARKER + WEIGHT_GEO + WEIGHT_VISUAL = 1.0
 *
 * Thresholds de decisão:
 *   score >= THRESHOLD_AUTO   → confirmar automaticamente
 *   score >= THRESHOLD_SUGGEST → sugerir ao usuário
 *   score <  THRESHOLD_SUGGEST → ignorar
 */
object RecognitionConstants {

    // ── Pesos de fusão ────────────────────────────────────────────────────────
    /** Peso do componente de marker ARCore na fusão. */
    const val WEIGHT_MARKER = 0.55f
    /** Peso do componente de geolocalização na fusão. */
    const val WEIGHT_GEO = 0.20f
    /** Peso do componente visual (OpenCV/ORB) na fusão. */
    const val WEIGHT_VISUAL = 0.25f

    // ── Thresholds de decisão ─────────────────────────────────────────────────
    /** Score mínimo para confirmação automática do local. */
    const val THRESHOLD_AUTO = 0.90f
    /** Score mínimo para exibir sugestão ao usuário. */
    const val THRESHOLD_SUGGEST = 0.65f

    // ── Geolocalização ────────────────────────────────────────────────────────
    /** Raio de busca de candidatos próximos, em metros. */
    const val GEO_RADIUS_METERS = 300.0

    // ── Pipeline visual ───────────────────────────────────────────────────────
    /**
     * Intervalo mínimo entre análises visuais, em milissegundos.
     * Frames são descartados se o pipeline estiver ocupado.
     */
    const val VISUAL_INTERVAL_MS = 800L

    // ── Platform Channels ─────────────────────────────────────────────────────
    /** Canal de eventos (EventChannel) para envio de resultados ao Flutter. */
    const val EVENT_CHANNEL = "com.brunoouza.ar_tour/recognition_events"
    /** Canal de controle (MethodChannel) para receber comandos do Flutter. */
    const val METHOD_CHANNEL = "com.brunoouza.ar_tour/recognition_control"

    // ── Nomes dos eventos emitidos ────────────────────────────────────────────
    const val EVENT_MARKER_DETECTED    = "onMarkerDetected"
    const val EVENT_VISUAL_MATCH       = "onVisualMatch"
    const val EVENT_SUGGESTION         = "onRecognitionSuggestion"
    const val EVENT_CONFIRMED          = "onRecognitionConfirmed"
    const val EVENT_LOST               = "onRecognitionLost"
    const val EVENT_DEBUG              = "onRecognitionDebugInfo"
    const val EVENT_LOCATION_UPDATE    = "onLocationUpdate"
    /** Falha ao iniciar ou retomar sessão ARCore (ex.: sensores). */
    const val EVENT_SESSION_FAILED     = "onArSessionFailed"
}
