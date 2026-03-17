import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_prefs_service.dart';

// ── Visitados ─────────────────────────────────────────────────────────────────

class VisitedNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => UserPrefsService.allVisited;

  Future<void> markVisited(String pointId) async {
    await UserPrefsService.markVisited(pointId);
    state = UserPrefsService.allVisited;
  }

  Future<void> unmarkVisited(String pointId) async {
    await UserPrefsService.markVisited(pointId, value: false);
    state = UserPrefsService.allVisited;
  }

  bool isVisited(String pointId) => state.contains(pointId);
}

final visitedProvider = NotifierProvider<VisitedNotifier, Set<String>>(
  VisitedNotifier.new,
);

// ── Favoritos ─────────────────────────────────────────────────────────────────

class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => UserPrefsService.allFavorites;

  Future<void> toggle(String pointId) async {
    await UserPrefsService.toggleFavorite(pointId);
    state = UserPrefsService.allFavorites;
  }

  bool isFavorite(String pointId) => state.contains(pointId);
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

// ── Filtro da lista ───────────────────────────────────────────────────────────

enum PointFilter { all, visited, favorites }

final filterProvider = StateProvider<PointFilter>((ref) => PointFilter.all);
