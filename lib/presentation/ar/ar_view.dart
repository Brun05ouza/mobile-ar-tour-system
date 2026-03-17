import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/point_model.dart';
import '../../data/services/points_service.dart';
import 'ar_overlay_card.dart';

// Platform Channel para comunicação com o Android nativo
const _channel = MethodChannel('com.brunoouza.ar_tour/ar_detection');

class ArView extends StatefulWidget {
  const ArView({super.key});

  @override
  State<ArView> createState() => _ArViewState();
}

class _ArViewState extends State<ArView> {
  PointModel? _pontoDetetado;
  bool _scanning = false;
  String _statusMsg = 'Pronto para escanear';
  bool _cameraDenied = false;

  @override
  void initState() {
    super.initState();
    // Inicia o scanner automaticamente ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarScanner());
  }

  Future<void> _iniciarScanner() async {
    if (_scanning) return;

    // Solicita permissão de câmera antes de abrir o AR
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        if (!mounted) return;
        setState(() {
          _cameraDenied = true;
          _statusMsg = result.isPermanentlyDenied
              ? 'Permissão da câmera negada. Ative nas configurações do app para usar o AR.'
              : 'É necessário permitir o uso da câmera para o AR funcionar.';
        });
        return;
      }
    }
    _cameraDenied = false;

    setState(() {
      _scanning = true;
      _pontoDetetado = null;
      _statusMsg = 'Abrindo câmera AR...';
    });

    try {
      // Chama a Activity nativa de Image Tracking
      final String? imageReference = await _channel.invokeMethod('startImageTracking');

      if (!mounted) return;

      if (imageReference != null) {
        final ponto = await PointsService.findByImageReference(imageReference);
        if (mounted) {
          setState(() {
            _pontoDetetado = ponto;
            _scanning = false;
            _statusMsg = ponto != null
                ? 'Ponto encontrado!'
                : 'Imagem detectada, mas sem ponto cadastrado ($imageReference)';
          });
        }
      } else {
        // Usuário fechou sem detectar
        if (mounted) {
          setState(() {
            _scanning = false;
            _statusMsg = 'Nenhuma imagem detectada. Tente novamente.';
          });
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _statusMsg = 'Erro: ${e.message}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        title: const Text('AR Tour'),
        backgroundColor: const Color(0xFF0F1117),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_pontoDetetado != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Escanear novamente',
              onPressed: _iniciarScanner,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Conteúdo central
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone animado
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _scanning
                        ? const SizedBox(
                            key: ValueKey('scanning'),
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              color: Colors.teal,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(
                            key: const ValueKey('idle'),
                            _pontoDetetado != null
                                ? Icons.check_circle_outline
                                : Icons.image_search,
                            size: 72,
                            color: _pontoDetetado != null
                                ? Colors.teal
                                : Colors.white24,
                          ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    _statusMsg,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botão de escanear (aparece quando não está escaneando)
                  if (!_scanning) ...[
                    ElevatedButton.icon(
                      onPressed: _iniciarScanner,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(_pontoDetetado != null
                          ? 'Escanear outro ponto'
                          : 'Escanear imagem'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    if (_cameraDenied) ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () async {
                          await openAppSettings();
                        },
                        icon: const Icon(Icons.settings, size: 20),
                        label: const Text('Abrir configurações'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.teal,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Overlay card aparece na parte de baixo ao detectar um ponto
          if (_pontoDetetado != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ArOverlayCard(
                point: _pontoDetetado!,
                onClose: () => setState(() => _pontoDetetado = null),
              ),
            ),
        ],
      ),
    );
  }
}
