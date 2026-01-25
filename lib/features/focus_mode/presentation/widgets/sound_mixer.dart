import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../bloc/focus_bloc.dart';

class SoundMixer extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const SoundMixer({
    super.key,
    required this.state,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.equalizer, size: 20, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              'Mezclador de Sonido',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
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
        Tooltip(message: label, child: Icon(icon, color: Colors.white.withOpacity(0.8))),
        const SizedBox(width: 16),
        Expanded(
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: 0.0,
            max: 1.0,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.white10,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${(value * 100).toInt()}%',
            style: const TextStyle(fontSize: 12, color: Colors.white60),
            textAlign: TextAlign.end,
          ),
        )
      ],
    );
  }
}
