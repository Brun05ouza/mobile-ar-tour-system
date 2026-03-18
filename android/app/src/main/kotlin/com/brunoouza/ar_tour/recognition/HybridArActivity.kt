package com.brunoouza.ar_tour.recognition

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import com.brunoouza.ar_tour.BackgroundRenderer
import com.brunoouza.ar_tour.DisplayRotationHelper
import com.brunoouza.ar_tour.R
import com.brunoouza.ar_tour.location.CurrentLocationProvider
import com.brunoouza.ar_tour.models.RecognitionCandidate
import com.brunoouza.ar_tour.models.RecognitionResultStatus
import com.google.ar.core.AugmentedImage
import com.google.ar.core.AugmentedImageDatabase
import com.google.ar.core.ArCoreApk
import com.google.ar.core.Config
import com.google.ar.core.Session
import com.google.ar.core.TrackingState
import com.google.ar.core.exceptions.CameraNotAvailableException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10

/**
 * Activity contínua de reconhecimento híbrido AR.
 *
 * Diferente da [ArImageTrackingActivity] (que fecha ao detectar um marker),
 * esta Activity mantém a sessão ARCore aberta e emite um stream contínuo
 * de eventos de reconhecimento para o Flutter via EventChannel.
 *
 * Fluxo de reconhecimento:
 *   1. Obtém localização e filtra candidatos próximos.
 *   2. ARCore detecta markers — markerScore = 1.0 para o candidato correspondente.
 *   3. VisualRecognitionManager analisa frames periodicamente (placeholder).
 *   4. RecognitionFusionManager combina scores e decide ação.
 *   5. RecognitionEventDispatcher emite evento ao Flutter.
 *
 * Ponto de extensão: para adicionar novos componentes de score, injete
 * o score em [currentCandidates] antes de chamar [runFusion].
 */
class HybridArActivity : AppCompatActivity(), GLSurfaceView.Renderer {

    companion object {
        private const val TAG = "HybridArActivity"
        private const val REQUEST_LOCATION = 2001
        private const val REQUEST_CAMERA   = 2002

        // Mesma estrutura do ArImageTrackingActivity original:
        // arquivo → Pair(imageReference, larguraFísicaEmMetros)
        private val IMAGE_MAP = mapOf(
            "coca-cola"       to Pair("marker_01", 0.07f),
            "cristo-redentor" to Pair("marker_02", 0.15f),
            "pao-de-acucar"   to Pair("marker_03", 0.15f)
        )
    }

    // ── UI ────────────────────────────────────────────────────────────────────
    private lateinit var surfaceView: GLSurfaceView
    private lateinit var statusText: TextView

    // ── ARCore ────────────────────────────────────────────────────────────────
    private var session: Session? = null
    private lateinit var displayRotationHelper: DisplayRotationHelper
    private val backgroundRenderer = BackgroundRenderer()

    // ── Localização ───────────────────────────────────────────────────────────
    private lateinit var locationProvider: CurrentLocationProvider

    // ── Reconhecimento ────────────────────────────────────────────────────────
    // eventDispatcher é singleton — o sink é gerenciado pelo MainActivity
    private val visualManager  = VisualRecognitionManager()
    private val coroutineScope = CoroutineScope(Dispatchers.Default)

    /** Candidatos filtrados pela localização atual. */
    @Volatile
    private var currentCandidates: List<RecognitionCandidate> = emptyList()

    /** IDs de pontos já confirmados nesta sessão (evita reenvios). */
    private val confirmedPoints = mutableSetOf<String>()

    /** Markers atualmente rastreados. */
    private val trackedMarkers = mutableSetOf<String>()

    private var frameCount = 0

