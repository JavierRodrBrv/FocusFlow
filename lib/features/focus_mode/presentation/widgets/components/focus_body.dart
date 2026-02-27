import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:focus_flow/features/premium/presentation/widgets/ad_banner_widget.dart';
import '../../bloc/focus_bloc.dart';
import 'timer_display.dart';
import 'timer_controls.dart';

class FocusBody extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;
  final GlobalKey timerKey;
  final GlobalKey controlsKey;
  final bool overlayVisible;

  const FocusBody({
    super.key,
    required this.state,
    required this.service,
    required this.timerKey,
    required this.controlsKey,
    this.overlayVisible = true,
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

    final isZoomMode = state.isZoomMode;
    final showUI = !isZoomMode || (isZoomMode && overlayVisible);
    // El anuncio se muestra si showUI es true (modo normal o toque)
    // O si estamos en modo zoom (según el nuevo requisito: "muestra el anuncio siempre")
    final showAd =
        (!state.isPremium && state.canRequestAds) && (isZoomMode || showUI);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              physics: isZoomMode ? const NeverScrollableScrollPhysics() : null,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 500),
                    scale: isZoomMode ? 1.4 : 1.0,
                    curve: Curves.easeInOut,
                    child: Showcase(
                      key: timerKey,
                      title: 'Temporizador',
                      description:
                          'Ajusta tu tiempo de enfoque. Pulsa el centro para usar el selector preciso de tiempo.',
                      child: TimerDisplay(state: state, service: service),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: SizedBox(height: isZoomMode ? 120 : 48),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: showUI ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !showUI,
                      child: Showcase(
                        key: controlsKey,
                        title: 'Controles de Sesión',
                        description:
                            'Inicia, pausa o reinicia tu sesión. Usa el botón de Modo Inmersivo (derecha) para ocultar distracciones.',
                        child: TimerControls(state: state, service: service),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: showAd ? 1.0 : 0.0,
          child: showAd
              ? const SafeArea(top: false, child: AdBannerWidget())
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
