package com.brunoouza.ar_tour.recognition

import android.graphics.Bitmap
import android.util.Log
import com.brunoouza.ar_tour.models.RecognitionCandidate
import com.google.ar.core.Frame
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Gerenciador de reconhecimento visual baseado em comparação de features.
 *
 * # Estado atual
 * O pipeline está estruturalmente completo, mas o motor de comparação
 * (OpenCV/ORB) é um PLACEHOLDER que retorna score 0.0.
 *
 * # Como integrar o OpenCV
 * 1. Adicione ao android/app/build.gradle.kts:
 *    ```
 *    implementation("org.opencv:opencv:4.9.0")
 *    ```
 * 2. Substitua os métodos marcados com `// OPENCV:` abaixo pela implementação real.
 * 3. Coloque imagens de referência em assets/recognition/<pointId>/
 *    (ex: assets/recognition/point_001/frontal.jpg)
 * 4. Atualize points.json com o campo "recognitionImages" apontando para esses assets.
 *
 * # Estratégia ORB
 * - Carrega imagens de reconhecimento dos candidatos próximos
 * - Extrai descriptors ORB de cada imagem de referência
 * - Captura frame da câmera (via ARCore) e extrai descriptors
 * - Compara via BruteForce matcher (Hamming distance para ORB)
 * - Normaliza score: matches_bons / total_keypoints → [0.0, 1.0]
 *
 * # Performance
 * - Processa no máximo a cada [RecognitionConstants.VISUAL_INTERVAL_MS] ms
 * - Descarta frames se o pipeline estiver ocupado (AtomicBoolean)
 * - Nunca trava a thread GL — corre em Dispatchers.Default
 */
class VisualRecognitionManager {

    companion object {
        private const val TAG = "VisualRecognition"

        // Limita comparação a imagens de no máximo esta resolução
        private const val MAX_ANALYSIS_WIDTH = 320
        private const val MAX_ANALYSIS_HEIGHT = 240

        // Mínimo de boas correspondências para considerar match
        private const val MIN_GOOD_MATCHES = 15
    }

    /** Previne processamento paralelo de frames. */
    private val isProcessing = AtomicBoolean(false)

    /** Timestamp do último frame processado. */
    @Volatile
    private var lastProcessedMs = 0L

    // ── Descriptors em cache ──────────────────────────────────────────────────
    // Chave: pointId, Valor: descriptors extraídos das imagens de referência
    // Populados na primeira vez que o candidato aparece, liberados quando sai do raio.
    //
    // OPENCV: substituir Any por Mat (org.opencv.core.Mat)
    private val descriptorCache = mutableMapOf<String, Any>()

    // ── Interface pública ─────────────────────────────────────────────────────

    /**
     * Tenta analisar o frame atual de forma assíncrona.
     *
     * Se o pipeline já estiver ocupado ou o intervalo mínimo não tiver passado,
     * o frame é descartado silenciosamente.
     *
     * @param frame      Frame atual do ARCore
     * @param candidates Candidatos filtrados por localização
     * @param scope      CoroutineScope para execução em background
     * @param onResult   Callback com mapa pointId → visualScore [0.0, 1.0]
     */
    fun tryAnalyzeAsync(
        frame: Frame,
        candidates: List<RecognitionCandidate>,
        scope: CoroutineScope,
        onResult: (Map<String, Float>) -> Unit
    ) {
        if (candidates.isEmpty()) return

        val now = System.currentTimeMillis()
        if (now - lastProcessedMs < RecognitionConstants.VISUAL_INTERVAL_MS) return
        if (!isProcessing.compareAndSet(false, true)) return

        scope.launch {
            try {
                val bitmap = captureFrameBitmap(frame)
                if (bitmap == null) {
                    Log.w(TAG, "Frame inválido — descartando análise visual")
                    return@launch
                }

                val scores = analyzeFrame(bitmap, candidates)
                lastProcessedMs = System.currentTimeMillis()

                if (scores.isNotEmpty()) {
                    val best = scores.maxByOrNull { it.value }
                    Log.d(TAG, "Visual: melhor match = ${best?.key} (score=${best?.value})")
                }

                onResult(scores)
            } catch (e: Exception) {
                Log.e(TAG, "Erro no pipeline visual: ${e.message}")
            } finally {
                isProcessing.set(false)
            }
        }
    }

