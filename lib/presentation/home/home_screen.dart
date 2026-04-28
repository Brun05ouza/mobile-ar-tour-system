import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';
import '../../features/recognition/presentation/hybrid_ar_view.dart';
import '../ar/ar_view.dart';
import '../list/points_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  static const int _itemCount = 5;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fades = List.generate(_itemCount, (i) {
      final start = i * 0.12;
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, (start + 0.55).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      );
    });

    _slides = List.generate(_itemCount, (i) {
      final start = i * 0.12;
      return Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, (start + 0.55).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic),
      ));
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) => FadeTransition(
        opacity: _fades[index],
        child: SlideTransition(position: _slides[index], child: child),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Selo / marca
                _animated(
                  0,
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: AppGradients.goldShimmer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.travel_explore_rounded,
                            color: AppColors.accent,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VISITAR',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                                color: AppColors.accent,
                              ),
                            ),
                            Text(
                              AppBrand.name,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Título editorial
                _animated(
                  1,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'O circuito\nao seu ritmo',
                        style: AppTheme.displayLarge(context),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppBrand.tagline,
                        style: AppTheme.bodyMuted(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Menu
                _animated(
                  2,
                  _MenuCard(
                    icon: Icons.center_focus_strong_rounded,
                    title: 'Reconhecer por imagem',
                    subtitle:
                        'Aponte a câmara para as ilustrações oficiais e desbloqueie a história de cada local.',
                    accent: AppColors.teal,
                    onTap: () => Navigator.push(
                      context,
                      _fadeRoute(const ArView()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _animated(
                  3,
                  _MenuCard(
                    icon: Icons.auto_awesome_mosaic_outlined,
                    title: 'Descoberta guiada',
                    subtitle:
                        'Sugestões inteligentes com base na sua posição — confirme quando reconhecer o sítio.',
                    accent: AppColors.accent,
                    onTap: () => Navigator.push(
                      context,
                      _fadeRoute(const HybridArView()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _animated(
                  4,
                  _MenuCard(
                    icon: Icons.map_outlined,
                    title: 'Locais do circuito',
                    subtitle:
                        'Navegue por todos os pontos, favoritos e locais já visitados.',
                    accent: AppColors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      _fadeRoute(const PointsListScreen()),
                    ),
                  ),
                ),

                const Spacer(),

                Center(
                  child: Text(
                    AppBrand.footerHint,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textHint,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PageRoute<T> _fadeRoute<T>(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      );
}

class _MenuCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: _pressed ? 0.95 : 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.accent.withValues(alpha: _pressed ? 0.45 : 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: _pressed ? 8 : 20,
                offset: Offset(0, _pressed ? 2 : 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.accent, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: widget.accent.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
