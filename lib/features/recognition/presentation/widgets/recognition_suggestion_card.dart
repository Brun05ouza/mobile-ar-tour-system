import 'package:flutter/material.dart';

import '../../../../data/models/point_model.dart';

/// Card de sugestão apresentado quando o score atinge o threshold médio.
///
/// Exibe: "Talvez você esteja vendo: [nome do local]"
/// Ações: Confirmar / Ignorar
class RecognitionSuggestionCard extends StatefulWidget {
  final PointModel point;
  final double confidence;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  const RecognitionSuggestionCard({
    super.key,
    required this.point,
    required this.confidence,
    required this.onConfirm,
    required this.onDismiss,
  });

  @override
  State<RecognitionSuggestionCard> createState() =>
      _RecognitionSuggestionCardState();
}

class _RecognitionSuggestionCardState extends State<RecognitionSuggestionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1117).withOpacity(0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────────
                Row(
                  children: [
                    // Thumbnail do ponto
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: widget.point.imagePath.isNotEmpty
                          ? Image.asset(
                              widget.point.imagePath,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: Colors.amber.withOpacity(0.2),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.hide_image_outlined,
                                  color: Colors.amberAccent,
                                  size: 22,
                                ),
                              ),
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.place,
                                  color: Colors.amberAccent, size: 24),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'POSSÍVEL CORRESPONDÊNCIA',
                              style: TextStyle(
                                color: Colors.amberAccent.withOpacity(0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.point.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Container(height: 1, color: Colors.white.withOpacity(0.07)),
                const SizedBox(height: 14),

                // ── Botões ────────────────────────────────────────────────────
                Row(
                  children: [
                    // Ignorar
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onDismiss,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: BorderSide(
                              color: Colors.white.withOpacity(0.15)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Outra sugestão'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Confirmar
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: widget.onConfirm,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Sim, é este'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
