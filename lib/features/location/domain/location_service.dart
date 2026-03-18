import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../../../data/models/point_model.dart';

/// Resultado da obtenção de localização.
class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });
}

/// Serviço de localização desacoplado.
///
/// Usa o pacote [geolocator] para obter posição e calcular candidatos próximos.
/// Failsafe: todos os métodos retornam null/lista vazia em caso de erro,
/// nunca propagam exceção para a UI.
class LocationService {
  /// Raio padrão de busca de pontos próximos, em metros.
  static const double defaultRadiusMeters = 300.0;

  /// Solicita permissão e retorna a posição atual do usuário.
  ///
  /// Retorna null se:
  ///   - permissão negada
  ///   - GPS desativado
  ///   - timeout ou erro de plataforma
  static Future<LocationResult?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
      );
    } catch (_) {
      return null;
    }
  }

  /// Retorna stream contínuo de posições.
  ///
  /// Emite null silenciosamente em caso de erro.
  static Stream<LocationResult?> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).map((pos) => LocationResult(
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
        )).handleError((_) => null);
  }

  /// Filtra [points] retornando apenas os que estão dentro de [radiusMeters]
  /// da posição [lat]/[lon].
  static List<PointModel> filterNearby({
    required List<PointModel> points,
    required double lat,
    required double lon,
    double radiusMeters = defaultRadiusMeters,
  }) {
    return points
        .where((p) =>
            haversineMeters(lat, lon, p.latitude, p.longitude) <= radiusMeters)
        .toList();
  }

  /// Calcula score de proximidade linear entre 0.0 e 1.0.
  ///
  /// score = max(0, 1 - distância/raio)
  /// Quanto mais perto, maior o score.
  static double computeGeoScore({
    required double userLat,
    required double userLon,
    required double pointLat,
    required double pointLon,
    double radiusMeters = defaultRadiusMeters,
  }) {
    final dist = haversineMeters(userLat, userLon, pointLat, pointLon);
    return (1.0 - dist / radiusMeters).clamp(0.0, 1.0);
  }

  /// Distância haversine entre dois pontos geográficos, em metros.
  static double haversineMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _rad(double deg) => deg * math.pi / 180.0;
}
