import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../bloc/focus_bloc.dart';

class SavedMixPlayer extends StatefulWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const SavedMixPlayer({super.key, required this.state, required this.service});

  @override
  State<SavedMixPlayer> createState() => _SavedMixPlayerState();
}

class _SavedMixPlayerState extends State<SavedMixPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Sincronizar estado inicial
    if (widget.state.isPlayingMix) {
      _iconController.forward();
    }
  }

  @override
  void didUpdateWidget(SavedMixPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animar el icono si el estado de reproducción cambia
    if (widget.state.isPlayingMix != oldWidget.state.isPlayingMix) {
      if (widget.state.isPlayingMix) {
        _iconController.forward();
      } else {
        _iconController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.state.hasSavedMix) return const SizedBox.shrink();

    final isPlaying = widget.state.isPlayingMix;

    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),

      child: InkWell(
        onTap: () {
          widget.service.invoke('sendEvent', {
            'event': isPlaying ? 'pauseMix' : 'playSavedMix',
          });

          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(
          //       isPlaying
          //           ? 'Mezcla pausada.'
          //           : 'Reproduciendo tu mezcla guardada...',
          //     ),
          //
          //     duration: const Duration(seconds: 2),
          //
          //     behavior: SnackBarBehavior.floating,
          //   ),
          // );
        },

        borderRadius: BorderRadius.circular(16),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),

          curve: Curves.easeInOut,

          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPlaying
                  ? [Colors.orange.shade900, Colors.deepOrange.shade900]
                  : [Colors.indigo.shade900, Colors.blue.shade900],

              begin: Alignment.topLeft,

              end: Alignment.bottomRight,
            ),

            borderRadius: BorderRadius.circular(16),

            border: Border.all(
              color: isPlaying
                  ? Colors.orange.withValues(alpha: 0.5)
                  : Colors.blue.withValues(alpha: 0.5),

              width: 1.5,
            ),

            boxShadow: [
              BoxShadow(
                color: (isPlaying ? Colors.orange : Colors.blue).withValues(
                  alpha: 0.2,
                ),

                blurRadius: 15,

                offset: const Offset(0, 6),
              ),
            ],
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Row(
                children: [
                  const Icon(Icons.queue_music, size: 24, color: Colors.white),

                  const SizedBox(width: 12),

                  const Text(
                    'Tu Mezcla Guardada',

                    style: TextStyle(
                      color: Colors.white,

                      fontSize: 16,

                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 500),

                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(
                  color: isPlaying ? Colors.deepOrange : Colors.blueAccent,

                  shape: BoxShape.circle,

                  boxShadow: [
                    BoxShadow(
                      color: (isPlaying ? Colors.deepOrange : Colors.blueAccent)
                          .withValues(alpha: 0.4),

                      blurRadius: 8,

                      spreadRadius: 2,
                    ),
                  ],
                ),

                child: AnimatedIcon(
                  icon: AnimatedIcons.play_pause,

                  progress: _iconController,

                  color: Colors.white,

                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
