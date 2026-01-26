import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../bloc/focus_bloc.dart';

class SavedMixPlayer extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const SavedMixPlayer({
    super.key,
    required this.state,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.hasSavedMix) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.queue_music, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                'Tu Mezcla Guardada',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              final isPlaying = state.isPlayingMix;
              service.invoke('sendEvent', {'event': isPlaying ? 'pauseMix' : 'playSavedMix'});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isPlaying ? 'Mezcla pausada.' : 'Reproduciendo tu mezcla guardada...'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: state.isPlayingMix
                      ? [Colors.orange.shade900, Colors.deepOrange.shade900]
                      : [Colors.indigo.shade900, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: state.isPlayingMix ? Colors.orange.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    state.isPlayingMix ? 'Pausar Mezcla' : 'Reproducir Mezcla',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: state.isPlayingMix ? Colors.deepOrange : Colors.blueAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (state.isPlayingMix ? Colors.deepOrange : Colors.blueAccent).withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      state.isPlayingMix ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
