package com.brunoouza.ar_tour

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.google.ar.core.AugmentedImage
import com.google.ar.core.AugmentedImageDatabase
import com.google.ar.core.ArCoreApk
import com.google.ar.core.Config
import com.google.ar.core.Session
import com.google.ar.core.TrackingState
import com.google.ar.core.exceptions.CameraNotAvailableException
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10

class ArImageTrackingActivity : AppCompatActivity(), GLSurfaceView.Renderer {

    companion object {
        const val CHANNEL = "com.brunoouza.ar_tour/ar_detection"
        const val EXTRA_IMAGE_REF = "detected_image_reference"
        private const val TAG = "ArImageTracking"
    }

    private lateinit var surfaceView: GLSurfaceView
    private lateinit var statusText: TextView

    private var session: Session? = null
    private var displayRotationHelper: DisplayRotationHelper? = null
    private val backgroundRenderer = BackgroundRenderer()

    // Imagens cadastradas: nome_arquivo_sem_extensão → Pair(imageReference, largura física em metros)
    // A largura física ajuda o ARCore a detectar com muito mais precisão e velocidade
    private val imageMap = mapOf(
        "coca-cola"       to Pair("marker_01", 0.07f),   // lata ~7cm
        "cristo-redentor" to Pair("marker_02", 0.15f),   // foto impressa ~15cm
        "pao-de-acucar"   to Pair("marker_03", 0.15f)    // foto impressa ~15cm
    )

    private val detectedImages = mutableSetOf<String>()

    @Volatile private var finished = false
    private var frameCount = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_ar_tracking)

        surfaceView = findViewById(R.id.gl_surface_view)
        statusText  = findViewById(R.id.status_text)

        displayRotationHelper = DisplayRotationHelper(this)

        surfaceView.preserveEGLContextOnPause = true
        surfaceView.setEGLContextClientVersion(2)
        surfaceView.setEGLConfigChooser(8, 8, 8, 8, 16, 0)
        surfaceView.setRenderer(this)
        surfaceView.renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
    }

    override fun onResume() {
        super.onResume()

        if (session == null) {
            try {
                if (!ArCoreApk.getInstance().checkAvailability(this).isSupported) {
                    runOnUiThread { statusText.text = "ARCore não suportado neste dispositivo" }
                    return
                }

                val newSession = Session(this)
                val config = Config(newSession)
                config.augmentedImageDatabase = criarBancoDeImagens(newSession)
                config.focusMode = Config.FocusMode.AUTO
                config.updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE
                newSession.configure(config)
                session = newSession

            } catch (e: Exception) {
                Log.e(TAG, "Erro ao criar sessão ARCore", e)
                runOnUiThread { statusText.text = "Erro ao inicializar AR: ${e.message}" }
                return
            }
        }

        try {
            session?.resume()
        } catch (e: CameraNotAvailableException) {
            Log.e(TAG, "Câmera não disponível", e)
            session = null
            return
        }

        surfaceView.onResume()
        displayRotationHelper?.onResume()
        runOnUiThread { statusText.text = "Aponte a câmera para a imagem do ponto turístico..." }
    }

    override fun onPause() {
        super.onPause()
        surfaceView.onPause()
        session?.pause()
        displayRotationHelper?.onPause()
    }

    override fun onDestroy() {
        super.onDestroy()
        session?.close()
        session = null
    }

    private fun criarBancoDeImagens(session: Session): AugmentedImageDatabase {
        val db = AugmentedImageDatabase(session)
        for ((fileName, info) in imageMap) {
            val (reference, widthMeters) = info
            try {
                assets.open("images/$fileName.png").use { stream ->
                    val opts = BitmapFactory.Options().apply {
                        inPreferredConfig = Bitmap.Config.ARGB_8888
                    }
                    val bitmap = BitmapFactory.decodeStream(stream, null, opts)
                    if (bitmap != null) {
                        // widthInMeters informa ao ARCore o tamanho físico real — essencial para detecção
                        val index = db.addImage(reference, bitmap, widthMeters)
                        Log.d(TAG, "Imagem '$reference' adicionada (index=$index) — ${bitmap.width}x${bitmap.height}px, ${widthMeters}m")
                    } else {
                        Log.e(TAG, "Falha ao decodificar '$fileName.png'")
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar '$fileName.png': ${e.message}")
            }
        }
        Log.d(TAG, "Banco de imagens criado com ${db.numImages} imagem(ns)")
        return db
    }

    // ─── GLSurfaceView.Renderer ───────────────────────────────────────────────

    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        GLES20.glClearColor(0.1f, 0.1f, 0.1f, 1.0f)

        // Cria textura OES + shaders para renderizar o feed da câmera
        backgroundRenderer.createOnGlThread()

        // Informa ao ARCore a textura que deve usar para o feed
        session?.setCameraTextureName(backgroundRenderer.textureId)
    }

    override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
        displayRotationHelper?.onSurfaceChanged(width, height)
        GLES20.glViewport(0, 0, width, height)
    }

    override fun onDrawFrame(gl: GL10?) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)

        val currentSession = session ?: return

        // Textura precisa ser re-informada quando a sessão é criada no GL thread
        currentSession.setCameraTextureName(backgroundRenderer.textureId)

        displayRotationHelper?.updateSessionIfNeeded(currentSession)

        val frame = try {
            currentSession.update()
        } catch (e: CameraNotAvailableException) {
            Log.e(TAG, "Câmera não disponível no frame", e)
            return
        } catch (e: Exception) {
            Log.e(TAG, "Erro no update do frame", e)
            return
        }

        // Renderiza o feed da câmera como background
        backgroundRenderer.draw(frame)

        // Verifica imagens detectadas
        if (!finished) {
            frameCount++
            val trackables = currentSession.getAllTrackables(AugmentedImage::class.java)

            // Log a cada 60 frames para acompanhar estado
            if (frameCount % 60 == 0) {
                Log.d(TAG, "Frame $frameCount — trackables: ${trackables.size}")
                trackables.forEach { img ->
                    Log.d(TAG, "  → '${img.name}' estado: ${img.trackingState} / ${img.trackingMethod}")
                }
            }

            for (augmentedImage in trackables) {
                if (augmentedImage.trackingState == TrackingState.TRACKING) {
                    val ref = augmentedImage.name
                    if (!detectedImages.contains(ref)) {
                        detectedImages.add(ref)
                        Log.d(TAG, "✓ Imagem detectada: $ref")
                        notificarFlutter(ref)
                    }
                }
            }
        }
    }

    private fun notificarFlutter(imageReference: String) {
        if (finished) return
        finished = true
        runOnUiThread {
            statusText.text = "✓ Detectado: $imageReference"
            val resultIntent = intent
            resultIntent.putExtra(EXTRA_IMAGE_REF, imageReference)
            setResult(RESULT_OK, resultIntent)
            finish()
        }
    }

    @Suppress("UNUSED_PARAMETER")
    fun onCloseClicked(view: View) {
        setResult(RESULT_CANCELED)
        finish()
    }
}
