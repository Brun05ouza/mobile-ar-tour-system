import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Locais do circuito',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.borderSubtle,
          ),
        ),
      ),
      body: AppBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todos',
                    icon: Icons.list_rounded,
                    active: filter == PointFilter.all,
                    onTap: () =>
                        ref.read(filterProvider.notifier).state = PointFilter.all,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Visitados',
                    icon: Icons.check_circle_outline_rounded,
                    active: filter == PointFilter.visited,
                    color: const Color(0xFF6BCB9E),
                    onTap: () => ref.read(filterProvider.notifier).state =
                        PointFilter.visited,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Favoritos',
                    icon: Icons.favorite_border_rounded,
                    active: filter == PointFilter.favorites,
                    color: const Color(0xFFE8A0BF),
                    onTap: () => ref.read(filterProvider.notifier).state =
                        PointFilter.favorites,
                  ),
                ],
              ),
            ),
            Expanded(
              child: pointsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (_, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: AppColors.textHint.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Não foi possível carregar os locais.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Verifique a ligação à Internet e tente novamente.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textHint,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (points) {
                  final filtered =
                      _applyFilter(points, filter, visited, favorites);

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
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.22)
              : AppColors.textPrimary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.55)
                : AppColors.textPrimary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? color : AppColors.textHint,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: active ? color : AppColors.textHint,
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          color: AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isVisited
                ? const Color(0xFF6BCB9E).withValues(alpha: 0.35)
                : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
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
                          ? const Color(0xFF6BCB9E).withValues(alpha: 0.5)
                          : AppColors.textPrimary.withValues(alpha: 0.12),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: point.imagePath.isNotEmpty
                        ? Image.asset(
                            point.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.hide_image_outlined,
                                color: AppColors.accent.withValues(alpha: 0.65),
                                size: 28,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            child: Icon(
                              Icons.place_rounded,
                              color: AppColors.accent,
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
                        color: const Color(0xFF6BCB9E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.bgDeep,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF1A1510),
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
                        color: AppColors.bgDeep,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE8A0BF).withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFE8A0BF),
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
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isVisited)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6BCB9E).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Visitado',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFB8F0D8),
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
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

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
              isVisited ? Icons.explore_off_rounded : Icons.favorite_border_rounded,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              isVisited
                  ? 'Ainda não visitou nenhum local'
                  : 'Ainda não tem favoritos',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isVisited
                  ? 'Use a experiência em AR para descobrir um monumento.'
                  : 'Abra os detalhes de um local e toque no coração para guardar.',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textHint,
                fontSize: 13,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
