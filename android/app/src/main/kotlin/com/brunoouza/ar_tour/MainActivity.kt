package com.brunoouza.ar_tour

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.brunoouza.ar_tour.recognition.HybridArActivity
import com.brunoouza.ar_tour.recognition.RecognitionConstants
import com.brunoouza.ar_tour.recognition.RecognitionEventDispatcher

class MainActivity : FlutterActivity() {

    private val legacyChannel = ArImageTrackingActivity.CHANNEL
    private var pendingResult: MethodChannel.Result? = null

    companion object {
        private const val AR_REQUEST_CODE     = 1001
        private const val HYBRID_REQUEST_CODE = 1002
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Canal legado (preservado sem alteração) ───────────────────────────
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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            RecognitionConstants.METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startHybridRecognition" -> {
                    startActivityForResult(
                        Intent(this, HybridArActivity::class.java),
                        HYBRID_REQUEST_CODE
                    )
                    result.success(null)
                }
                "stopHybridRecognition" -> result.success(null)
                "getCurrentLocation"    -> result.success(null)
                else -> result.notImplemented()
            }
        }

        // ── EventChannel de reconhecimento ────────────────────────────────────
        // O StreamHandler repassa o sink para o singleton RecognitionEventDispatcher,
        // que é usado pela HybridArActivity para enviar eventos ao Flutter.
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            RecognitionConstants.EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                RecognitionEventDispatcher.setSink(events)
            }
            override fun onCancel(arguments: Any?) {
                RecognitionEventDispatcher.clearSink()
            }
        })
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == AR_REQUEST_CODE) {
            val imageRef = if (resultCode == Activity.RESULT_OK)
                data?.getStringExtra(ArImageTrackingActivity.EXTRA_IMAGE_REF)
            else null
            pendingResult?.success(imageRef)
            pendingResult = null
        }
        // HYBRID_REQUEST_CODE: comunicação já foi feita via EventChannel
    }
}
