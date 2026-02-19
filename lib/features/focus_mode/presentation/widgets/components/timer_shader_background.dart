import 'package:flutter/material.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/focus_bloc.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/components/gradient_flow_background.dart';

class TimerShaderBackground extends StatelessWidget {
  final FocusState state;

  const TimerShaderBackground({super.key, required this.state});

  bool get _shouldShowEffect {
    final status = state.pomodoroStatus;
    // Keep the effect active as long as the session has started (not in initial state).
    // This includes running, paused, resting, and finished.
    return status != PomodoroStatus.initial;
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
