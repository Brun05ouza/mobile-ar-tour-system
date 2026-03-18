import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/ar/ar_overlay_card.dart';
import '../../../presentation/details/details_screen.dart';
import '../data/recognition_notifier.dart';
import '../domain/recognition_status.dart';
import 'widgets/recognition_debug_panel.dart';
import 'widgets/recognition_status_banner.dart';
import 'widgets/recognition_suggestion_card.dart';

/// Tela principal do sistema de reconhecimento híbrido AR.
///
/// Gerencia o ciclo de vida do pipeline (start/stop) e exibe os estados
/// de reconhecimento usando widgets desacoplados.
///
/// Fluxo de estado:
///   idle → analyzing → suggestion → confirmed
///                    ↗ lost ──────────↗
///
/// Esta tela coexiste com o [ArView] legado — ambas funcionam independentemente.
class HybridArView extends ConsumerStatefulWidget {
  const HybridArView({super.key});

  @override
  ConsumerState<HybridArView> createState() => _HybridArViewState();
}

class _HybridArViewState extends ConsumerState<HybridArView> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRecognition());
  }

  @override
  void dispose() {
    // Para o pipeline ao sair da tela
    ref.read(recognitionProvider.notifier).stopRecognition();
    super.dispose();
  }

  Future<void> _startRecognition() async {
    if (_started) return;
    _started = true;
    await ref.read(recognitionProvider.notifier).startRecognition();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recognitionProvider);

    // Navega para DetailsScreen ao confirmar
    ref.listen(recognitionProvider, (prev, next) {
      if (next.status == RecognitionStatus.confirmed &&
          next.confirmedPoint != null &&
          prev?.status != RecognitionStatus.confirmed) {
        // Pequeno delay para a animação do card ser visível
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  DetailsScreen(point: next.confirmedPoint!),
              transitionDuration: const Duration(milliseconds: 350),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          );
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        title: const Text('AR Híbrido'),
        backgroundColor: const Color(0xFF0F1117),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Botão de reiniciar
          if (state.status != RecognitionStatus.analyzing)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reiniciar análise',
              onPressed: () {
                ref.read(recognitionProvider.notifier).stopRecognition();
                _started = false;
                _startRecognition();
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // ── Conteúdo central ────────────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone animado principal
                  _StatusIcon(status: state.status),

                  const SizedBox(height: 24),

                  // Mensagem principal
                  Text(
                    _mainMessage(state.status),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  // Info de candidatos próximos
                  if (state.nearbyCandidates.isNotEmpty &&
                      state.status == RecognitionStatus.analyzing) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${state.nearbyCandidates.length} local(is) próximo(s) identificado(s)',
                      style: const TextStyle(
                        color: Colors.teal,
                        fontSize: 13,
                      ),
                    ),
                  ],

                  // Botão de escanear manualmente (quando idle)
                  if (state.status == RecognitionStatus.idle) ...[
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        _started = false;
                        _startRecognition();
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Iniciar Reconhecimento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Banner de status (topo) ─────────────────────────────────────────
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: RecognitionStatusBanner(
              status: state.status,
              message: state.lastDebugMessage.isNotEmpty &&
                      _shouldShowDebugInBanner(state.status)
                  ? ''
                  : '',
            ),
          ),

          // ── Card de sugestão (meio-baixo) ───────────────────────────────────
          if (state.status == RecognitionStatus.suggestion &&
              state.suggestedPoint != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: RecognitionSuggestionCard(
                point: state.suggestedPoint!,
                confidence: state.recognitionConfidence,
                onConfirm: () =>
                    ref.read(recognitionProvider.notifier).confirmSuggestion(),
                onDismiss: () =>
                    ref.read(recognitionProvider.notifier).dismissSuggestion(),
              ),
            ),

          // ── Card confirmado (usa o ArOverlayCard existente) ─────────────────
          if (state.status == RecognitionStatus.confirmed &&
              state.confirmedPoint != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ArOverlayCard(
                point: state.confirmedPoint!,
                onClose: () =>
                    ref.read(recognitionProvider.notifier).onRecognitionLost(),
              ),
            ),

          // ── Debug panel (apenas em kDebugMode) ─────────────────────────────
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: RecognitionDebugPanel(state: state),
          ),
        ],
      ),
    );
  }

  String _mainMessage(RecognitionStatus status) {
    switch (status) {
      case RecognitionStatus.idle:
        return 'Aponte a câmera para um local ou quadro';
      case RecognitionStatus.analyzing:
        return 'Analisando ambiente...';
      case RecognitionStatus.suggestion:
        return 'Local identificado — confirme ou ignore abaixo';
      case RecognitionStatus.confirmed:
        return 'Local reconhecido!';
      case RecognitionStatus.lost:
        return 'Reconhecimento perdido — analisando novamente...';
    }
  }

  bool _shouldShowDebugInBanner(RecognitionStatus status) =>
      status == RecognitionStatus.analyzing;
}

// ── Status Icon ───────────────────────────────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  final RecognitionStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: switch (status) {
        RecognitionStatus.analyzing => const SizedBox(
            key: ValueKey('analyzing'),
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              color: Colors.teal,
              strokeWidth: 3,
            ),
          ),
        RecognitionStatus.suggestion => Icon(
            key: const ValueKey('suggestion'),
            Icons.lightbulb_outline,
            size: 72,
            color: Colors.amberAccent.withOpacity(0.8),
          ),
        RecognitionStatus.confirmed => const Icon(
            key: ValueKey('confirmed'),
            Icons.check_circle_outline,
            size: 72,
            color: Colors.greenAccent,
          ),
        RecognitionStatus.lost => Icon(
            key: const ValueKey('lost'),
            Icons.visibility_off_outlined,
            size: 72,
            color: Colors.orangeAccent.withOpacity(0.7),
          ),
        RecognitionStatus.idle => const Icon(
            key: ValueKey('idle'),
            Icons.image_search,
            size: 72,
            color: Colors.white24,
          ),
      },
    );
  }
}
