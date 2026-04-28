import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/theme/app_theme.dart';
import '../../data/models/point_model.dart';
import '../../data/services/points_service.dart';
import '../home/home_screen.dart';
import 'ar_overlay_card.dart';

const _channel = MethodChannel('com.brunoouza.ar_tour/ar_detection');

class ArView extends StatefulWidget {
  const ArView({super.key});

  @override
  State<ArView> createState() => _ArViewState();
}

class _ArViewState extends State<ArView> {
  PointModel? _pontoDetetado;
  bool _scanning = false;
  String _statusMsg = 'Pronto para começar';
  bool _cameraDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarScanner());
  }

  Future<void> _iniciarScanner() async {
    if (_scanning) return;

    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        if (!mounted) return;
        setState(() {
          _cameraDenied = true;
          _statusMsg = result.isPermanentlyDenied
              ? 'Ative a câmara nas definições do telemóvel para usar esta experiência.'
              : 'É necessário permissão de câmara para continuar.';
        });
        return;
      }
    }
    _cameraDenied = false;

    setState(() {
      _scanning = true;
      _pontoDetetado = null;
      _statusMsg = 'A abrir a experiência…';
    });

    try {
      final String? imageReference =
          await _channel.invokeMethod('startImageTracking');

      if (!mounted) return;

      if (imageReference != null) {
        final ponto = await PointsService.findByImageReference(imageReference);
        if (mounted) {
          setState(() {
            _pontoDetetado = ponto;
            _scanning = false;
            _statusMsg = ponto != null
                ? 'Excelente — encontrámos este local.'
                : 'Imagem reconhecida. O conteúdo deste local estará disponível em breve.';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _scanning = false;
            _statusMsg = 'Não foi detetada uma imagem válida. Tente novamente.';
          });
        }
      }
    } on PlatformException catch (_) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _statusMsg =
              'Não foi possível iniciar a experiência. Tente outra vez dentro de instantes.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Reconhecimento por imagem',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? null
            : IconButton(
                icon: const Icon(Icons.home_outlined),
                tooltip: 'Início',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    PageRouteBuilder<void>(
                      pageBuilder: (_, __, ___) => const HomeScreen(),
                      transitionDuration: const Duration(milliseconds: 350),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                    ),
                    (_) => false,
                  );
                },
              ),
        actions: [
          if (_pontoDetetado != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Nova leitura',
              onPressed: _iniciarScanner,
            ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _scanning
                            ? SizedBox(
                                key: const ValueKey('scanning'),
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  color: AppColors.accent,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Icon(
                                key: const ValueKey('idle'),
                                _pontoDetetado != null
                                    ? Icons.verified_outlined
                                    : Icons.wallpaper_outlined,
                                size: 80,
                                color: _pontoDetetado != null
                                    ? AppColors.accent
                                    : AppColors.textHint,
                              ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        _statusMsg,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 36),
                      if (!_scanning) ...[
                        FilledButton.icon(
                          onPressed: _iniciarScanner,
                          icon: const Icon(Icons.photo_camera_outlined, size: 22),
                          label: Text(
                            _pontoDetetado != null
                                ? 'Ler outra imagem'
                                : 'Iniciar leitura',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: const Color(0xFF1A1510),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        if (_cameraDenied) ...[
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: () async {
                              await openAppSettings();
                            },
                            icon: const Icon(Icons.settings_outlined, size: 20),
                            label: const Text('Abrir definições'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.accent,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
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
        ),
      ),
    );
  }
}
