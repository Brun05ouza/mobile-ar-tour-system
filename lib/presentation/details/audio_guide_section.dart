import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Reprodutor de áudio guia a partir de um asset local (offline).
///
/// Pausa ao ir para segundo plano; liberta o player no [dispose] (pop da tela).
class AudioGuideSection extends StatefulWidget {
  final String audioAssetPath;

  const AudioGuideSection({super.key, required this.audioAssetPath});

  @override
  State<AudioGuideSection> createState() => _AudioGuideSectionState();
}

class _AudioGuideSectionState extends State<AudioGuideSection>
    with WidgetsBindingObserver {
  late final AudioPlayer _player;
  bool _loaded = false;
  String? _loadError;
  bool _dragging = false;
  double _dragValue = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = AudioPlayer();
    _load();
  }

  Future<void> _load() async {
    try {
      await _player.setAsset(widget.audioAssetPath);
      if (mounted) setState(() => _loaded = true);
    } catch (e) {
      if (mounted) {
        setState(() => _loadError = 'Não foi possível carregar o áudio.');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _player.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  static String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _loadError!,
                style: TextStyle(color: Colors.red.shade200, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    if (!_loaded) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 14),
            Text(
              'A carregar áudio…',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.headphones, color: Colors.tealAccent, size: 22),
              SizedBox(width: 10),
              Text(
                'Áudio guia',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<bool>(
            stream: _player.playingStream,
            initialData: _player.playing,
            builder: (context, playingSnap) {
              final playing = playingSnap.data ?? false;
              return Row(
                children: [
                  IconButton.filled(
                    onPressed: () {
                      if (playing) {
                        _player.pause();
                      } else {
                        _player.play();
                      }
                    },
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.teal.withOpacity(0.35),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildProgressSlider()),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, posSnap) {
              return StreamBuilder<Duration?>(
                stream: _player.durationStream,
                builder: (context, durSnap) {
                  final position = posSnap.data ?? Duration.zero;
                  final duration = durSnap.data ?? Duration.zero;
                  final displayPos = _dragging
                      ? Duration(
                          milliseconds:
                              (_dragValue * duration.inMilliseconds).round(),
                        )
                      : position;
                  return Text(
                    '${_formatDuration(displayPos)} / ${_formatDuration(duration)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider() {
    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, posSnap) {
        return StreamBuilder<Duration?>(
          stream: _player.durationStream,
          builder: (context, durSnap) {
            final position = posSnap.data ?? Duration.zero;
            final duration = durSnap.data ?? Duration.zero;
            final maxMs = duration.inMilliseconds;
            final progress = maxMs > 0
                ? (position.inMilliseconds / maxMs).clamp(0.0, 1.0)
                : 0.0;
            final value = _dragging ? _dragValue : progress;

            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.tealAccent,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.tealAccent,
                overlayColor: Colors.teal.withOpacity(0.2),
              ),
              child: Slider(
                value: value.clamp(0.0, 1.0),
                onChanged: maxMs > 0
                    ? (v) {
                        setState(() {
                          _dragging = true;
                          _dragValue = v;
                        });
                      }
                    : null,
                onChangeEnd: maxMs > 0
                    ? (v) {
                        setState(() => _dragging = false);
                        _player.seek(
                          Duration(milliseconds: (v * maxMs).round()),
                        );
                      }
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
