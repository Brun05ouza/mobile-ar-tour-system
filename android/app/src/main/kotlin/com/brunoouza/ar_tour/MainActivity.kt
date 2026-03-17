package com.brunoouza.ar_tour

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = ArImageTrackingActivity.CHANNEL
    private var pendingResult: MethodChannel.Result? = null

    companion object {
        private const val AR_REQUEST_CODE = 1001
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startImageTracking" -> {
                        pendingResult = result
                        val intent = Intent(this, ArImageTrackingActivity::class.java)
                        startActivityForResult(intent, AR_REQUEST_CODE)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == AR_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                val imageRef = data?.getStringExtra(ArImageTrackingActivity.EXTRA_IMAGE_REF)
                pendingResult?.success(imageRef)
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }
}
