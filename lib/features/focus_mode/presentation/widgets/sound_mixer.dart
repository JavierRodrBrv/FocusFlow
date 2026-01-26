import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/premium/presentation/widgets/premium_feature_dialog.dart';

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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            IconButton(
              tooltip: state.isPremium ? 'Guardar Mix' : 'Guardar Mix (Premium)',
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.save_alt,
                    color: state.isPremium ? Colors.blueAccent : Colors.white38,
                  ),
                  if (!state.isPremium)
                    const Positioned(
                      right: -4,
                      bottom: -4,
                      child: Icon(
                        Icons.lock,
                        size: 14,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
              onPressed: () {
                if (state.isPremium) {
                  service.invoke('sendEvent', {'event': 'saveMix'});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mix guardado correctamente.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => const PremiumFeatureDialog(
                      featureName: 'Guardar Mezclas',
                      featureDescription:
                          'Guarda tus configuraciones de sonido favoritas para acceder a ellas rápidamente en cualquier momento.',
                    ),
                  );
                }
              },
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

class _MixerSlider extends StatefulWidget {
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
  State<_MixerSlider> createState() => _MixerSliderState();
}

class _MixerSliderState extends State<_MixerSlider> {
  late double _currentValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant _MixerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo actualizamos desde el padre si el usuario NO está arrastrando.
    // Esto evita saltos ("jitter") si el stream tiene lag.
    if (!_isDragging && widget.value != _currentValue) {
      setState(() {
        _currentValue = widget.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
            message: widget.label,
            child: Icon(widget.icon, color: Colors.white.withOpacity(0.8))),
        const SizedBox(width: 16),
        Expanded(
          child: Slider(
            value: _currentValue,
            min: 0.0,
            max: 1.0,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.white10,
            onChangeStart: (_) => _isDragging = true,
            onChangeEnd: (_) => _isDragging = false,
            onChanged: (val) {
              setState(() => _currentValue = val);
              widget.onChanged(val);
            },
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${(_currentValue * 100).toInt()}%',
            style: const TextStyle(fontSize: 12, color: Colors.white60),
            textAlign: TextAlign.end,
          ),
        )
      ],
    );
  }
}
