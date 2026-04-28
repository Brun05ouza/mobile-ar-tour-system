package com.brunoouza.ar_tour

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import com.google.ar.core.AugmentedImage
import com.google.ar.core.AugmentedImageDatabase
import com.google.ar.core.ArCoreApk
import com.google.ar.core.Config
import com.google.ar.core.Session
import com.google.ar.core.TrackingState
import com.google.ar.core.exceptions.CameraNotAvailableException
import com.google.ar.core.exceptions.FatalException
import com.google.ar.core.exceptions.SessionPausedException
import com.google.ar.core.exceptions.UnavailableDeviceNotCompatibleException
import com.google.ar.core.exceptions.UnavailableException
import com.google.ar.core.exceptions.UnavailableUserDeclinedInstallationException
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10

class ArImageTrackingActivity : AppCompatActivity(), GLSurfaceView.Renderer {

    companion object {
        const val CHANNEL = "com.brunoouza.ar_tour/ar_detection"
        const val EXTRA_IMAGE_REF = "detected_image_reference"
        private const val TAG = "ArImageTracking"
        private const val REQUEST_CAMERA = 3001
        /** Tentativas de session.resume() após FatalException (sensor queue / ARCore). */
        private const val MAX_FATAL_RESUME_RETRIES = 4
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

    private var fatalResumeRetryCount = 0

    /** Após INSTALL_REQUESTED do ArCoreApk — utilizador volta da Play Store e onResume corre outra vez. */
    private var arCoreInstallRequested = false

    /**
     * Sincroniza thread GL com session.pause()/resume(): sem isto, update() é chamado com sessão
     * já pausada → SessionPausedException e possível crash nativo (SIGSEGV) no ARCore.
     */
    @Volatile
    private var arSessionUpdatesEnabled = false

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
        fatalResumeRetryCount = 0
        arCoreInstallRequested = false
    }

    override fun onResume() {
        super.onResume()

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CAMERA),
                REQUEST_CAMERA
            )
            runOnUiThread { statusText.text = "Permissão de câmera necessária para o AR" }
            return
        }

        resumeArCoreSession()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_CAMERA) return
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            resumeArCoreSession()
        } else {
            Toast.makeText(
                this,
                "Sem permissão de câmera o AR não funciona.",
                Toast.LENGTH_LONG
            ).show()
            setResult(RESULT_CANCELED)
            finish()
        }
    }

    /** Cria (se preciso), retoma a sessão ARCore e o GLSurfaceView — exige CAMERA já concedida. */
    private fun resumeArCoreSession() {
        try {
            when (ArCoreApk.getInstance().requestInstall(this, arCoreInstallRequested)) {
                ArCoreApk.InstallStatus.INSTALL_REQUESTED -> {
                    arCoreInstallRequested = true
                    runOnUiThread {
                        statusText.text = "Instale ou atualize o Google Play Services para AR"
                    }
                    Log.d(TAG, "Pedido de instalação/atualização do ARCore ao utilizador")
                    return
                }
                ArCoreApk.InstallStatus.INSTALLED -> { /* continuar */ }
            }
        } catch (e: UnavailableDeviceNotCompatibleException) {
            Log.e(TAG, "Dispositivo incompatível com ARCore", e)
            runOnUiThread { statusText.text = "Este dispositivo não suporta ARCore." }
            return
        } catch (e: UnavailableUserDeclinedInstallationException) {
            Log.w(TAG, "Utilizador recusou instalar ARCore", e)
            Toast.makeText(this, "ARCore é necessário para esta funcionalidade.", Toast.LENGTH_LONG).show()
            setResult(RESULT_CANCELED)
            finish()
            return
        } catch (e: UnavailableException) {
            Log.e(TAG, "ARCore indisponível", e)
            runOnUiThread {
                statusText.text = "ARCore indisponível. Atualize o sistema e o Google Play Services."
            }
            return
        }

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
                // Menos trabalho para o pipeline nativo (só imagens aumentadas, sem planos):
                config.planeFindingMode = Config.PlaneFindingMode.DISABLED
                config.lightEstimationMode = Config.LightEstimationMode.DISABLED
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
            session?.close()
            session = null
            return
        } catch (e: FatalException) {
            Log.e(TAG, "ARCore FatalException ao retomar sessão (${fatalResumeRetryCount + 1}/$MAX_FATAL_RESUME_RETRIES)", e)
            try {
                session?.close()
            } catch (_: Exception) {
            }
            session = null
            if (fatalResumeRetryCount < MAX_FATAL_RESUME_RETRIES) {
                fatalResumeRetryCount++
                val delayMs = (350L shl (fatalResumeRetryCount - 1)).coerceAtMost(4000L)
                Handler(Looper.getMainLooper()).postDelayed({
                    if (isFinishing || isDestroyed) return@postDelayed
                    resumeArCoreSession()
                }, delayMs)
                return
            }
            runOnUiThread {
                Toast.makeText(
                    this,
                    "ARCore não iniciou (sensores). Atualize \"Google Play Services para AR\", reinicie o telefone e feche outras apps de câmera.",
                    Toast.LENGTH_LONG
                ).show()
                setResult(RESULT_CANCELED)
                finish()
            }
            return
        }

        fatalResumeRetryCount = 0
        arSessionUpdatesEnabled = true
        surfaceView.onResume()
        displayRotationHelper?.onResume()
        runOnUiThread { statusText.text = "Aponte a câmera para a imagem do ponto turístico..." }
    }

    override fun onPause() {
        // Antes de pausar a sessão: impede que a GLThread chame session.update() (race com pause).
        arSessionUpdatesEnabled = false
        super.onPause()
        displayRotationHelper?.onPause()
        surfaceView.onPause()
        session?.pause()
    }

    override fun onDestroy() {
        super.onDestroy()
        arSessionUpdatesEnabled = false
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

        if (!arSessionUpdatesEnabled) return
        val currentSession = session ?: return

        // Textura precisa ser re-informada quando a sessão é criada no GL thread
        currentSession.setCameraTextureName(backgroundRenderer.textureId)

        displayRotationHelper?.updateSessionIfNeeded(currentSession)

        val frame = try {
            currentSession.update()
        } catch (e: SessionPausedException) {
            return
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
