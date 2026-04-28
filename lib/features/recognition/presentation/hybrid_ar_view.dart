import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../presentation/ar/ar_overlay_card.dart';
import '../../../presentation/details/details_screen.dart';
import '../../../presentation/home/home_screen.dart';
import '../data/recognition_notifier.dart';
import '../domain/recognition_status.dart';
import 'widgets/recognition_status_banner.dart';
import 'widgets/recognition_suggestion_card.dart';

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

    ref.listen(recognitionProvider, (prev, next) {
      if (next.status == RecognitionStatus.confirmed &&
          next.confirmedPoint != null &&
          prev?.status != RecognitionStatus.confirmed) {
        final point = next.confirmedPoint!;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => DetailsScreen(point: point),
              transitionDuration: const Duration(milliseconds: 350),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          );
        });
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Descoberta guiada',
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
          if (state.status != RecognitionStatus.analyzing)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Recomeçar',
              onPressed: () {
                ref.read(recognitionProvider.notifier).stopRecognition();
                _started = false;
                _startRecognition();
              },
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
                      _StatusIcon(status: state.status),
                      const SizedBox(height: 28),
                      Text(
                        _mainMessage(state.status),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          height: 1.55,
                        ),
                      ),
                      if (state.nearbyCandidates.isNotEmpty &&
                          state.status == RecognitionStatus.analyzing) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Há locais do circuito próximos de si.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.teal.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (state.status == RecognitionStatus.idle) ...[
                        const SizedBox(height: 36),
                        FilledButton.icon(
                          onPressed: () {
                            _started = false;
                            _startRecognition();
                          },
                          icon: const Icon(Icons.play_circle_outline, size: 22),
                          label: Text(
                            'Começar',
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
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: RecognitionStatusBanner(
                  status: state.status,
                  message: '',
                ),
              ),
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
            ],
          ),
        ),
      ),
    );
  }

  String _mainMessage(RecognitionStatus status) {
    switch (status) {
      case RecognitionStatus.idle:
        return 'Prima «Começar» para iniciar. Mantenha o telemóvel estável enquanto exploramos o espaço à sua volta.';
      case RecognitionStatus.analyzing:
        return 'Um momento — estamos a preparar a melhor sugestão para onde está.';
      case RecognitionStatus.suggestion:
        return 'Confirme se reconhece o local sugerido ou peça outra sugestão.';
      case RecognitionStatus.confirmed:
        return 'Perfeito — este é o seu próximo destaque.';
      case RecognitionStatus.lost:
        return 'A voltar a analisar o ambiente…';
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final RecognitionStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: switch (status) {
        RecognitionStatus.analyzing => SizedBox(
            key: const ValueKey('analyzing'),
            width: 88,
            height: 88,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2.5,
            ),
          ),
        RecognitionStatus.suggestion => Icon(
            key: const ValueKey('suggestion'),
            Icons.lightbulb_outline_rounded,
            size: 88,
            color: AppColors.accent.withValues(alpha: 0.95),
          ),
        RecognitionStatus.confirmed => Icon(
            key: const ValueKey('confirmed'),
            Icons.verified_outlined,
            size: 88,
            color: AppColors.teal.withValues(alpha: 0.95),
          ),
        RecognitionStatus.lost => Icon(
            key: const ValueKey('lost'),
            Icons.motion_photos_pause_outlined,
            size: 88,
            color: AppColors.textHint,
          ),
        RecognitionStatus.idle => Icon(
            key: const ValueKey('idle'),
            Icons.explore_outlined,
            size: 88,
            color: AppColors.textHint,
          ),
      },
    );
  }
}
