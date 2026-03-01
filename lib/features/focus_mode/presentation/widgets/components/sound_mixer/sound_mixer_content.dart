import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/premium/presentation/widgets/premium_feature_dialog.dart';
import '../../../models/focus_state.dart';
import '../shared/bouncing_button.dart';
import '../../modals/saved_mixes_bottom_sheet.dart';
import 'ambience_list.dart';
import 'circular_action_button.dart';
import 'mixer_slider.dart';

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
  int _selectedTabIndex = 0; // 0: Mezclador, 1: Sonido de Fondo

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

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.state.isPlayingMix;
    final state = widget.state;
    final service = widget.service;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tab Selector
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Row(
            children: [
              _buildTabButton('Mezclador', 0),
              const SizedBox(width: 8),
              _buildTabButton('Sonido de fondo', 1),
            ],
          ),
        ),

        // Contenido con altura fija para evitar saltos del modal
        SizedBox(
          height: 340,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _selectedTabIndex == 0
                  ? Column(
                      key: const ValueKey('mixer_tab'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MixerSlider(
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
                        MixerSlider(
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
                        MixerSlider(
                          label: 'Olas',
                          icon: Icons.waves,
                          value: state.brownNoiseVolume,
                          onChanged: (value) {
                            service.invoke('sendEvent', {
                              'event': 'updateBrownNoiseVolume',
                              'volume': value,
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularActionButton(
                              icon: Icons.queue_music,
                              isPremium: state.isPremium,
                              color: Colors.white70,
                              onPressed: () {
                                if (state.isPremium) {
                                  SavedMixesBottomSheet.show(
                                      context, state, service);
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const PremiumFeatureDialog(
                                      featureName: 'Cargar mezclas guardadas',
                                      featureDescription:
                                          'Accede y carga al instante tus mezclas de sonido personalizadas que has guardado previamente.',
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 24),
                            BouncingButton(
                              onPressed: () {
                                service.invoke('sendEvent', {
                                  'event': isPlaying ? 'pauseMix' : 'resumeMix',
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isPlaying
                                      ? Colors.blueAccent
                                      : Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  boxShadow: isPlaying
                                      ? [
                                          BoxShadow(
                                            color: Colors.blueAccent
                                                .withValues(alpha: 0.4),
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
                            CircularActionButton(
                              icon: Icons.save_alt,
                              isPremium: state.isPremium,
                              color: Colors.blueAccent,
                              onPressed: () {
                                if (state.isPremium) {
                                  service
                                      .invoke('sendEvent', {'event': 'saveMix'});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Mix guardado.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const PremiumFeatureDialog(
                                      featureName: 'Guardar mezclas de sonido',
                                      featureDescription:
                                          'Guarda tus configuraciones de sonido ambientale para usarlas más tarde.',
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    )
                  : AmbienceList(
                      key: const ValueKey('ambience_tab'),
                      state: state,
                      service: service,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blueAccent.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Colors.blueAccent.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.white38,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
