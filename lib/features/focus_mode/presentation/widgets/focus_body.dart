import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../premium/presentation/widgets/ad_banner_widget.dart';
import '../bloc/focus_bloc.dart';
import 'timer_display.dart';
import 'timer_controls.dart';
import 'sound_mixer.dart';
import 'saved_mix_player.dart';
import 'hardcore_mode_card.dart';

class FocusBody extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;
  final GlobalKey timerKey;
  final GlobalKey controlsKey;
  final GlobalKey mixerKey;
  final GlobalKey savedMixesKey;
  final GlobalKey hardcoreKey;

  const FocusBody({
    super.key,
    required this.state,
    required this.service,
    required this.timerKey,
    required this.controlsKey,
    required this.mixerKey,
    required this.savedMixesKey,
    required this.hardcoreKey,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status == AppStatus.initial ||
        state.status == AppStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == AppStatus.error) {
      return const Center(child: Text("Error fatal de inicialización"));
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            children: [
              const SizedBox(height: 20),
              Showcase(
                key: timerKey,
                title: 'Temporizador',
                description: 'Tiempo restante.',
                child: TimerDisplay(state: state, service: service),
              ),
              const SizedBox(height: 30),
              Showcase(
                key: controlsKey,
                title: 'Controles',
                description: 'Inicia, pausa o reinicia.',
                child: TimerControls(state: state, service: service),
              ),
              const SizedBox(height: 24),
              Showcase(
                key: hardcoreKey,
                title: 'Modo Focus',
                description:
                    'Activa este modo para evitar distracciones. Si giras el móvil, el tiempo se detiene.',
                child: HardcoreModeCard(state: state, service: service),
              ),
              const SizedBox(height: 40),
              Showcase(
                key: mixerKey,
                title: 'Sonidos',
                description: 'Ajusta tu ambiente.',
                child: SoundMixer(state: state, service: service),
              ),
              const SizedBox(height: 40),
              Showcase(
                key: savedMixesKey,
                title: 'Mezclas',
                description: 'Tus favoritas.',
                child: SavedMixPlayer(state: state, service: service),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        if (!state.isPremium && state.canRequestAds)
          const SafeArea(top: false, child: AdBannerWidget())
        else
          const SizedBox.shrink(),
      ],
    );
  }
}
