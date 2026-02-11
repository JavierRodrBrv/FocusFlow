import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/premium/presentation/widgets/premium_feature_dialog.dart';

import '../bloc/focus_bloc.dart';

class SoundMixer extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const SoundMixer({super.key, required this.state, required this.service});

  void _showSavedMixes(BuildContext context) {
    if (state.savedMixes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes mezclas guardadas aún.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mezclas Guardadas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.savedMixes.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final mix = state.savedMixes[index];
                    final isSelected = mix.id == state.lastActivatedMixId;
                    final isHistory =
                        mix.id == state.persistedLastMixId && !isSelected;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.greenAccent.withValues(alpha: 0.2)
                              : isHistory
                              ? Colors.grey.withValues(alpha: 0.2)
                              : Colors.blueAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check
                              : isHistory
                              ? Icons.history
                              : Icons.music_note,
                          color: isSelected
                              ? Colors.greenAccent
                              : isHistory
                              ? Colors.white70
                              : Colors.blueAccent,
                        ),
                      ),
                      title: Text(
                        mix.name,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.greenAccent
                              : isHistory
                              ? Colors.white70
                              : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Lluvia: ${(mix.rainVolume * 100).toInt()}% • Fuego: ${(mix.fireVolume * 100).toInt()}% • Olas: ${(mix.brownNoiseVolume * 100).toInt()}%${isHistory ? " (Última)" : ""}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        service.invoke('sendEvent', {
                          'event': 'loadMix',
                          'mixId': mix.id,
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Cargando "${mix.name}"...')),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
            Row(
              children: [
                IconButton(
                  tooltip: state.isPremium
                      ? 'Cargar Mix'
                      : 'Cargar Mix (Premium)',
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.queue_music,
                        color: state.isPremium
                            ? Colors.white70
                            : Colors.white38,
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
                      _showSavedMixes(context);
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => const PremiumFeatureDialog(
                          featureName: 'Cargar Mezclas',
                          featureDescription:
                              'Accede a tus mezclas de sonido guardadas y cambia de ambiente al instante.',
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  tooltip: state.isPremium
                      ? 'Guardar Mix'
                      : 'Guardar Mix (Premium)',
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.save_alt,
                        color: state.isPremium
                            ? Colors.blueAccent
                            : Colors.white38,
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
          ],
        ),
        const SizedBox(height: 16),
        _MixerSlider(
          label: 'Lluvia',
          icon: Icons.water_drop,
          value: state.rainVolume,
          onChanged: (value) {
            service.invoke('sendEvent', {
              'event': 'updateRainVolume',
              'volume': value,
            });
          },
        ),
        _MixerSlider(
          label: 'Fuego',
          icon: Icons.local_fire_department,
          value: state.fireVolume,
          onChanged: (value) {
            service.invoke('sendEvent', {
              'event': 'updateFireVolume',
              'volume': value,
            });
          },
        ),
        _MixerSlider(
          label: 'Ruido Marrón',
          icon: Icons.waves,
          value: state.brownNoiseVolume,
          onChanged: (value) {
            service.invoke('sendEvent', {
              'event': 'updateBrownNoiseVolume',
              'volume': value,
            });
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
  DateTime _lastUpdateTime = DateTime.now();
  DateTime _lastInteractionTime = DateTime.now().subtract(
    const Duration(seconds: 1),
  );

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant _MixerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    // PERIODO DE GRACIA:
    // Si el usuario acaba de interactuar (hace menos de 500ms), ignoramos
    // lo que diga el servicio, porque probablemente sea información antigua (lag).
    final timeSinceInteraction = DateTime.now().difference(
      _lastInteractionTime,
    );
    final isUserInteracting =
        _isDragging || timeSinceInteraction.inMilliseconds < 500;

    // Si el valor entrante es 0.0, es una orden de pausa (manual o auto),
    // así que forzamos la actualización visual ignorando el periodo de gracia.
    final isExplicitZero = widget.value == 0.0;

    if ((!isUserInteracting || isExplicitZero) &&
        widget.value != _currentValue) {
      setState(() {
        _currentValue = widget.value;
      });
    }
  }

  void _handleChanged(double val) {
    setState(() {
      _currentValue = val;
      _lastInteractionTime = DateTime.now(); // Marcamos interacción
    });

    // Throttling ligero para no saturar el canal de comunicación
    final now = DateTime.now();
    if (now.difference(_lastUpdateTime) > const Duration(milliseconds: 16)) {
      widget.onChanged(val);
      _lastUpdateTime = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: widget.label,
          child: Icon(widget.icon, color: Colors.white.withValues(alpha: 0.8)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: _currentValue, end: _currentValue),
            duration: _isDragging
                ? Duration.zero
                : const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return Slider(
                value: animatedValue,
                min: 0.0,
                max: 1.0,
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.white10,
                onChangeStart: (_) {
                  setState(() => _isDragging = true);
                },
                onChangeEnd: (val) {
                  setState(() {
                    _isDragging = false;
                    _lastInteractionTime = DateTime.now();
                  });
                  widget.onChanged(val);
                },
                onChanged: _handleChanged,
              );
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
        ),
      ],
    );
  }
}
