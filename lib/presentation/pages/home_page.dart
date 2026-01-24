
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/presentation/bloc/focus_bloc.dart';
import 'package:focus_flow/presentation/widgets/ad_banner_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    print('[HomePage] build called.');
    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusFlow'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Debug button to simulate premium
          TextButton.icon(
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('Simulate Premium'),
            onPressed: () {
              context.read<FocusBloc>().add(TogglePremiumStatus());
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.7),
            ),
          )
        ],
      ),
      body: BlocBuilder<FocusBloc, FocusState>(
        builder: (context, state) {
          print('[HomePage] BlocBuilder rebuilding with status: ${state.status}');
          // Show loading indicator for both initial and loading states
          if (state.status == AppStatus.initial || state.status == AppStatus.loading) {
            print('[HomePage] Building Loading UI');
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AppStatus.error) {
            print('[HomePage] Building Error UI');
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
                      "No se pudieron cargar los recursos de audio. Asegúrate de que los archivos 'rain.mp3', 'fire.mp3' y 'brown.mp3' existan en la carpeta 'assets/audio'.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            );
          }
          print('[HomePage] Building Loaded UI. isPremium: ${state.isPremium}, canRequestAds: ${state.canRequestAds}');
          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // TODO: Implement Pomodoro Timer UI
                      const Text(
                        '25:00',
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 60),
                      _SoundMixer(),
                    ],
                  ),
                ),
              ),
              // Conditional Ad Banner based on premium and consent status
              if (!state.isPremium && state.canRequestAds)
                Container(
                  color: Colors.red.withOpacity(0.2), // Debug container
                  child: const SafeArea(
                    top: false,
                    child: AdBannerWidget(),
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }
}

class _SoundMixer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FocusBloc, FocusState>(
      builder: (context, state) {
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
                context.read<FocusBloc>().add(UpdateRainVolume(value));
              },
            ),
            _MixerSlider(
              label: 'Fuego',
              icon: Icons.local_fire_department,
              value: state.fireVolume,
              onChanged: (value) {
                context.read<FocusBloc>().add(UpdateFireVolume(value));
              },
            ),
            _MixerSlider(
              label: 'Ruido Marrón',
              icon: Icons.waves,
              value: state.brownNoiseVolume,
              onChanged: (value) {
                context.read<FocusBloc>().add(UpdateBrownNoiseVolume(value));
              },
            ),
          ],
        );
      },
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
