import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../bloc/focus_bloc.dart';
import '../sound_mixer_content.dart';
import '../hardcore_mode_card.dart';

class SoundMixerModal extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const SoundMixerModal({
    super.key,
    required this.state,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: service.on('update'),
      initialData: state.toJson(),
      builder: (context, snapshot) {
        FocusState currentState = state;
        if (snapshot.hasData && snapshot.data != null) {
          try {
            currentState = FocusState.fromJson(snapshot.data!);
          } catch (e) {
            // Fallback to initial state
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B), // Match settings menu color
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Mezclador de Sonido',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              SoundMixerContent(state: currentState, service: service),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class FocusModeModal extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const FocusModeModal({
    super.key,
    required this.state,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: service.on('update'),
      initialData: state.toJson(),
      builder: (context, snapshot) {
        FocusState currentState = state;
        if (snapshot.hasData && snapshot.data != null) {
          try {
            currentState = FocusState.fromJson(snapshot.data!);
          } catch (e) {
            // Fallback to initial state
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B), // Match settings menu color
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Modo Foco',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              HardcoreModeCard(state: currentState, service: service),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
