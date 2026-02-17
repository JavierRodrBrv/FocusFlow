import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/premium/presentation/widgets/premium_feature_dialog.dart';
import '../bloc/focus_bloc.dart';
import 'bouncing_button.dart';

class SoundMixerContent extends StatefulWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const SoundMixerContent({
    super.key,
    required this.state,
    required this.service,
  });

  @override
  State<SoundMixerContent> createState() => _SoundMixerContentState();
}

class _SoundMixerContentState extends State<SoundMixerContent>
    with TickerProviderStateMixin {
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (widget.state.isPlayingMix) {
      _iconController.forward();
    }
  }

  @override
  void didUpdateWidget(SoundMixerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  void _showSavedMixes(BuildContext context) {
    if (widget.state.savedMixes.isEmpty) {
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
                  itemCount: widget.state.savedMixes.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final mix = widget.state.savedMixes[index];
                    final isSelected =
                        mix.id == widget.state.lastActivatedMixId;
                    final isHistory =
                        mix.id == widget.state.persistedLastMixId &&
                        !isSelected;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.greenAccent.withOpacity(0.2)
                              : isHistory
                              ? Colors.grey.withOpacity(0.2)
                              : Colors.blueAccent.withOpacity(0.2),
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
                        widget.service.invoke('sendEvent', {
                          'event': 'loadMix',
                          'mixId': mix.id,
                        });
                        Navigator.pop(context);
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
    final isPlaying = widget.state.isPlayingMix;

    return Column(
      children: [
        _MixerSlider(
          label: 'Lluvia',
          icon: Icons.water_drop,
          value: widget.state.rainVolume,
          onChanged: (value) {
            widget.service.invoke('sendEvent', {
              'event': 'updateRainVolume',
              'volume': value,
            });
          },
        ),
        _MixerSlider(
          label: 'Fuego',
          icon: Icons.local_fire_department,
          value: widget.state.fireVolume,
          onChanged: (value) {
            widget.service.invoke('sendEvent', {
              'event': 'updateFireVolume',
              'volume': value,
            });
          },
        ),
        _MixerSlider(
          label: 'Olas',
          icon: Icons.waves,
          value: widget.state.brownNoiseVolume,
          onChanged: (value) {
            widget.service.invoke('sendEvent', {
              'event': 'updateBrownNoiseVolume',
              'volume': value,
            });
          },
        ),
        const SizedBox(height: 24),

        // CONTROLS ROW
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOAD MIX BUTTON
            BouncingButton(
              onPressed: () {
                if (widget.state.isPremium) {
                  _showSavedMixes(context);
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => const PremiumFeatureDialog(
                      featureName: 'Cargar mezclas guardadas',
                      featureDescription:
                          'Accede y carga al instante tus mezclas de sonido personalizadas que has guardado previamente.',
                    ),
                  );
                }
              },
              child: _CircularActionButton(
                icon: Icons.queue_music,
                isPremium: widget.state.isPremium,
                color: Colors.white70,
              ),
            ),

            const SizedBox(width: 24),

            // PLAY/PAUSE BUTTON
            BouncingButton(
              onPressed: () {
                widget.service.invoke('sendEvent', {
                  'event': isPlaying ? 'pauseMix' : 'resumeMix',
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isPlaying
                      ? Colors.blueAccent
                      : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: isPlaying
                      ? [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: AnimatedIcon(
                  icon: AnimatedIcons.play_pause,
                  progress: _iconController,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

            const SizedBox(width: 24),

            // SAVE MIX BUTTON
            BouncingButton(
              onPressed: () {
                if (widget.state.isPremium) {
                  widget.service.invoke('sendEvent', {'event': 'saveMix'});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mix guardado.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => const PremiumFeatureDialog(
                      featureName: 'Guardar mezclas de sonido',
                      featureDescription:
                          'Guarda tus configuraciones de sonido ambientale para usarlas más tarde.',
                    ),
                  );
                }
              },
              child: _CircularActionButton(
                icon: Icons.save_alt,
                isPremium: widget.state.isPremium,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CircularActionButton extends StatelessWidget {
  final IconData icon;
  final bool isPremium;
  final Color color;

  const _CircularActionButton({
    required this.icon,
    required this.isPremium,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: isPremium ? color : Colors.white24, size: 24),
          if (!isPremium)
            const Positioned(
              right: -4,
              bottom: -4,
              child: Icon(Icons.lock, size: 14, color: Colors.amber),
            ),
        ],
      ),
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
    final timeSinceInteraction = DateTime.now().difference(
      _lastInteractionTime,
    );
    final isUserInteracting =
        _isDragging || timeSinceInteraction.inMilliseconds < 500;
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
      _lastInteractionTime = DateTime.now();
    });
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
        Icon(widget.icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: TweenAnimationBuilder<double>(
              duration: _isDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              tween: Tween<double>(begin: _currentValue, end: _currentValue),
              builder: (context, animatedValue, child) {
                return Slider(
                  value: animatedValue,
                  min: 0.0,
                  max: 1.0,
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.white10,
                  onChangeStart: (_) => setState(() => _isDragging = true),
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
        ),
        TweenAnimationBuilder<double>(
          duration: _isDragging
              ? Duration.zero
              : const Duration(milliseconds: 300),
          tween: Tween<double>(begin: _currentValue, end: _currentValue),
          builder: (context, animatedValue, child) {
            return SizedBox(
              width: 35,
              child: Text(
                '${(animatedValue * 100).toInt()}%',
                style: const TextStyle(fontSize: 10, color: Colors.white38),
                textAlign: TextAlign.end,
              ),
            );
          },
        ),
      ],
    );
  }
}

//
// class _MixerSlider extends StatefulWidget {
//   final String label;
//   final IconData icon;
//   final double value;
//   final ValueChanged<double> onChanged;
//
//   const _MixerSlider({
//     required this.label,
//     required this.icon,
//     required this.value,
//     required this.onChanged,
//   });
//
//   @override
//   State<_MixerSlider> createState() => _MixerSliderState();
// }
//
//
// class _MixerSliderState extends State<_MixerSlider> {
//   late double _currentValue;
//   bool _isDragging = false;
//   DateTime _lastUpdateTime = DateTime.now();
//   DateTime _lastInteractionTime = DateTime.now().subtract(
//     const Duration(seconds: 1),
//   );
//
//   @override
//   void initState() {
//     super.initState();
//     _currentValue = widget.value;
//   }
//
//   @override
//   void didUpdateWidget(covariant _MixerSlider oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     final timeSinceInteraction = DateTime.now().difference(
//       _lastInteractionTime,
//     );
//     final isUserInteracting =
//         _isDragging || timeSinceInteraction.inMilliseconds < 500;
//     final isExplicitZero = widget.value == 0.0;
//
//     if ((!isUserInteracting || isExplicitZero) &&
//         widget.value != _currentValue) {
//       setState(() {
//         _currentValue = widget.value;
//       });
//     }
//   }
//
//   void _handleChanged(double val) {
//     setState(() {
//       _currentValue = val;
//       _lastInteractionTime = DateTime.now();
//     });
//     final now = DateTime.now();
//     if (now.difference(_lastUpdateTime) > const Duration(milliseconds: 16)) {
//       widget.onChanged(val);
//       _lastUpdateTime = now;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Icon(widget.icon, color: Colors.white70, size: 20),
//         const SizedBox(width: 12),
//         Expanded(
//           child: SliderTheme(
//             data: SliderTheme.of(context).copyWith(
//               trackHeight: 4,
//               thumbShape: const RoundSliderThumbShape(
//                 enabledThumbRadius: 6,
//               ),
//               overlayShape: const RoundSliderOverlayShape(
//                 overlayRadius: 14,
//               ),
//             ),
//             child: Slider(
//               value: _currentValue,
//               min: 0.0,
//               max: 1.0,
//               activeColor: Colors.blueAccent,
//               inactiveColor: Colors.white10,
//               onChangeStart: (_) => setState(() => _isDragging = true),
//               onChangeEnd: (val) {
//                 setState(() {
//                   _isDragging = false;
//                   _lastInteractionTime = DateTime.now();
//                 });
//                 widget.onChanged(val);
//               },
//               onChanged: _handleChanged,
//             ),
//           ),
//         ),
//         SizedBox(
//           width: 35,
//           child: Text(
//             '${(_currentValue * 100).toInt()}%',
//             style: const TextStyle(fontSize: 10, color: Colors.white38),
//             textAlign: TextAlign.end,
//           ),
//         ),
//       ],
//     );
//   }
// }
