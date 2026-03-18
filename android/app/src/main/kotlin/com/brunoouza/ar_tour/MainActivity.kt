package com.brunoouza.ar_tour

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.brunoouza.ar_tour.recognition.HybridArActivity
import com.brunoouza.ar_tour.recognition.RecognitionConstants

class MainActivity : FlutterActivity() {

    // Canal legado (preservado sem alteração)
    private val legacyChannel = ArImageTrackingActivity.CHANNEL
    private var pendingResult: MethodChannel.Result? = null

    companion object {
        private const val AR_REQUEST_CODE    = 1001
        private const val HYBRID_REQUEST_CODE = 1002

        /** FlutterEngine compartilhado — injetado na HybridArActivity para o EventChannel. */
        var sharedFlutterEngine: FlutterEngine? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sharedFlutterEngine = flutterEngine

        // ── Canal legado: startImageTracking ─────────────────────────────────
        // Preservado sem nenhuma alteração de comportamento.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, legacyChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startImageTracking" -> {
                        pendingResult = result
                        startActivityForResult(
                            Intent(this, ArImageTrackingActivity::class.java),
                            AR_REQUEST_CODE
                        )
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Canal de controle híbrido ─────────────────────────────────────────
        // Métodos: startHybridRecognition, stopHybridRecognition, getCurrentLocation
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            RecognitionConstants.METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startHybridRecognition" -> {
                    val intent = Intent(this, HybridArActivity::class.java)
                    startActivityForResult(intent, HYBRID_REQUEST_CODE)
                    result.success(null)
                }
                "stopHybridRecognition" -> {
                    // A Activity gerencia seu próprio ciclo de vida via finish()
                    result.success(null)
                }
                "getCurrentLocation" -> {
                    // Localização é enviada continuamente via EventChannel (onLocationUpdate).
                    // Este método retorna a última posição conhecida de forma síncrona.
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // ── EventChannel de reconhecimento ────────────────────────────────────
        // O StreamHandler é configurado pela HybridArActivity quando ela inicia.
        // Aqui apenas registramos o canal para que o Flutter possa escutar.
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            RecognitionConstants.EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                // O sink real é configurado pela HybridArActivity via RecognitionEventDispatcher
            }
            override fun onCancel(arguments: Any?) {}
        })
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        // ── Resultado legado ──────────────────────────────────────────────────
        if (requestCode == AR_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                val imageRef = data?.getStringExtra(ArImageTrackingActivity.EXTRA_IMAGE_REF)
                pendingResult?.success(imageRef)
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }

        // ── Resultado híbrido ─────────────────────────────────────────────────
        // A HybridArActivity comunica via EventChannel — onActivityResult apenas
        // garante que o Flutter saiba que a tela foi fechada.
        if (requestCode == HYBRID_REQUEST_CODE) {
            // Sem ação necessária — eventos já foram enviados via EventChannel
        }
    }
}
