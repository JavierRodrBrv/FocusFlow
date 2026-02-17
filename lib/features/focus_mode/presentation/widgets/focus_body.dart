import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../../../premium/presentation/widgets/ad_banner_widget.dart';
import '../bloc/focus_bloc.dart';
import 'timer_display.dart';
import 'timer_controls.dart';

class FocusBody extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;
  final GlobalKey timerKey;
  final GlobalKey controlsKey;

  const FocusBody({
    super.key,
    required this.state,
    required this.service,
    required this.timerKey,
    required this.controlsKey,
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TimerDisplay(
                    key: timerKey,
                    state: state,
                    service: service,
                  ),
                  const SizedBox(height: 48),
                  TimerControls(
                    key: controlsKey,
                    state: state,
                    service: service,
                  ),
                ],
              ),
            ),
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