    // ── Todos os pontos carregados do JSON ────────────────────────────────────
    private var allPoints: List<PointData> = emptyList()

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_ar_tracking)

        surfaceView = findViewById(R.id.gl_surface_view)
        statusText  = findViewById(R.id.status_text)

        displayRotationHelper = DisplayRotationHelper(this)
        locationProvider = CurrentLocationProvider(this)

        setupGlSurface()
        loadPointsFromAssets()
        requestCameraPermissionIfNeeded()
        requestLocationPermissionIfNeeded()
    }

    override fun onResume() {
        super.onResume()

        // Não inicializa ARCore sem permissão de câmera
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
            != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "Câmera sem permissão — aguardando concessão")
            runOnUiThread { statusText.text = "Permissão de câmera necessária" }
            return
        }

        if (session == null) {
            try {
                val availability = ArCoreApk.getInstance().checkAvailability(this)
                if (!availability.isSupported) {
                    runOnUiThread { statusText.text = "ARCore não suportado neste dispositivo" }
                    Log.e(TAG, "ARCore não suportado: $availability")
                    return
                }
                val newSession = Session(this)
                val config = Config(newSession).apply {
                    augmentedImageDatabase = buildImageDatabase(newSession)
                    focusMode = Config.FocusMode.AUTO
                    updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE
                }
                newSession.configure(config)
                session = newSession
                Log.d(TAG, "Sessão ARCore criada com sucesso")
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao criar sessão ARCore: ${e.javaClass.simpleName} — ${e.message}")
                runOnUiThread { statusText.text = "Erro AR: ${e.message}" }
                return
            }
        }

        try {
            session?.resume()
        } catch (e: CameraNotAvailableException) {
            Log.e(TAG, "Câmera não disponível ao resumir sessão", e)
            session = null
            runOnUiThread { statusText.text = "Câmera não disponível — feche outros apps" }
            return
        }

        surfaceView.onResume()
        displayRotationHelper.onResume()
        locationProvider.start()
        runOnUiThread { statusText.text = "Analisando ambiente..." }
        Log.d(TAG, "onResume: sessão AR ativa")
    }

    override fun onPause() {
        super.onPause()
        surfaceView.onPause()
        session?.pause()
        displayRotationHelper.onPause()
        locationProvider.stop()
    }

    override fun onDestroy() {
        super.onDestroy()
        session?.close()
        session = null
        coroutineScope.cancel()
    }

    // ── GLSurfaceView.Renderer ────────────────────────────────────────────────

    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        GLES20.glClearColor(0.1f, 0.1f, 0.1f, 1.0f)
        backgroundRenderer.createOnGlThread()
        session?.setCameraTextureName(backgroundRenderer.textureId)
    }

    override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
        displayRotationHelper.onSurfaceChanged(width, height)
        GLES20.glViewport(0, 0, width, height)
    }

    override fun onDrawFrame(gl: GL10?) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)
        val currentSession = session ?: return

        currentSession.setCameraTextureName(backgroundRenderer.textureId)
        displayRotationHelper.updateSessionIfNeeded(currentSession)

        val frame = try {
            currentSession.update()
        } catch (e: CameraNotAvailableException) {
            Log.e(TAG, "Câmera não disponível no frame", e)
            return
        } catch (e: Exception) {
            Log.e(TAG, "Erro no update do frame: ${e.message}")
            return
        }

        backgroundRenderer.draw(frame)

        frameCount++

        // Log periódico de estado
        if (frameCount % 90 == 0) {
            val loc = locationProvider.lastLocation
            Log.d(TAG, "Frame $frameCount — candidatos: ${currentCandidates.size}, " +
                    "loc: ${loc?.latitude?.toString()?.take(7) ?: "null"}")
        }

        // ── Detecção de markers ──────────────────────────────────────────────
        val trackables = currentSession.getAllTrackables(AugmentedImage::class.java)
        val nowTracking = mutableSetOf<String>()

        for (img in trackables) {
            if (img.trackingState == TrackingState.TRACKING) {
                val markerRef = img.name
                nowTracking.add(markerRef)

                if (!trackedMarkers.contains(markerRef)) {
                    trackedMarkers.add(markerRef)
                    Log.d(TAG, "Marker detectado: $markerRef")
                    onMarkerDetected(markerRef)
                }
            }
        }

        // Detectar markers perdidos
        val lostMarkers = trackedMarkers - nowTracking
        for (ref in lostMarkers) {
            trackedMarkers.remove(ref)
            val candidate = currentCandidates.find { it.imageReference == ref }
            if (candidate != null) {
                Log.d(TAG, "Marker perdido: $ref")
                RecognitionEventDispatcher.dispatchLost(candidate.pointId)
            }
        }

        // ── Análise visual periódica (via VisualRecognitionManager) ──────────
        visualManager.tryAnalyzeAsync(
            frame = frame,
            candidates = currentCandidates,
            scope = coroutineScope
        ) { visualScores ->
            // Atualiza scores visuais nos candidatos e re-executa fusão
            val updated = currentCandidates.map { c ->
                c.copy(visualScore = visualScores[c.pointId] ?: 0f)
            }
            currentCandidates = updated
            runFusion()
        }
    }

    // ── Lógica de reconhecimento ──────────────────────────────────────────────

    /**
     * Chamado quando um marker ARCore é detectado.
     * Atribui markerScore = 1.0 para o candidato correspondente e executa fusão.
     */
    private fun onMarkerDetected(markerRef: String) {
        // Localiza o candidato pelo imageReference
        val loc = locationProvider.lastLocation
        val candidate = currentCandidates.find { it.imageReference == markerRef }
            ?: run {
                // Candidato não está na lista de próximos — pode estar fora do raio
                // Cria candidato temporário com geoScore baseado na distância atual
                val pointData = allPoints.find { it.imageReference == markerRef } ?: return
                val geoScore = if (loc != null) {
                    LocationScoringManager.computeScore(
                        LocationScoringManager.haversineMeters(
                            loc.latitude, loc.longitude,
                            pointData.latitude, pointData.longitude
                        ),
                        RecognitionConstants.GEO_RADIUS_METERS
                    )
                } else 0f

                RecognitionCandidate(
                    pointId        = pointData.id,
                    pointName      = pointData.name,
                    latitude       = pointData.latitude,
                    longitude      = pointData.longitude,
                    imageReference = pointData.imageReference,
                    geoScore       = geoScore,
                    markerScore    = 1.0f
                )
            }

        // Envia evento de marker imediatamente (antes da fusão)
        RecognitionEventDispatcher.dispatchMarkerDetected(candidate.pointId, markerRef, 1.0f)

        // Atualiza markerScore e executa fusão
        val withMarker = candidate.copy(markerScore = 1.0f)
        val result = RecognitionFusionManager.fuse(withMarker)

        // Log detalhado da decisão
        Log.d(TAG, "Decisão para '${candidate.pointId}': " +
                "score=${result.confidence} status=${result.status} src=${result.source}")

        // Debug para o Flutter
        RecognitionEventDispatcher.dispatchDebug(
            "Marker '${markerRef}' → ${candidate.pointId} | " +
            "score=${result.confidence} | status=${result.status}",
            listOf(withMarker.copy(finalScore = result.confidence))
        )

        if (result.status != RecognitionResultStatus.NONE &&
            !confirmedPoints.contains(candidate.pointId)) {

            if (result.status == RecognitionResultStatus.CONFIRMED) {
                confirmedPoints.add(candidate.pointId)
            }
            RecognitionEventDispatcher.dispatchResult(result)
        }
    }

    /**
     * Executa fusão em todos os candidatos atuais e despacha o melhor resultado.
     * Chamado após atualização de scores visuais.
     */
    private fun runFusion() {
        if (currentCandidates.isEmpty()) return
        val best = RecognitionFusionManager.fuseAll(currentCandidates)
        if (best.status != RecognitionResultStatus.NONE &&
            !confirmedPoints.contains(best.pointId)) {

            if (best.status == RecognitionResultStatus.CONFIRMED) {
                confirmedPoints.add(best.pointId)
            }
            RecognitionEventDispatcher.dispatchResult(best)
        }

        // Envia debug com todos os candidatos
        RecognitionEventDispatcher.dispatchDebug(
            "Fusão: ${currentCandidates.size} candidatos | melhor=${best.pointId} score=${best.confidence}",
            currentCandidates.map { it.copy(finalScore = RecognitionFusionManager.fuse(it).confidence) }
        )
    }

    // ── Configurações ─────────────────────────────────────────────────────────

    private fun setupGlSurface() {
        surfaceView.preserveEGLContextOnPause = true
        surfaceView.setEGLContextClientVersion(2)
        surfaceView.setEGLConfigChooser(8, 8, 8, 8, 16, 0)
        surfaceView.setRenderer(this)
        surfaceView.renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
    }

    private fun buildImageDatabase(session: Session): AugmentedImageDatabase {
        val db = AugmentedImageDatabase(session)
        for ((fileName, info) in IMAGE_MAP) {
            val (ref, width) = info
            try {
                assets.open("images/$fileName.png").use { stream ->
                    val bitmap = BitmapFactory.decodeStream(stream, null,
                        BitmapFactory.Options().apply {
                            inPreferredConfig = Bitmap.Config.ARGB_8888
                        })
                    if (bitmap != null) {
                        db.addImage(ref, bitmap, width)
                        Log.d(TAG, "Imagem '$ref' adicionada ao banco ARCore")
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar '$fileName.png': ${e.message}")
            }
        }
        return db
    }

    /** Carrega pontos do assets/content/points.json para filtragem geográfica. */
    private fun loadPointsFromAssets() {
        coroutineScope.launch {
            try {
                val raw = assets.open("content/points.json")
                    .bufferedReader().readText()
                val arr = JSONArray(raw)
                val points = mutableListOf<PointData>()
                for (i in 0 until arr.length()) {
                    val obj: JSONObject = arr.getJSONObject(i)
                    points.add(PointData(
                        id             = obj.getString("id"),
                        name           = obj.getString("name"),
                        latitude       = obj.getDouble("latitude"),
                        longitude      = obj.getDouble("longitude"),
                        imageReference = obj.getString("imageReference")
                    ))
                }
                allPoints = points
                Log.d(TAG, "${points.size} pontos carregados do JSON")

                // Atualiza candidatos imediatamente se já tiver localização
                updateCandidates()
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar points.json: ${e.message}")
            }
        }

        // Atualiza candidatos a cada nova posição
        locationProvider.onLocationUpdate = { loc ->
            Log.d(TAG, "Localização atualizada → re-filtrando candidatos")
            RecognitionEventDispatcher.dispatchLocationUpdate(loc.latitude, loc.longitude, loc.accuracy)
            updateCandidates()
        }
    }

    /** Re-filtra candidatos com base na posição atual. */
    private fun updateCandidates() {
        val loc = locationProvider.lastLocation ?: return
        val candidates = LocationScoringManager.filterCandidates(allPoints, loc)
        currentCandidates = candidates

        if (candidates.isNotEmpty()) {
            RecognitionEventDispatcher.dispatchDebug(
                "Candidatos próximos: ${candidates.joinToString { it.pointName }}",
                candidates
            )
            runOnUiThread {
                statusText.text = "${candidates.size} local(is) próximo(s) — analisando..."
            }
        } else {
            runOnUiThread { statusText.text = "Nenhum local próximo. Aponte para um marker." }
        }
    }

    /** Solicita permissão de câmera se necessário (obrigatória para ARCore). */
    private fun requestCameraPermissionIfNeeded() {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
            != PackageManager.PERMISSION_GRANTED) {
            Log.d(TAG, "Solicitando permissão de câmera")
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CAMERA),
                REQUEST_CAMERA
            )
        }
    }

    /** Solicita permissão de localização se necessário. */
    private fun requestLocationPermissionIfNeeded() {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
            != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION),
                REQUEST_LOCATION
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            REQUEST_CAMERA -> {
                if (grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    Log.d(TAG, "Permissão de câmera concedida — reiniciando AR")
                    // Chama onResume manualmente para inicializar a sessão ARCore agora
                    onResume()
                } else {
                    Log.e(TAG, "Permissão de câmera negada — AR não pode funcionar")
                    runOnUiThread {
                        statusText.text = "Permissão de câmera negada. Ative nas configurações."
                    }
                }
            }
            REQUEST_LOCATION -> {
                if (grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    locationProvider.start()
                    Log.d(TAG, "Permissão de localização concedida")
                } else {
                    Log.w(TAG, "Permissão de localização negada — continuando só com marker")
                }
            }
        }
    }

    @Suppress("UNUSED_PARAMETER")
    fun onCloseClicked(view: View) {
        finish()
    }
}