    /**
     * Analisa o [bitmap] contra as imagens de referência dos [candidates].
     *
     * Retorna mapa pointId → score normalizado [0.0, 1.0].
     *
     * # Implementação atual: PLACEHOLDER
     * Retorna 0.0 para todos os candidatos.
     *
     * # Implementação OpenCV (substituir):
     * ```kotlin
     * // 1. Converter bitmap para Mat grayscale
     * val frameMat = Mat()
     * Utils.bitmapToMat(bitmap, frameMat)
     * Imgproc.cvtColor(frameMat, frameMat, Imgproc.COLOR_BGR2GRAY)
     *
     * // 2. Extrair descriptors ORB do frame
     * val orb = ORB.create()
     * val frameKps = MatOfKeyPoint()
     * val frameDesc = Mat()
     * orb.detectAndCompute(frameMat, Mat(), frameKps, frameDesc)
     *
     * // 3. Para cada candidato, comparar com descriptors cached
     * val scores = mutableMapOf<String, Float>()
     * for (candidate in candidates) {
     *     val refDesc = getOrComputeDescriptors(candidate) ?: continue
     *     val matcher = DescriptorMatcher.create(DescriptorMatcher.BRUTEFORCE_HAMMING)
     *     val matches = MatOfDMatch()
     *     matcher.match(frameDesc, refDesc, matches)
     *     val goodMatches = matches.toArray().filter { it.distance < 60 }
     *     val score = (goodMatches.size.toFloat() / MIN_GOOD_MATCHES).coerceIn(0f, 1f)
     *     scores[candidate.pointId] = score
     * }
     * return scores
     * ```
     */
    private fun analyzeFrame(
        bitmap: Bitmap,
        candidates: List<RecognitionCandidate>
    ): Map<String, Float> {
        // PLACEHOLDER: OpenCV não integrado ainda.
        // Retorna 0.0 para todos os candidatos — fusão usa apenas marker + geo.
        // Para integrar: ver comentário acima e RecognitionConstants.VISUAL_INTERVAL_MS
        return candidates.associate { it.pointId to 0f }
    }

    /**
     * Captura o frame atual como Bitmap para análise.
     *
     * Retorna null se o frame for inválido ou a captura falhar.
     *
     * OPENCV: quando integrado, pode converter diretamente para Mat
     * sem passar por Bitmap para melhor performance.
     */
    private fun captureFrameBitmap(frame: Frame): Bitmap? {
        return try {
            // ARCore não expõe diretamente o frame como Bitmap via API pública.
            // A forma correta é usar frame.acquireCameraImage() e converter.
            // Por ora, retornamos null (análise visual desativada até integração OpenCV).
            //
            // OPENCV: substituir por:
            // val image = frame.acquireCameraImage()
            // val bitmap = image.toBitmap().scale(MAX_ANALYSIS_WIDTH, MAX_ANALYSIS_HEIGHT)
            // image.close()
            // bitmap
            null
        } catch (e: Exception) {
            Log.w(TAG, "Falha ao capturar frame: ${e.message}")
            null
        }
    }

    /**
     * Obtém (ou calcula e faz cache de) descriptors ORB para um candidato.
     *
     * OPENCV: implementar aqui a carga de assets/recognition/<pointId>/
     * e extração de descriptors com ORB.create().detectAndCompute()
     *
     * @return descriptors (Mat quando OpenCV integrado), null se imagens não disponíveis
     */
    @Suppress("UNUSED_PARAMETER")
    private fun getOrComputeDescriptors(candidate: RecognitionCandidate): Any? {
        // PLACEHOLDER: sem OpenCV, retorna null
        return null
    }

    /** Libera descriptors em cache de pontos que saíram do raio. */
    fun evictStaleDescriptors(activeCandidateIds: Set<String>) {
        val stale = descriptorCache.keys - activeCandidateIds
        stale.forEach { descriptorCache.remove(it) }
        if (stale.isNotEmpty()) {
            Log.d(TAG, "Descriptors liberados: $stale")
        }
    }
}
