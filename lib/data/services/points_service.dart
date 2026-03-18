import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../models/point_model.dart';

/// Serviço responsável por carregar e consultar os pontos turísticos.
///
/// Lê de [assets/content/points.json] (novo caminho). Se não encontrar,
/// usa o caminho legado [assets/data/points.json] para compatibilidade.
class PointsService {
  static List<PointModel>? _cache;

  static Future<List<PointModel>> loadAll() async {
    if (_cache != null) return _cache!;

    String raw;
    try {
      raw = await rootBundle.loadString('assets/content/points.json');
    } catch (_) {
      raw = await rootBundle.loadString('assets/data/points.json');
    }

    final list = json.decode(raw) as List<dynamic>;
    _cache = list
        .map((e) => PointModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  static Future<PointModel?> findByImageReference(String imageReference) async {
    final points = await loadAll();
    try {
      return points.firstWhere((p) => p.imageReference == imageReference);
    } catch (_) {
      return null;
    }
  }

  /// Retorna todos os pontos dentro de [radiusMeters] da posição fornecida.
  static Future<List<PointModel>> findNearby({
    required double lat,
    required double lon,
    double radiusMeters = 300,
  }) async {
    final points = await loadAll();
    return points
        .where((p) =>
            haversineMeters(lat, lon, p.latitude, p.longitude) <= radiusMeters)
        .toList();
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
