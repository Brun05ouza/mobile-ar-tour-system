import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/points_provider.dart';
import '../details/details_screen.dart';

class PointsListScreen extends ConsumerWidget {
  const PointsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(pointsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        title: const Text('Pontos do Tour'),
        backgroundColor: const Color(0xFF0F1117),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ),
      body: pointsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
        error: (e, _) => Center(
          child: Text('Erro ao carregar pontos: $e',
              style: const TextStyle(color: Colors.red)),
        ),
        data: (points) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: points.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final point = points[index];
            return _PointCard(
              index: index + 1,
              name: point.name,
              description: point.description,
              marker: point.imageReference,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailsScreen(point: point),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  final int index;
  final String name;
  final String description;
  final String marker;
  final VoidCallback onTap;

  const _PointCard({
    required this.index,
    required this.name,
    required this.description,
    required this.marker,
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
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
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
                      const Icon(Icons.image_search,
                          size: 12, color: Colors.teal),
                      const SizedBox(width: 4),
                      Text(
                        marker,
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
            const Icon(Icons.chevron_right,
                color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }
}
