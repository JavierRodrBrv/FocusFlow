import 'package:flutter/material.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/background_effect.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/components/gradient_flow_background.dart';

import '../../models/focus_state.dart';

class TimerShaderBackground extends StatelessWidget {
  final FocusState state;

  const TimerShaderBackground({super.key, required this.state});

  bool get _shouldShowEffect {
    final status = state.pomodoroStatus;
    // Efecto activo si la sesión ha comenzado Y la preferencia es Gradient.
    return status != PomodoroStatus.initial &&
        state.backgroundEffect == BackgroundEffect.gradient;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(seconds: 2),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _shouldShowEffect
          ? const GradientFlowBackground(
              key: ValueKey('shader_active'),
              child: SizedBox.expand(),
            )
          : Container(
              key: const ValueKey('shader_inactive'),
              color: const Color(0xFF0F172A),
              child: const SizedBox.expand(),
            ),
    );
  }
}
