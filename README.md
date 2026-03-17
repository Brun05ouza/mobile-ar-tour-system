# AR Tour System

Aplicativo de turismo com **Realidade Aumentada** desenvolvido em Flutter + ARCore. Aponte a câmera para imagens de pontos turísticos cadastrados e o app exibe informações detalhadas sobre o local.

---

## Funcionalidades

- Reconhecimento de imagens de pontos turísticos via ARCore Image Tracking
- Overlay animado com nome e descrição ao detectar uma imagem
- Tela de detalhes completa de cada ponto turístico
- Lista de todos os pontos do tour
- Persistência local com Hive
- Gerenciamento de estado com Riverpod

---

## Pré-requisitos

Antes de começar, garanta que você tem instalado:

| Ferramenta | Versão mínima | Download |
|---|---|---|
| Flutter SDK | 3.x | https://docs.flutter.dev/get-started/install |
| Android Studio | Hedgehog+ | https://developer.android.com/studio |
| Java (JDK) | 17 | https://adoptium.net |
| Dispositivo Android | API 26+ com suporte a ARCore | https://developers.google.com/ar/devices |

> **Importante:** O ARCore **não funciona em emuladores**. É obrigatório um dispositivo físico Android com suporte a ARCore.

---

## Como instalar e rodar

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/mobile-ar-tour-system.git
cd mobile-ar-tour-system
```

### 2. Instale as dependências Flutter

```bash
flutter pub get
```

### 3. Verifique o ambiente

```bash
flutter doctor
```

Todos os itens relevantes devem estar com `✓`. Preste atenção especialmente em:
- Flutter SDK
- Android toolchain
- Connected device

### 4. Conecte o dispositivo Android

Ative o **Modo Desenvolvedor** no seu celular:
1. Vá em **Configurações → Sobre o telefone**
2. Toque 7 vezes em **Número da versão**
3. Volte para **Configurações → Opções do desenvolvedor**
4. Ative **Depuração USB**

Conecte o cabo USB e confirme a permissão no celular.

Verifique se o dispositivo foi reconhecido:

```bash
flutter devices
```

### 5. Rode o app

```bash
flutter run
```

---

## Configuração do Android

### Requisitos mínimos no `android/app/build.gradle.kts`

O projeto já está configurado com:

```kotlin
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}
kotlinOptions {
    jvmTarget = "17"
}
dependencies {
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.ar:core:1.44.0")
}
```

### Permissões necessárias (`AndroidManifest.xml`)

Já configuradas:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-feature android:name="android.hardware.camera.ar" android:required="true"/>
```

### Jetifier (necessário para compatibilidade de bibliotecas legadas)

Já ativado no `android/gradle.properties`:

```properties
android.useAndroidX=true
android.enableJetifier=true
```

---

## Imagens de referência (AR)

As imagens que o ARCore usa para reconhecimento ficam em:

```
android/app/src/main/assets/images/
```

| Arquivo | Ponto turístico | Marker ID |
|---|---|---|
| `coca-cola.png` | Lata de Coca-Cola (teste) | `marker_01` |
| `cristo-redentor.png` | Cristo Redentor | `marker_02` |
| `pao-de-acucar.png` | Pão de Açúcar | `marker_03` |

### Como adicionar novas imagens de referência

1. **Prepare a imagem:**
   - Formato: PNG ou JPG
   - Tamanho recomendado: entre 300px e 500px de largura
   - Modo de cor: **RGB** (sem transparência/alpha)
   - Imagens com alto contraste e muitos detalhes são detectadas melhor
   - Evite imagens com fundo sólido, muito borrão ou áreas repetitivas

2. **Salve em:** `android/app/src/main/assets/images/nome-da-imagem.png`

3. **Registre no `ArImageTrackingActivity.kt`:**

