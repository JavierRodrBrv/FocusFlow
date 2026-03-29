import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/premium/presentation/widgets/ad_banner_widget.dart';
import '../../../models/focus_state.dart';
import '../../modals/settings_menu_bottom_sheet.dart';
import '../timer/timer_display.dart';
import '../timer/timer_controls.dart';

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
                  // Nuevo: Burbuja de Descansos
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: (state.defaultBreakDuration != null &&
                            state.pomodoroStatus == PomodoroStatus.initial &&
                            showUI)
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => SettingsMenuBottomSheet(
                                    initialState: state,
                                    initialView: 3,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.coffee,
                                      size: 16,
                                      color: Colors.orangeAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${state.defaultBreakDuration!.inMinutes} min descanso',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
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
