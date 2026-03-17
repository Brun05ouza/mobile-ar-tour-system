import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/point_model.dart';
import '../../data/providers/user_prefs_provider.dart';

class DetailsScreen extends ConsumerWidget {
  final PointModel point;

  const DetailsScreen({super.key, required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visited = ref.watch(visitedProvider);
    final favorites = ref.watch(favoritesProvider);
    final isVisited = visited.contains(point.id);
    final isFavorite = favorites.contains(point.id);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: CustomScrollView(
        slivers: [
          // ── AppBar expansível ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF0F1117),
            foregroundColor: Colors.white,
            actions: [
              // Botão favoritar
              IconButton(
                tooltip: isFavorite ? 'Remover dos favoritos' : 'Favoritar',
                onPressed: () => ref.read(favoritesProvider.notifier).toggle(point.id),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(isFavorite),
                    color: isFavorite ? Colors.pinkAccent : Colors.white54,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                point.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isVisited
                        ? [const Color(0xFF1B5E20), const Color(0xFF004D40)]
                        : [const Color(0xFF00897B), const Color(0xFF004D40)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    isVisited ? Icons.check_circle_outline : Icons.place,
                    size: 80,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Badges de status ───────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.teal.withOpacity(0.5)),
                        ),
                        child: Text(
                          point.id,
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      if (isVisited) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 13, color: Colors.greenAccent),
                              SizedBox(width: 5),
                              Text(
                                'Visitado',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isFavorite) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.pink.withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite,
                                  size: 13, color: Colors.pinkAccent),
                              SizedBox(width: 5),
                              Text(
                                'Favorito',
                                style: TextStyle(
                                  color: Colors.pinkAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Descrição ──────────────────────────────────────────────
                  const Text(
                    'Sobre este ponto',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    point.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  if (point.details.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Detalhes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      point.details,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Info cards ─────────────────────────────────────────────
                  _InfoCard(
                    icon: Icons.location_on,
                    title: 'Localização',
                    content:
                        'Lat: ${point.latitude.toStringAsFixed(4)}\nLon: ${point.longitude.toStringAsFixed(4)}',
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    icon: Icons.image_search,
                    title: 'Marcador AR',
                    content: point.imageReference,
                  ),

                  const SizedBox(height: 28),

                  // ── Ações ──────────────────────────────────────────────────
                  Row(
                    children: [
                      // Marcar / desmarcar visitado
                      Expanded(
                        child: _ActionButton(
                          icon: isVisited
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          label: isVisited ? 'Visitado' : 'Marcar Visitado',
                          color: Colors.green,
                          active: isVisited,
                          onTap: () {
                            if (isVisited) {
                              ref
                                  .read(visitedProvider.notifier)
                                  .unmarkVisited(point.id);
                            } else {
                              ref
                                  .read(visitedProvider.notifier)
                                  .markVisited(point.id);
                              _showSnack(context, '✓ Marcado como visitado!',
                                  Colors.green);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Favoritar
                      Expanded(
                        child: _ActionButton(
                          icon: isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          label: isFavorite ? 'Favoritado' : 'Favoritar',
                          color: Colors.pinkAccent,
                          active: isFavorite,
                          onTap: () {
                            ref
                                .read(favoritesProvider.notifier)
                                .toggle(point.id);
                            if (!isFavorite) {
                              _showSnack(context, '♥ Adicionado aos favoritos!',
                                  Colors.pinkAccent);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Botão voltar para AR
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Voltar para AR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.2) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? color.withOpacity(0.5) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? color : Colors.white38, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? color : Colors.white38,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.tealAccent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