```kotlin
private val imageMap = mapOf(
    "coca-cola"        to Pair("marker_01", 0.07f),   // largura física em metros
    "cristo-redentor"  to Pair("marker_02", 0.15f),
    "pao-de-acucar"    to Pair("marker_03", 0.15f),
    "nova-imagem"      to Pair("marker_04", 0.10f),   // adicione aqui
)
```

   > O terceiro valor (`0.15f`) é a **largura física real** do objeto/foto em metros. Isso ajuda o ARCore a detectar com muito mais precisão. Ex: uma foto impressa em A4 tem ~0.21f, uma lata de refrigerante ~0.07f.

4. **Cadastre o ponto no `assets/data/points.json`:**

```json
{
  "id": "4",
  "name": "Nome do Ponto",
  "description": "Descrição curta",
  "details": "Descrição longa e detalhada...",
  "imageReference": "marker_04",
  "latitude": -23.0,
  "longitude": -43.0
}
```

5. Rode `flutter run` novamente.

---

## Estrutura do projeto

```
mobile-ar-tour-system/
├── android/
│   └── app/
│       └── src/main/
│           ├── assets/images/          # Imagens de referência ARCore
│           ├── kotlin/.../
│           │   ├── MainActivity.kt         # Platform Channel Flutter ↔ Android
│           │   ├── ArImageTrackingActivity.kt  # Activity nativa ARCore
│           │   ├── BackgroundRenderer.kt   # Renderiza feed da câmera no OpenGL
│           │   └── DisplayRotationHelper.kt # Gerencia rotação do display
│           └── res/layout/
│               └── activity_ar_tracking.xml
├── assets/
│   ├── data/points.json               # Dados dos pontos turísticos
│   └── images/                        # Imagens usadas no app Flutter
├── lib/
│   ├── main.dart
│   ├── data/
│   │   ├── models/point_model.dart
│   │   ├── providers/points_provider.dart
│   │   └── services/points_service.dart
│   └── presentation/
│       ├── home/home_screen.dart
│       ├── ar/
│       │   ├── ar_view.dart
│       │   └── ar_overlay_card.dart
│       ├── list/points_list_screen.dart
│       └── details/details_screen.dart
└── pubspec.yaml
```

---

## Como funciona o AR

```
Usuário clica "Iniciar AR"
        ↓
Flutter chama Platform Channel → startImageTracking
        ↓
ArImageTrackingActivity inicia (Activity nativa Android)
        ↓
ARCore Session criada com banco de imagens de referência
        ↓
GLSurfaceView renderiza feed da câmera em tempo real
        ↓
ARCore detecta imagem → TrackingState.TRACKING
        ↓
Activity retorna imageReference via Platform Channel
        ↓
Flutter busca o ponto no JSON pelo imageReference
        ↓
ArOverlayCard exibe nome + descrição com animação
        ↓
Usuário pode navegar para a tela de Detalhes
```

---

## Dependências Flutter

```yaml
dependencies:
  flutter_riverpod: ^2.x    # Gerenciamento de estado
  hive_flutter: ^1.x        # Persistência local
  geolocator: ^x.x          # Localização GPS
```

---

## Troubleshooting

**Build falha com erro de namespace:**
> Verifique se o `ar_flutter_plugin` em `~/.pub-cache` tem `namespace` declarado no `build.gradle`.

**App instala mas AR fecha imediatamente:**
> Certifique-se de que o ARCore Services está instalado no dispositivo. Acesse a Play Store e busque por "Google Play Services for AR".

**Câmera abre mas não detecta imagens:**
> - Segure o celular a ~20-30cm da imagem, em boa iluminação
> - A imagem precisa estar impressa ou em uma tela com boa resolução
> - Verifique se a largura física em metros está correta no `imageMap`
> - Imagens muito simples ou com baixo contraste têm dificuldade de detecção

**`TextureNotSetException` no logcat:**
> A textura OpenGL não foi configurada antes do `session.update()`. Certifique-se de que `backgroundRenderer.createOnGlThread()` é chamado em `onSurfaceCreated` e `session.setCameraTextureName()` em `onDrawFrame` antes do `update()`.
