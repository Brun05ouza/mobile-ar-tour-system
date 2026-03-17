import 'package:hive_flutter/hive_flutter.dart';

/// Persiste preferências do usuário (visitados e favoritos) em caixas Hive separadas.
class UserPrefsService {
  static const _visitedBox = 'visited_points';
  static const _favoritesBox = 'favorite_points';

  static Box<bool> get _visited => Hive.box<bool>(_visitedBox);
  static Box<bool> get _favorites => Hive.box<bool>(_favoritesBox);

  static Future<void> openBoxes() async {
    await Hive.openBox<bool>(_visitedBox);
    await Hive.openBox<bool>(_favoritesBox);
  }

  // ── Visitados ──────────────────────────────────────────────────────────────

  static bool isVisited(String pointId) => _visited.get(pointId) ?? false;

  static Future<void> markVisited(String pointId, {bool value = true}) =>
      _visited.put(pointId, value);

  static Set<String> get allVisited =>
      _visited.keys.where((k) => _visited.get(k) == true).map((k) => k.toString()).toSet();

  // ── Favoritos ──────────────────────────────────────────────────────────────

  static bool isFavorite(String pointId) => _favorites.get(pointId) ?? false;

  static Future<void> toggleFavorite(String pointId) =>
      _favorites.put(pointId, !isFavorite(pointId));

  static Set<String> get allFavorites =>
      _favorites.keys.where((k) => _favorites.get(k) == true).map((k) => k.toString()).toSet();
}
