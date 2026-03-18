import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/point_model.dart';
import '../../data/providers/points_provider.dart';
import '../../data/providers/user_prefs_provider.dart';
import '../details/details_screen.dart';

class PointsListScreen extends ConsumerWidget {
  const PointsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(pointsProvider);
    final filter = ref.watch(filterProvider);
    final visited = ref.watch(visitedProvider);
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        title: const Text('Pontos do Tour'),
        backgroundColor: const Color(0xFF0F1117),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withOpacity(0.08)),
        ),
      ),
      body: Column(
        children: [
          // ── Barra de filtros ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  icon: Icons.list,
                  active: filter == PointFilter.all,
                  onTap: () => ref.read(filterProvider.notifier).state = PointFilter.all,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Visitados',
                  icon: Icons.check_circle_outline,
                  active: filter == PointFilter.visited,
                  color: Colors.green,
                  onTap: () => ref.read(filterProvider.notifier).state = PointFilter.visited,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Favoritos',
                  icon: Icons.favorite_border,
                  active: filter == PointFilter.favorites,
                  color: Colors.pinkAccent,
                  onTap: () => ref.read(filterProvider.notifier).state = PointFilter.favorites,
                ),
              ],
            ),
          ),

          // ── Lista ─────────────────────────────────────────────────────────
          Expanded(
            child: pointsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              ),
              error: (e, _) => Center(
                child: Text('Erro ao carregar pontos: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (points) {
                final filtered = _applyFilter(points, filter, visited, favorites);

                if (filtered.isEmpty) {
                  return _EmptyState(filter: filter);
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final point = filtered[index];
                    final isVisited = visited.contains(point.id);
                    final isFavorite = favorites.contains(point.id);

                    return _AnimatedCard(
                      index: index,
                      child: _PointCard(
                        point: point,
                        isVisited: isVisited,
                        isFavorite: isFavorite,
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                DetailsScreen(point: point),
                            transitionDuration:
                                const Duration(milliseconds: 350),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<PointModel> _applyFilter(
    List<PointModel> points,
    PointFilter filter,
    Set<String> visited,
    Set<String> favorites,
  ) {
    switch (filter) {
      case PointFilter.all:
        return points;
      case PointFilter.visited:
        return points.where((p) => visited.contains(p.id)).toList();
      case PointFilter.favorites:
        return points.where((p) => favorites.contains(p.id)).toList();
    }
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.color = Colors.teal,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color.withOpacity(0.6) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? color : Colors.white38),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? color : Colors.white38,
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Point Card ────────────────────────────────────────────────────────────────

class _PointCard extends StatelessWidget {
  final PointModel point;
  final bool isVisited;
  final bool isFavorite;
  final VoidCallback onTap;

  const _PointCard({
    required this.point,
    required this.isVisited,
    required this.isFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isVisited
                ? Colors.green.withOpacity(0.35)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail do ponto com badge de favorito/visitado
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isVisited
                          ? Colors.green.withOpacity(0.5)
                          : Colors.white.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: point.imagePath.isNotEmpty
                        ? Image.asset(
                            point.imagePath,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.teal.withOpacity(0.2),
                            child: Icon(
                              Icons.place,
                              color: Colors.tealAccent,
                              size: 28,
                            ),
                          ),
                  ),
                ),
                if (isVisited)
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF0F1117), width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                if (isFavorite)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1117),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.pinkAccent.withOpacity(0.5),
                            width: 1),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.pinkAccent,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          point.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isVisited)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Visitado',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    point.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.image_search, size: 12, color: Colors.teal),
                      const SizedBox(width: 4),
                      Text(
                        point.imageReference,
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Animated Card (staggered entrada) ─────────────────────────────────────────

class _AnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedCard({required this.index, required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final PointFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final isVisited = filter == PointFilter.visited;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVisited ? Icons.explore_off : Icons.favorite_border,
              size: 64,
              color: Colors.white12,
            ),
            const SizedBox(height: 16),
            Text(
              isVisited
                  ? 'Nenhum ponto visitado ainda'
                  : 'Nenhum ponto favoritado ainda',
              style: const TextStyle(color: Colors.white38, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isVisited
                  ? 'Use o AR para escanear um ponto turístico'
                  : 'Abra os detalhes de um ponto e toque no coração',
              style: const TextStyle(color: Colors.white24, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
