import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/domain/entities/phone_orientation.dart';
import 'package:focus_flow/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/presentation/widgets/ad_banner_widget.dart';

import '../bloc/focus_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FlutterBackgroundService().on('update'),
      builder: (context, snapshot) {
        FocusState state;
        if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
          // While waiting for the first state from the service, show a loading screen.
          state = const FocusState();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          // If the stream is connected but there's no data, use a safe initial state.
          print('[HomePage] Stream has no data. Using initial state.');
          state = const FocusState();
        } else {
          // Decode the state from the JSON map received from the service.
          state = FocusState.fromJson(snapshot.data!);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('FocusFlow'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: const [],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FocusState state) {
    final service = FlutterBackgroundService();
    if (state.status == AppStatus.initial || state.status == AppStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == AppStatus.error) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 64),
              SizedBox(height: 16),
              Text(
                'Error de Inicialización',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                "No se pudieron cargar los recursos o el servicio de fondo falló.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ListView(
              children: [
                const SizedBox(height: 20),
                _DurationSelector(state: state, service: service),
                const SizedBox(height: 20),
                _TimerControls(state: state, service: service),
                const SizedBox(height: 40),
                _SoundMixer(state: state, service: service),
                const SizedBox(height: 40),
                _HardcoreModeSwitch(state: state, service: service),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        if (!state.isPremium && state.canRequestAds)
          const SafeArea(
            top: false,
            child: AdBannerWidget(),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;
  const _DurationSelector({required this.state, required this.service});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final canAdjust = state.pomodoroStatus == PomodoroStatus.initial;
    final color = canAdjust ? Colors.white : Colors.white.withOpacity(0.4);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.remove_circle_outline, color: color),
          iconSize: 30,
          onPressed: !canAdjust ? null : () {
            final newDuration = state.pomodoroDuration - const Duration(minutes: 5);
            if (newDuration.inMinutes >= 5) {
              service.invoke('sendEvent', {
                'event': 'updatePomodoroDuration',
                'durationMinutes': newDuration.inMinutes,
              });
            }
          },
        ),
        Text(
          _formatDuration(state.remainingTime),
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: color),
          iconSize: 30,
          onPressed: !canAdjust ? null : () {
            final newDuration = state.pomodoroDuration + const Duration(minutes: 5);
             service.invoke('sendEvent', {
                'event': 'updatePomodoroDuration',
                'durationMinutes': newDuration.inMinutes,
              });
          },
        ),
      ],
    );
  }
}

class _TimerControls extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;
  const _TimerControls({required this.state, required this.service});

  @override
  Widget build(BuildContext context) {
    final status = state.pomodoroStatus;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay),
          iconSize: 30,
          onPressed: () => service.invoke('sendEvent', {'event': 'resetTimer'}),
        ),
        const SizedBox(width: 20),
        if (status == PomodoroStatus.running)
          IconButton.filled(
            iconSize: 48,
            icon: const Icon(Icons.pause),
            onPressed: () => service.invoke('sendEvent', {'event': 'pauseTimer'}),
          )
        else
          IconButton.filled(
            iconSize: 48,
            icon: const Icon(Icons.play_arrow),
            onPressed: () => service.invoke('sendEvent', {'event': 'startTimer'}),
          ),
        const SizedBox(width: 20),
        const SizedBox(width: 30),
      ],
    );
  }
}

class _HardcoreModeSwitch extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;
  const _HardcoreModeSwitch({required this.state, required this.service});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text( 'Modo Hardcore', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text( 'La sesión falla si levantas el móvil', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
              Switch(
                value: state.isHardcoreMode,
                onChanged: (_) {
                  service.invoke('sendEvent', {'event': 'toggleHardcore'});
                },
                activeColor: Colors.red,
              ),
            ],
          ),
          if (state.isHardcoreMode) ...[
            const SizedBox(height: 12),
            _buildHardcoreMessage(state),
          ]
        ],
      ),
    );
  }

  Widget _buildHardcoreMessage(FocusState state) {
    if (state.isInPenaltyBox) {
      return const Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Expanded(child: Text('¡Castigo! Pon el móvil boca abajo para continuar.', style: TextStyle(color: Colors.red))),
        ],
      );
    }
    
    if (state.pomodoroStatus == PomodoroStatus.running) {
       if (state.phoneOrientation == PhoneOrientation.faceDown) {
        return const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('¡Correcto! Sesión en curso.', style: TextStyle(color: Colors.green))),
          ],
        );
      } else {
        return const Row(
          children: [
            Icon(Icons.warning, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(child: Text('Mantén el móvil boca abajo.', style: TextStyle(color: Colors.amber))),
          ],
        );
      }
    } else { 
       return const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white70),
          SizedBox(width: 8),
          Expanded(child: Text('Para empezar, pon el móvil boca abajo y pulsa Play.', style: TextStyle(color: Colors.white70))),
        ],
      );
    }
  }
}

class _SoundMixer extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;
  const _SoundMixer({required this.state, required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sound Mixer', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _MixerSlider(
          label: 'Lluvia',
          icon: Icons.water_drop,
          value: state.rainVolume,
          onChanged: (value) {
            service.invoke('sendEvent', {'event': 'updateRainVolume', 'volume': value});
          },
        ),
        _MixerSlider(
          label: 'Fuego',
          icon: Icons.local_fire_department,
          value: state.fireVolume,
          onChanged: (value) {
             service.invoke('sendEvent', {'event': 'updateFireVolume', 'volume': value});
          },
        ),
        _MixerSlider(
          label: 'Ruido Marrón',
          icon: Icons.waves,
          value: state.brownNoiseVolume,
          onChanged: (value) {
            service.invoke('sendEvent', {'event': 'updateBrownNoiseVolume', 'volume': value});
          },
        ),
      ],
    );
  }
}

class _MixerSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;

  const _MixerSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8)),
        const SizedBox(width: 16),
        Expanded(
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: 0.0,
            max: 1.0,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text('${(value * 100).toInt()}%'),
        )
      ],
    );
  }
}
