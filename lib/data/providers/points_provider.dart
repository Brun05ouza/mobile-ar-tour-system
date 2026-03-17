import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/point_model.dart';
import '../services/points_service.dart';

final pointsProvider = FutureProvider<List<PointModel>>((ref) async {
  return PointsService.loadAll();
});
