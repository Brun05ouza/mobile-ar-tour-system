import 'package:flutter/services.dart';

/// Gerencia toda a comunicação Flutter ↔ Android para o sistema híbrido.
///
/// Canais:
///   - [_eventChannel]: stream de eventos enviados pelo Android nativo.
///   - [_methodChannel]: chamadas pontuais Flutter → Android.
///
/// Nomes de canais são constantes para evitar typos e centralizar mudanças.
class RecognitionChannel {
  RecognitionChannel._();

  static const String _eventChannelName =
      'com.brunoouza.ar_tour/recognition_events';
  static const String _methodChannelName =
      'com.brunoouza.ar_tour/recognition_control';

  static const EventChannel _eventChannel = EventChannel(_eventChannelName);
  static const MethodChannel _methodChannel = MethodChannel(_methodChannelName);

  // ── Nomes dos eventos recebidos do Android ──────────────────────────────────

  static const String eventMarkerDetected = 'onMarkerDetected';
  static const String eventVisualMatch = 'onVisualMatch';
  static const String eventSuggestion = 'onRecognitionSuggestion';
  static const String eventConfirmed = 'onRecognitionConfirmed';
  static const String eventLost = 'onRecognitionLost';
  static const String eventDebug = 'onRecognitionDebugInfo';
  static const String eventLocationUpdate = 'onLocationUpdate';

  // ── Stream de eventos ───────────────────────────────────────────────────────

  /// Stream de eventos emitidos pelo Android nativo.
  ///
  /// Cada evento é um [Map] com campos:
  ///   - `type` (String): nome do evento (ver constantes acima)
  ///   - demais campos dependem do tipo de evento
  static Stream<Map<String, dynamic>> get events =>
      _eventChannel.receiveBroadcastStream().map((event) {
        if (event is Map) {
          return Map<String, dynamic>.from(event);
        }
        return <String, dynamic>{};
      });

  // ── Métodos ─────────────────────────────────────────────────────────────────

  /// Inicia o reconhecimento híbrido na HybridArActivity.
  static Future<void> startHybridRecognition() async {
    await _methodChannel.invokeMethod<void>('startHybridRecognition');
  }

  /// Para o reconhecimento e fecha a HybridArActivity.
  static Future<void> stopHybridRecognition() async {
    await _methodChannel.invokeMethod<void>('stopHybridRecognition');
  }

  /// Solicita a lista de candidatos próximos com base na localização atual.
  ///
  /// Retorna lista de maps `{pointId, distance, geoScore}`.
  static Future<List<Map<String, dynamic>>> getNearbyCandidates() async {
    final result = await _methodChannel
        .invokeMethod<List<dynamic>>('getNearbyCandidates');
    if (result == null) return [];
    return result
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Solicita a localização atual ao Android.
  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    final result = await _methodChannel
        .invokeMethod<Map<dynamic, dynamic>>('getCurrentLocation');
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }
}
