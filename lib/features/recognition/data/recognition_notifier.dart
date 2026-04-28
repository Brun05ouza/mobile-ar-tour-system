import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/point_model.dart';
import '../../../data/services/points_service.dart';
import '../domain/recognition_candidate.dart';
import '../domain/recognition_state_model.dart';
import '../domain/recognition_status.dart';
import 'recognition_channel.dart';

/// Provider global do estado de reconhecimento híbrido.
final recognitionProvider =
    NotifierProvider<RecognitionNotifier, RecognitionStateModel>(
  RecognitionNotifier.new,
);

/// Notifier que gerencia o estado do pipeline de reconhecimento híbrido.
///
/// Responsabilidades:
///   - Escutar o EventChannel do Android nativo
///   - Traduzir eventos em mutações do [RecognitionStateModel]
///   - Decidir quando abrir card automático vs. mostrar sugestão
///   - Expor ações para a UI (iniciar, parar, confirmar, ignorar)
class RecognitionNotifier extends Notifier<RecognitionStateModel> {
  StreamSubscription<Map<String, dynamic>>? _subscription;

  @override
  RecognitionStateModel build() => const RecognitionStateModel.initial();

  // ── Controle do pipeline ──────────────────────────────────────────────────

  /// Inicia o reconhecimento híbrido abrindo a HybridArActivity.
  Future<void> startRecognition() async {
    state = state.copyWith(
      status: RecognitionStatus.analyzing,
      lastDebugMessage: 'A preparar a experiência…',
    );

    _listenToEvents();

    try {
      await RecognitionChannel.startHybridRecognition();
    } catch (e) {
      state = state.copyWith(
        status: RecognitionStatus.idle,
        lastDebugMessage: 'Não foi possível iniciar. Tente novamente.',
      );
    }
  }

  /// Para o reconhecimento e cancela o stream de eventos.
  Future<void> stopRecognition() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      await RecognitionChannel.stopHybridRecognition();
    } catch (_) {}
    state = const RecognitionStateModel.initial();
  }

  /// Usuário confirmou a sugestão manualmente.
  void confirmSuggestion() {
    final suggested = state.suggestedPoint;
    if (suggested == null) return;
    state = state.copyWith(
      status: RecognitionStatus.confirmed,
      confirmedPoint: suggested,
      clearSuggested: true,
    );
  }

  /// Usuário ignorou a sugestão.
  void dismissSuggestion() {
    state = state.copyWith(
      status: RecognitionStatus.analyzing,
      clearSuggested: true,
      lastDebugMessage: 'A procurar outra sugestão…',
    );
  }

  /// Reconhecimento perdido — volta para análise.
  void onRecognitionLost() {
    state = state.copyWith(
      status: RecognitionStatus.lost,
      markerDetected: false,
      clearConfirmed: true,
      clearSuggested: true,
      lastDebugMessage: 'A recalibrar a vista…',
    );

    // Retorna ao estado "analyzing" após breve delay
    Future.delayed(const Duration(seconds: 2), () {
      if (state.status == RecognitionStatus.lost) {
        state = state.copyWith(status: RecognitionStatus.analyzing);
      }
    });
  }

  // ── Escuta de eventos ─────────────────────────────────────────────────────

  void _listenToEvents() {
    _subscription?.cancel();
    _subscription = RecognitionChannel.events.listen(
      _handleEvent,
      onError: (e) {
        state = state.copyWith(
          lastDebugMessage: 'Ligação interrompida. Reabra o ecrã se necessário.',
        );
      },
    );
  }

  Future<void> _handleEvent(Map<String, dynamic> event) async {
    final type = event['type'] as String? ?? '';

    switch (type) {
      case RecognitionChannel.eventMarkerDetected:
        await _onMarkerDetected(event);
        break;

      case RecognitionChannel.eventConfirmed:
        await _onConfirmed(event);
        break;

      case RecognitionChannel.eventSuggestion:
        await _onSuggestion(event);
        break;

      case RecognitionChannel.eventLost:
        onRecognitionLost();
        break;

      case RecognitionChannel.eventLocationUpdate:
        _onLocationUpdate(event);
        break;

      case RecognitionChannel.eventDebug:
        _onDebugInfo(event);
        break;

      case RecognitionChannel.eventSessionFailed:
        final msg = event['message'] as String? ?? 'AR indisponível';
        state = state.copyWith(
          status: RecognitionStatus.idle,
          lastDebugMessage: msg,
        );
        break;

      default:
        break;
    }
  }

  Future<void> _onMarkerDetected(Map<String, dynamic> event) async {
    final confidence = (event['confidence'] as num?)?.toDouble() ?? 1.0;

    state = state.copyWith(
      markerDetected: true,
      recognitionConfidence: confidence,
      lastDebugMessage: 'Sinal do local detetado.',
    );
  }

  Future<void> _onConfirmed(Map<String, dynamic> event) async {
    final pointId = event['pointId'] as String? ?? '';
    final confidence = (event['score'] as num?)?.toDouble() ?? 0.0;

    final point = await _findPoint(pointId);

    state = state.copyWith(
      status: RecognitionStatus.confirmed,
      confirmedPoint: point,
      recognitionConfidence: confidence,
      clearSuggested: true,
      lastDebugMessage: 'Local confirmado.',
    );
  }

  Future<void> _onSuggestion(Map<String, dynamic> event) async {
    final pointId = event['pointId'] as String? ?? '';
    final score = (event['score'] as num?)?.toDouble() ?? 0.0;

    // Não substituir uma confirmação por uma sugestão
    if (state.status == RecognitionStatus.confirmed) return;

    final point = await _findPoint(pointId);

    state = state.copyWith(
      status: RecognitionStatus.suggestion,
      suggestedPoint: point,
      recognitionConfidence: score,
      lastDebugMessage: 'Sugestão disponível — confirme abaixo.',
    );
  }

  void _onLocationUpdate(Map<String, dynamic> event) {
    final lat = (event['lat'] as num?)?.toDouble();
    final lon = (event['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return;

    state = state.copyWith(
      locationLoaded: true,
      userLat: lat,
      userLon: lon,
    );
  }

  void _onDebugInfo(Map<String, dynamic> event) {
    final message = event['message'] as String? ?? '';
    final rawCandidates = event['candidates'] as List<dynamic>? ?? [];

    final candidates = rawCandidates.map((e) {
      final m = e as Map<dynamic, dynamic>;
      return _candidateFromMap(Map<String, dynamic>.from(m));
    }).toList();

    state = state.copyWith(
      nearbyCandidates: candidates,
      lastDebugMessage: message,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<PointModel?> _findPoint(String pointId) async {
    if (pointId.isEmpty) return null;
    try {
      final points = await PointsService.loadAll();
      return points.firstWhere((p) => p.id == pointId);
    } catch (_) {
      return null;
    }
  }

  RecognitionCandidate _candidateFromMap(Map<String, dynamic> m) {
    // Cria um candidato mínimo a partir do mapa de debug do Android
    // (não há PointModel completo disponível aqui, apenas os dados de score)
    final dummy = PointModel(
      id: m['pointId'] as String? ?? '',
      name: m['pointName'] as String? ?? '',
      description: '',
      imageReference: '',
      latitude: 0,
      longitude: 0,
    );
    return RecognitionCandidate(
      point: dummy,
      geoScore: (m['geoScore'] as num?)?.toDouble() ?? 0.0,
      markerScore: (m['markerScore'] as num?)?.toDouble() ?? 0.0,
      visualScore: (m['visualScore'] as num?)?.toDouble() ?? 0.0,
      finalScore: (m['finalScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
