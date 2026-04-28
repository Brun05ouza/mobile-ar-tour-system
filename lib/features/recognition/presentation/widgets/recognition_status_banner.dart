import 'package:flutter/material.dart';

import '../../domain/recognition_status.dart';

/// Banner no topo da tela AR que exibe o estado atual do pipeline.
///
/// Adapta cor e ícone automaticamente ao [status] recebido.
class RecognitionStatusBanner extends StatelessWidget {
  final RecognitionStatus status;
  final String message;

  const RecognitionStatusBanner({
    super.key,
    required this.status,
    this.message = '',
  });

  @override
  Widget build(BuildContext context) {
    final config = _configForStatus(status);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(status),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: config.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: config.color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            // Ícone ou spinner
            if (status == RecognitionStatus.analyzing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: config.color,
                ),
              )
            else
              Icon(config.icon, color: config.color, size: 16),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                message.isNotEmpty ? message : config.defaultMessage,
                style: TextStyle(
                  color: config.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _BannerConfig _configForStatus(RecognitionStatus status) {
    switch (status) {
      case RecognitionStatus.idle:
        return _BannerConfig(
          color: Colors.white54,
          icon: Icons.explore_outlined,
          defaultMessage: 'Prima «Começar» para iniciar a descoberta.',
        );
      case RecognitionStatus.analyzing:
        return _BannerConfig(
          color: const Color(0xFF4FD1C5),
          icon: Icons.auto_awesome,
          defaultMessage: 'A analisar o que tem à sua volta…',
        );
      case RecognitionStatus.suggestion:
        return _BannerConfig(
          color: const Color(0xFFC9A87C),
          icon: Icons.lightbulb_outline_rounded,
          defaultMessage: 'Temos uma sugestão — confirme abaixo.',
        );
      case RecognitionStatus.confirmed:
        return _BannerConfig(
          color: const Color(0xFF4FD1C5),
          icon: Icons.verified_outlined,
          defaultMessage: 'Local confirmado.',
        );
      case RecognitionStatus.lost:
        return _BannerConfig(
          color: const Color(0xFFB8B4AB),
          icon: Icons.motion_photos_pause_outlined,
          defaultMessage: 'A recalibrar…',
        );
    }
  }
}

class _BannerConfig {
  final Color color;
  final IconData icon;
  final String defaultMessage;

  _BannerConfig({
    required this.color,
    required this.icon,
    required this.defaultMessage,
  });
}
