# AR Tour System — Guia Turístico com Realidade Aumentada

App Android de guia turístico com **reconhecimento híbrido contextual** baseado em ARCore, geolocalização e comparação visual.

---

## Sumário

1. [Visão Geral](#visão-geral)
2. [Arquitetura Híbrida](#arquitetura-híbrida)
3. [Fluxo de Decisão](#fluxo-de-decisão)
4. [Pesos e Thresholds Configuráveis](#pesos-e-thresholds-configuráveis)
5. [Instalação e Configuração](#instalação-e-configuração)
6. [Configuração Android](#configuração-android)
7. [Como Adicionar Novos Pontos](#como-adicionar-novos-pontos)
8. [Como Adicionar Imagens de Reconhecimento](#como-adicionar-imagens-de-reconhecimento)
9. [Como Calibrar Thresholds](#como-calibrar-thresholds)
10. [Integração Flutter ↔ Android](#integração-flutter--android)
11. [Estrutura do Projeto](#estrutura-do-projeto)
12. [Integrando OpenCV (Fase Futura)](#integrando-opencv-fase-futura)
13. [Troubleshooting](#troubleshooting)

---

## Visão Geral

O app possui **dois modos de AR**:

| Modo | Arquivo | Comportamento |
|---|---|---|
| **Legado** | `ArImageTrackingActivity.kt` | Detecta um marker ARCore e fecha a tela |
| **Híbrido** | `HybridArActivity.kt` | Câmera contínua + stream de eventos + fusão de scores |

O modo híbrido é acessado pelo botão **"AR Híbrido"** na HomeScreen.

---

## Arquitetura Híbrida

```
Flutter
  └── HybridArView
        └── RecognitionNotifier (Riverpod)
              └── RecognitionChannel
                    ├── EventChannel ← Android envia eventos
                    └── MethodChannel → Flutter controla
Android
  └── HybridArActivity
        ├── ARCore (AugmentedImageDatabase)  → markerScore
        ├── CurrentLocationProvider          → posição GPS
        ├── LocationScoringManager           → geoScore
        ├── VisualRecognitionManager         → visualScore (placeholder)
        ├── RecognitionFusionManager         → scoreFinal
        └── RecognitionEventDispatcher       → EventChannel
```

### Módulos Android

| Arquivo | Responsabilidade |
|---|---|
| `HybridArActivity.kt` | Activity principal — orquestra todos os managers |
| `RecognitionConstants.kt` | Pesos, thresholds e nomes de canais centralizados |
| `RecognitionFusionManager.kt` | Combina scores e decide a ação |
| `RecognitionEventDispatcher.kt` | Serializa e envia eventos ao Flutter |
| `LocationScoringManager.kt` | Calcula score de proximidade geográfica |
| `CurrentLocationProvider.kt` | FusedLocationProvider com ciclo de vida gerenciado |
| `VisualRecognitionManager.kt` | Pipeline ORB/OpenCV (placeholder) |
| `RecognitionCandidate.kt` | Modelo de candidato com scores parciais |
| `RecognitionResult.kt` | Resultado da fusão |

### Módulos Flutter

| Arquivo | Responsabilidade |
|---|---|
| `hybrid_ar_view.dart` | Tela principal do modo híbrido |
| `recognition_notifier.dart` | Gerencia estado via Riverpod |
| `recognition_channel.dart` | EventChannel + MethodChannel |
| `recognition_state_model.dart` | Estado imutável do pipeline |
| `location_service.dart` | Geolocalização e filtragem de proximidade |
| `recognition_status_banner.dart` | Banner de status adaptativo |
| `recognition_suggestion_card.dart` | Card de sugestão com ações |
| `recognition_debug_panel.dart` | Painel de debug (apenas em kDebugMode) |

---

## Fluxo de Decisão

```
Câmera aberta
    │
    ├── GPS obtido → filtrar candidatos no raio de 300m
    │
    ├── [A cada frame] ARCore detecta marker?
    │       Sim → markerScore = 1.0 para o candidato correspondente
    │       Não → markerScore = 0.0
    │
    ├── [A cada 800ms] VisualRecognitionManager analisa frame
    │       → visualScore por ORB/OpenCV (0.0 enquanto não integrado)
    │
    └── RecognitionFusionManager combina scores:
            scoreFinal = marker * 0.55 + geo * 0.20 + visual * 0.25

            scoreFinal >= 0.90 → CONFIRMADO (card abre automaticamente)
            scoreFinal >= 0.65 → SUGESTÃO   (usuário confirma ou ignora)
            scoreFinal <  0.65 → NENHUM     (pipeline continua)
```

### Regra especial — marker domina

Quando `markerScore >= 0.9`, o campo `source` é definido como `MARKER_ONLY`.
Mesmo assim, o `geoScore` ainda entra no cálculo para evitar falsos positivos
em locais fisicamente distantes (ex: imagem impressa fora do local real).

---

## Pesos e Thresholds Configuráveis

Edite `android/app/src/main/kotlin/com/brunoouza/ar_tour/recognition/RecognitionConstants.kt`:

```kotlin
// Pesos — devem somar 1.0
const val WEIGHT_MARKER  = 0.55f   // ARCore AugmentedImages
const val WEIGHT_GEO     = 0.20f   // Proximidade GPS
const val WEIGHT_VISUAL  = 0.25f   // OpenCV ORB (placeholder)

// Thresholds de decisão
const val THRESHOLD_AUTO    = 0.90f  // Confirmação automática
const val THRESHOLD_SUGGEST = 0.65f  // Sugestão ao usuário

// Raio de busca de candidatos próximos
const val GEO_RADIUS_METERS = 300.0

// Intervalo entre análises visuais (ms)
const val VISUAL_INTERVAL_MS = 800L
```

**Quando ajustar:**
- Em ambiente indoor (museu): reduza `GEO_RADIUS_METERS` para 50–100m
- Sem GPS confiável: aumente `WEIGHT_MARKER` para 0.75 e reduza `WEIGHT_GEO` para 0.05
- Com OpenCV integrado: redistribua pesos (ex: marker=0.40, geo=0.20, visual=0.40)
- Para evitar falsos positivos: aumente `THRESHOLD_AUTO` para 0.95

---

## Instalação e Configuração

### Pré-requisitos

- Flutter SDK >= 3.0.0
- Android Studio Hedgehog ou superior
- Dispositivo Android com suporte a ARCore (ver [lista oficial](https://developers.google.com/ar/devices))
- NDK instalado (`flutter.ndkVersion` no `local.properties`)

### Passos

```bash
git clone https://github.com/Brun05ouza/mobile-ar-tour-system.git
cd mobile-ar-tour-system
flutter pub get
flutter run
```

Se o build falhar por JVM target:

```bash
cd android
./gradlew clean
cd ..
flutter run
```

### Áudio guia (offline)

Na **tela de detalhes**, se o campo `audioAsset` em `assets/content/points.json` não estiver vazio, o app mostra um player com **play/pause** e **barra de progresso** (inclui seek). O áudio vem de ficheiros em **`assets/audio/`**, embutidos no APK — **não precisa de rede**.

- Formatos comuns suportados pelo pacote `just_audio`: por exemplo **MP3**, **WAV**, **M4A** (conforme codec no dispositivo).
- Coloque o ficheiro em `assets/audio/` e referencie o caminho completo no JSON, ex.: `"audioAsset": "assets/audio/point_001.wav"`.
- Se `audioAsset` for `""`, a secção de áudio não aparece.
- Ao **voltar** da tela de detalhes, o player é encerrado; se a app for para **segundo plano**, a reprodução **pausa** automaticamente.

---

## Configuração Android

### Permissões (AndroidManifest.xml)

Já configuradas:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### Google Play Services Location

Já adicionado em `android/app/build.gradle.kts`:
```kotlin
implementation("com.google.android.gms:play-services-location:21.3.0")
```

### ARCore

O ARCore é declarado como `required`. O app não instala em dispositivos sem suporte.
Para torná-lo opcional:

```xml
<!-- AndroidManifest.xml -->
<uses-feature android:name="android.hardware.camera.ar" android:required="false"/>
```

E adicione verificação em runtime antes de criar a `Session`.

---

## Como Adicionar Novos Pontos

### 1. Adicione a imagem de referência ARCore

Coloque a imagem em:
```
android/app/src/main/assets/images/<nome>.png
```

Recomendações:
- Formato RGB (sem transparência)
- Resolução máxima 400px de largura
- Alto contraste, sem áreas uniformes

### 2. Registre no `imageMap` da `HybridArActivity`

```kotlin
// HybridArActivity.kt
private val IMAGE_MAP = mapOf(
    "meu-ponto" to Pair("marker_04", 0.15f)  // nome-arquivo → (referência, largura-física-em-metros)
)
```

O mesmo registro deve existir em `ArImageTrackingActivity.kt` para o modo legado.

### 3. Adicione ao `points.json`

`assets/content/points.json`:

```json
{
  "id": "point_004",
  "name": "Nome do Local",
  "description": "Descrição curta.",
  "details": "Descrição completa...",
  "imageReference": "marker_04",
  "imagePath": "assets/images/meu-ponto.png",
  "latitude": -23.5505,
  "longitude": -46.6333,
  "category": "historia",
  "tags": ["patrimonio", "cultural"],
  "recognitionImages": [],
  "recognitionThreshold": 0.75,
  "thumbnailAsset": "assets/images/meu-ponto.png",
  "audioAsset": "assets/audio/meu-ponto.wav"
}
```

### 4. Registre o asset no `pubspec.yaml`

Se a imagem estiver em uma pasta nova, adicione:
```yaml
flutter:
  assets:
    - assets/images/
```

---

## Como Adicionar Imagens de Reconhecimento

As `recognitionImages` são usadas pelo `VisualRecognitionManager` para comparação ORB/OpenCV.
São diferentes das imagens ARCore — são fotos tiradas do local para reconhecimento visual contextual.

### 1. Coloque as imagens em

```
assets/recognition/point_004/
  frontal.jpg
  lateral.jpg
  placa.jpg
  detalhe.jpg
```

Recomendações:
- 3–5 imagens por ponto, de ângulos diferentes
- Resolução 640×480 ou menor (OpenCV redimensiona internamente para 320×240)
- Formato JPEG ou PNG

### 2. Registre no `points.json`

```json
"recognitionImages": [
  "assets/recognition/point_004/frontal.jpg",
  "assets/recognition/point_004/lateral.jpg",
  "assets/recognition/point_004/placa.jpg"
]
```

### 3. Registre no `pubspec.yaml`

```yaml
assets:
  - assets/recognition/point_004/
```

> **Nota:** O reconhecimento visual só será ativo após a integração do OpenCV.
> Enquanto isso, o `VisualRecognitionManager` retorna score 0.0 e a decisão
> é baseada em marker + geolocalização.

---

## Como Calibrar Thresholds

### Por ponto individual

Use o campo `recognitionThreshold` no `points.json`:
```json
"recognitionThreshold": 0.85
```

Quando diferente de `0.0`, este valor substitui o `THRESHOLD_AUTO` global para aquele ponto.

> A implementação do threshold por ponto está no `PointModel.recognitionThreshold`.
> Para ativá-la no `RecognitionFusionManager`, adicione:
> ```kotlin
> val threshold = candidate.customThreshold.takeIf { it > 0f }
>     ?: RecognitionConstants.THRESHOLD_AUTO
> ```

### Debug em tempo real

Em modo debug (`kDebugMode = true`), o `RecognitionDebugPanel` exibe:
- Posição GPS atual
- Candidatos próximos com distância
- Scores parciais (geo, marker, visual) e score final
- Origem da decisão
- Última mensagem do pipeline

---

## Integração Flutter ↔ Android

### Canais de comunicação

| Canal | Tipo | Direção | Uso |
|---|---|---|---|
| `com.brunoouza.ar_tour/ar_detection` | MethodChannel | Flutter → Android | Modo legado (`startImageTracking`) |
| `com.brunoouza.ar_tour/recognition_control` | MethodChannel | Flutter → Android | Controle do modo híbrido |
| `com.brunoouza.ar_tour/recognition_events` | EventChannel | Android → Flutter | Stream de eventos de reconhecimento |

### Eventos emitidos pelo Android

| Evento | Payload | Quando |
|---|---|---|
| `onMarkerDetected` | `{pointId, markerRef, confidence}` | Marker ARCore entra em TRACKING |
| `onRecognitionConfirmed` | `{pointId, pointName, score, source}` | score >= 0.90 |
| `onRecognitionSuggestion` | `{pointId, pointName, score}` | score entre 0.65 e 0.90 |
| `onRecognitionLost` | `{pointId}` | Marker sai do campo de visão |
| `onLocationUpdate` | `{lat, lon, accuracy}` | Nova posição GPS |
| `onRecognitionDebugInfo` | `{message, candidates[]}` | A cada ciclo de análise |

---

## Estrutura do Projeto

```
lib/
  main.dart                        # AppTheme + inicialização Hive
  data/
    models/
      point_model.dart             # Modelo com campos de reconhecimento
      point_model.g.dart           # Adaptador Hive (gerado)
    providers/
      points_provider.dart         # FutureProvider da lista de pontos
      user_prefs_provider.dart     # Visitados, Favoritos, Filtro
    services/
      points_service.dart          # Carrega e filtra pontos do JSON
      user_prefs_service.dart      # Persistência Hive de prefs do usuário
  features/
    recognition/
      domain/
        recognition_status.dart    # Enum de estados
        recognition_source.dart    # Enum de origem da decisão
        recognition_candidate.dart # Candidato com scores parciais
        recognition_result.dart    # Resultado da fusão
        recognition_state_model.dart # Estado imutável Riverpod
      data/
        recognition_channel.dart   # EventChannel + MethodChannel
        recognition_notifier.dart  # Notifier Riverpod
      presentation/
        hybrid_ar_view.dart        # Tela principal híbrida
        widgets/
          recognition_status_banner.dart
          recognition_suggestion_card.dart
          recognition_debug_panel.dart
    location/
      domain/
        location_service.dart      # Geolocator + haversine
  presentation/
    home/home_screen.dart
    ar/
      ar_view.dart                 # Modo legado (preservado)
      ar_overlay_card.dart
    list/points_list_screen.dart
    details/details_screen.dart

android/app/src/main/kotlin/com/brunoouza/ar_tour/
  MainActivity.kt                  # Canais legado + híbrido
  ArImageTrackingActivity.kt       # Modo legado (preservado)
  BackgroundRenderer.kt
  DisplayRotationHelper.kt
  recognition/
    HybridArActivity.kt
    RecognitionConstants.kt
    RecognitionFusionManager.kt
    RecognitionEventDispatcher.kt
    LocationScoringManager.kt
    VisualRecognitionManager.kt
  location/
    CurrentLocationProvider.kt
  models/
    RecognitionCandidate.kt
    RecognitionResult.kt

assets/
  content/
    points.json                    # Dados dos pontos (novo caminho)
  data/
    points.json                    # Legado (mantido para compatibilidade)
  images/
    coca-cola.png
    cristo-redentor.png
    pao-de-acucar.png
    thumbnails/
  recognition/
    point_001/                     # Imagens para ORB/OpenCV
    point_002/
    point_003/
  audio/
```

---

## Integrando OpenCV (Fase Futura)

### 1. Adicione a dependência

`android/app/build.gradle.kts`:
```kotlin
implementation("org.opencv:opencv:4.9.0")
```

### 2. Implemente os métodos placeholder

Em `VisualRecognitionManager.kt`, substitua:
- `captureFrameBitmap()` — use `frame.acquireCameraImage()` e converta para `Mat`
- `analyzeFrame()` — implemente ORB + BruteForce Matcher (ver comentários no arquivo)
- `getOrComputeDescriptors()` — carregue assets e extraia descriptors com `ORB.create()`

### 3. Ajuste os pesos

`RecognitionConstants.kt`:
```kotlin
const val WEIGHT_MARKER  = 0.40f
const val WEIGHT_GEO     = 0.20f
const val WEIGHT_VISUAL  = 0.40f
```

### 4. Adicione imagens de reconhecimento

Ver seção [Como Adicionar Imagens de Reconhecimento](#como-adicionar-imagens-de-reconhecimento).

---

## Troubleshooting

### App fecha ao abrir AR
- Verifique se o dispositivo suporta ARCore
- Confirme permissão de câmera concedida

### Camera feed preta
- Certifique-se que `BackgroundRenderer.createOnGlThread()` é chamado em `onSurfaceCreated`
- Verifique que `session.setCameraTextureName(backgroundRenderer.textureId)` é chamado

### Nenhuma imagem detectada
- Imprima a imagem em tamanho físico correto (ver `widthInMeters` em `IMAGE_MAP`)
- Use imagens RGB sem transparência, máximo 400px
- Ilumine bem o ambiente — ARCore precisa de contraste nítido

### GPS não obtido
- Ative o GPS no dispositivo
- Conceda permissão `ACCESS_FINE_LOCATION`
- Outdoor: aguarde alguns segundos para o GPS fixar
- O app continua funcionando só com marker se o GPS falhar

### EventChannel não recebe eventos
- Verifique que `HybridArActivity.flutterEngine` está sendo injetado
- Confirme que o nome do canal em `RecognitionConstants.EVENT_CHANNEL` bate com o Flutter
- Verifique logs com tag `EventDispatcher` no Logcat

### Build error: "Unresolved reference"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```
