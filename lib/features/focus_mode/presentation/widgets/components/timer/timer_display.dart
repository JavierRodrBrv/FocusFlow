import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/components/shared/bouncing_button.dart';
import '../../../models/focus_state.dart';

class TimerDisplay extends StatefulWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const TimerDisplay({super.key, required this.state, required this.service});

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOutSine),
    );

    _updateAnimationState();
  }

  @override
  void didUpdateWidget(covariant TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimationState();
  }

  void _updateAnimationState() {
    final status = widget.state.pomodoroStatus;
    final isActive = status == PomodoroStatus.running || status == PomodoroStatus.resting;

    if (isActive) {
      if (!_breathingController.isAnimating) {
        _breathingController.repeat(reverse: true);
      }
    } else {
      if (_breathingController.isAnimating) {
        _breathingController.animateTo(0.0, duration: const Duration(milliseconds: 300));
      }
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

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
                    child: Text(AppLocalizations.of(context)!.cancel),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: Text(AppLocalizations.of(context)!.ready),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hms,
                initialTimerDuration: widget.state.pomodoroDuration,
                onTimerDurationChanged: (Duration newDuration) {
                  if (newDuration.inSeconds >= 10) {
                    widget.service.invoke('sendEvent', {
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
    final state = widget.state;
    final isResting = state.isResting;
    final canAdjust = state.pomodoroStatus == PomodoroStatus.initial;

    // Calcular el progreso del anillo (de 1.0 a 0.0)
    final double progress = state.pomodoroDuration.inSeconds > 0
        ? state.remainingTime.inSeconds / state.pomodoroDuration.inSeconds
        : 0.0;

    final color = isResting
        ? Colors.redAccent
        : (canAdjust ? Colors.white : Colors.white.withValues(alpha: 0.4));

    return Center(
      child: BouncingButton(
        onPressed: canAdjust ? () => _showTimerPicker(context) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _breathingController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Anillo de progreso dinámico
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 1.5,
                          backgroundColor: color.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            color.withValues(
                              alpha: canAdjust ? 0.15 : _glowAnimation.value,
                            ),
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
                );
              },
            ),
            if (canAdjust)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  AppLocalizations.of(context)!.tapToAdjust,
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
}
