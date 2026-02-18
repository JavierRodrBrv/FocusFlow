import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/focus_bloc.dart';

class TimerShaderBackground extends StatefulWidget {
  final FocusState state;

  const TimerShaderBackground({super.key, required this.state});

  @override
  State<TimerShaderBackground> createState() => _TimerShaderBackgroundState();
}

class _TimerShaderBackgroundState extends State<TimerShaderBackground>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    // We use a Ticker to get absolute time since the widget started.
    // This avoids the jump that occurs when an AnimationController repeats.
    _ticker = createTicker((elapsed) {
      setState(() {
        _elapsedSeconds = elapsed.inMicroseconds / 1000000.0;
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool get _shouldShowEffect {
    final status = widget.state.pomodoroStatus;
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
          ? ShaderBuilder(
              (context, shader, child) {
                return CustomPaint(
                  painter: _FlowPainter(
                    shader: shader,
                    time: _elapsedSeconds,
                  ),
                  child: const SizedBox.expand(),
                );
              },
              assetKey: 'shaders/gradient_flow.frag',
            )
          : const SizedBox.expand(),
    );
  }
}

class _FlowPainter extends CustomPainter {
  final FragmentShader shader;
  final double time;

  _FlowPainter({required this.shader, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, time);
    shader.setFloat(1, size.width);
    shader.setFloat(2, size.height);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_FlowPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.shader != shader;
}
