import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';
import '../../data/models/point_model.dart';
import '../../data/providers/user_prefs_provider.dart';
import '../details/details_screen.dart';

class ArOverlayCard extends ConsumerStatefulWidget {
  final PointModel point;
  final VoidCallback onClose;

  const ArOverlayCard({
    super.key,
    required this.point,
    required this.onClose,
  });

  @override
  ConsumerState<ArOverlayCard> createState() => _ArOverlayCardState();
}

class _ArOverlayCardState extends ConsumerState<ArOverlayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(visitedProvider.notifier).markVisited(widget.point.id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fechar() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = ref.watch(favoritesProvider).contains(widget.point.id);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.point.imagePath.isNotEmpty
                          ? Image.asset(
                              widget.point.imagePath,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: AppColors.accent.withValues(alpha: 0.15),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.hide_image_outlined,
                                  color: AppColors.accent.withValues(alpha: 0.75),
                                  size: 26,
                                ),
                              ),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.place_rounded,
                                color: AppColors.accent,
                                size: 28,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'LOCAL RECONHECIDO',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6BCB9E)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 10,
                                      color: const Color(0xFFB8F0D8),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'VISITADO',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB8F0D8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.point.name,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(favoritesProvider.notifier)
                          .toggle(widget.point.id),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          key: ValueKey(isFavorite),
                          color: isFavorite
                              ? const Color(0xFFE8A0BF)
                              : AppColors.textHint,
                          size: 22,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _fechar,
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.point.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsScreen(point: widget.point),
                      ),
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: Text(
                      'Ver detalhes',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: const Color(0xFF1A1510),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
