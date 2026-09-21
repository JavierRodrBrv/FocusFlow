import 'package:flutter/material.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';
import 'package:focus_flow/shared/theme/app_text_styles.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/premium/presentation/widgets/premium_feature_dialog.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
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

    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tab Selector
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Row(
            children: [
              _buildTabButton(l10n.mixerTab, 0),
              const SizedBox(width: 8),
              _buildTabButton(l10n.backgroundSoundTab, 1),
            ],
          ),
        ),

        // Contenido con altura fija para evitar saltos del modal, igualando al mezclador original
        SizedBox(
          height: 210,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _selectedTabIndex == 0
                ? Column(
                    key: const ValueKey('mixer_tab'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MixerSlider(
                        label: l10n.rainLabel,
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
                        label: l10n.fireLabel,
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
                        label: l10n.wavesLabel,
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
                            color: AppColors.textSecondary,
                            onPressed: () {
                              if (state.isPremium) {
                                SavedMixesBottomSheet.show(
                                    context, state, service);
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      PremiumFeatureDialog(
                                    featureName: l10n.premiumLoadMixTitle,
                                    featureDescription: l10n.premiumLoadMixDesc,
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
                                    : AppColors.textPrimary.withValues(alpha: 0.1),
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
                                color: AppColors.textPrimary,
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
                                    SnackBar(
                                      content: Text(l10n.mixSaved),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      PremiumFeatureDialog(
                                    featureName: l10n.saveSoundMixes,
                                    featureDescription: l10n.saveSoundMixesDesc,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    key: const ValueKey('ambience_tab'),
                    physics: const BouncingScrollPhysics(),
                    child: AmbienceList(
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
                  : AppColors.textPrimary.withValues(alpha: 0.05),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: isSelected ? Colors.blueAccent : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
