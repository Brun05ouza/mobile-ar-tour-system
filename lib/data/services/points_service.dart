import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/point_model.dart';

class PointsService {
  static List<PointModel>? _cache;

  static Future<List<PointModel>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/points.json');
    final list = json.decode(raw) as List<dynamic>;
    _cache = list.map((e) => PointModel.fromJson(e as Map<String, dynamic>)).toList();
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
}
