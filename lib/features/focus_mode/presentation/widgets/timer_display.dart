import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/bouncing_button.dart';

import '../bloc/focus_bloc.dart';

class TimerDisplay extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const TimerDisplay({super.key, required this.state, required this.service});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _showTimerPicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemBackground.resolveFrom(
                  context,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancelar'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Listo'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hms,
                initialTimerDuration: state.pomodoroDuration,
                onTimerDurationChanged: (Duration newDuration) {
                  if (newDuration.inSeconds >= 10) {
                    service.invoke('sendEvent', {
                      'event': 'updatePomodoroDuration',
                      'durationMinutes': newDuration.inMinutes,
                      'durationSeconds': newDuration.inSeconds % 60,
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isResting = state.isResting;
    final canAdjust = state.pomodoroStatus == PomodoroStatus.initial;
    final isAtMin = state.pomodoroDuration.inMinutes <= 5;
    final color = isResting
        ? Colors.redAccent
        : (canAdjust ? Colors.white : Colors.white.withValues(alpha: 0.4));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left Controls (Decrement)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // -10 Min
            BouncingButton(
              onPressed: (!canAdjust || isAtMin)
                  ? null
                  : () =>
                        _updateDuration(state.pomodoroDuration.inMinutes - 10),
              child: Icon(
                Icons.remove_circle_outline,
                color: (canAdjust && !isAtMin)
                    ? color
                    : color.withValues(alpha: 0.2),
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            // -5 Min
            BouncingButton(
              onPressed: (!canAdjust || isAtMin)
                  ? null
                  : () => _updateDuration(state.pomodoroDuration.inMinutes - 5),
              child: Icon(
                Icons.remove,
                color: (canAdjust && !isAtMin)
                    ? color.withValues(alpha: 0.7)
                    : color.withValues(alpha: 0.2),
                size: 24,
              ),
            ),
          ],
        ),

        // Time Display
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: BouncingButton(
              onPressed: canAdjust ? () => _showTimerPicker(context) : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatDuration(state.remainingTime),
                  style: TextStyle(
                    fontSize: state.remainingTime.inHours > 0 ? 52 : 64,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Right Controls (Increment)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // +10 Min
            BouncingButton(
              onPressed: !canAdjust
                  ? null
                  : () =>
                        _updateDuration(state.pomodoroDuration.inMinutes + 10),
              child: Icon(
                Icons.add_circle_outline,
                color: canAdjust ? color : color.withValues(alpha: 0.2),
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            // +5 Min
            BouncingButton(
              onPressed: !canAdjust
                  ? null
                  : () => _updateDuration(state.pomodoroDuration.inMinutes + 5),
              child: Icon(
                Icons.add,
                color: canAdjust
                    ? color.withValues(alpha: 0.7)
                    : color.withValues(alpha: 0.2),
                size: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateDuration(int newMinutes) {
    // Lógica centralizada de límites (Mínimo 5 minutos)
    final targetMinutes = newMinutes < 5 ? 5 : newMinutes;
    service.invoke('sendEvent', {
      'event': 'updatePomodoroDuration',
      'durationMinutes': targetMinutes,
    });
  }
}
