import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/components/bouncing_button.dart';
import '../../bloc/focus_bloc.dart';

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
    final color = isResting
        ? Colors.redAccent
        : (canAdjust ? Colors.white : Colors.white.withValues(alpha: 0.4));

    return Center(
      child: BouncingButton(
        onPressed: canAdjust ? () => _showTimerPicker(context) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (canAdjust)
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                    ),
                  ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatDuration(state.remainingTime),
                    style: TextStyle(
                      fontSize: state.remainingTime.inHours > 0 ? 64 : 82,
                      fontWeight: FontWeight.w200,
                      color: color,
                      letterSpacing: -2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            if (canAdjust)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  "TOCA PARA AJUSTAR",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
              ),
          ],
        ),
      ),
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
