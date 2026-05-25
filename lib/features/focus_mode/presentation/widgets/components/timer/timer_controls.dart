import 'package:flutter/material.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/components/shared/bouncing_button.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/dialogs/reset_confirmation_dialog.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/dialogs/session_completion_dialog.dart';

import '../../../models/focus_state.dart';

class TimerControls extends StatefulWidget {
  final FocusState state;
  final FlutterBackgroundService service;
  final GlobalKey? zoomKey;

  const TimerControls({
    super.key,
    required this.state,
    required this.service,
    this.zoomKey,
  });

  @override
  State<TimerControls> createState() => _TimerControlsState();
}

class _TimerControlsState extends State<TimerControls>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _glowAnimation = Tween<double>(begin: 15.0, end: 32.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant TimerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimations();
  }

  void _syncAnimations() {
    final status = widget.state.pomodoroStatus;
    final isActive = status == PomodoroStatus.running || status == PomodoroStatus.resting;

    if (isActive) {
      _iconController.forward();
      if (!_glowController.isAnimating) {
        _glowController.repeat(reverse: true);
      }
    } else {
      _iconController.reverse();
      if (_glowController.isAnimating) {
        _glowController.animateTo(0.0, duration: const Duration(milliseconds: 300));
      }
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _showBreakSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          AppLocalizations.of(context)!.addBreakTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          AppLocalizations.of(context)!.addBreakMessage,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.service.invoke('sendEvent', {
                'event': 'setBreakDuration',
                'durationMinutes': null,
              });
              widget.service.invoke('sendEvent', {'event': 'startTimer'});
              Navigator.pop(context);
            },
            child: Text(
              AppLocalizations.of(context)!.noThanks,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              widget.service.invoke('sendEvent', {
                'event': 'setBreakDuration',
                'durationMinutes': 5,
              });
              widget.service.invoke('sendEvent', {'event': 'startTimer'});
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.minOnly(5), style: const TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              widget.service.invoke('sendEvent', {
                'event': 'setBreakDuration',
                'durationMinutes': 10,
              });
              widget.service.invoke('sendEvent', {'event': 'startTimer'});
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.minOnly(10), style: const TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, VoidCallback onConfirm) {
    if (widget.state.hasBreak ||
        widget.state.pomodoroStatus == PomodoroStatus.running ||
        widget.state.pomodoroStatus == PomodoroStatus.paused) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ResetConfirmationDialog(
          hasBreak: widget.state.hasBreak,
          onConfirm: () {
            if (widget.state.penaltyCount > 0) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => SessionCompletionDialog(
                  penaltyCount: widget.state.penaltyCount,
                  totalPenaltyTime: widget.state.totalPenaltyTime,
                  isHardcoreMode: widget.state.isHardcoreMode,
                ),
              );
            }
            onConfirm();
          },
        ),
      );
    } else {
      onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final service = widget.service;
    final status = state.pomodoroStatus;
    final isActive = status == PomodoroStatus.running || status == PomodoroStatus.resting;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!state.isZoomMode) ...[
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: BouncingButton(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Icon(
                  Icons.replay,
                  size: 28,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              onPressed: () => _confirmReset(
                context,
                () => service.invoke('sendEvent', {'event': 'resetTimer'}),
              ),
            ),
          ),
          const SizedBox(width: 32),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return BouncingButton(
                    key: const ValueKey('play_pause_bouncy_btn'),
                    child: GestureDetector(
                      onTap: () {
                        if (status == PomodoroStatus.initial) {
                          service.invoke('sendEvent', {
                            'event': 'setBreakDuration',
                            'durationMinutes': state.defaultBreakDuration?.inMinutes,
                          });
                          service.invoke('sendEvent', {'event': 'startTimer'});
                        } else {
                          if (state.isHardcoreMode && state.isWaitingForFirstFlip) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!.hardcoreFlipMessage,
                                ),
                                backgroundColor: Colors.redAccent,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            return;
                          }
                          final event = isActive ? 'pauseTimer' : 'startTimer';
                          service.invoke('sendEvent', {'event': event});
                        }
                      },
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme.primary
                                  .withValues(alpha: isActive ? 0.5 : 0.3),
                              blurRadius: isActive ? _glowAnimation.value : 20,
                              spreadRadius: isActive ? 3 : 1,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedIcon(
                            icon: AnimatedIcons.play_pause,
                            progress: _iconController,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (state.hasBreak)
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                    child: isActive ? Padding(
                      key: const ValueKey('skipBtn'),
                      padding: const EdgeInsets.only(top: 16),
                      child: BouncingButton(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Icon(
                            Icons.skip_next_rounded,
                            size: 24,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        onPressed: () {
                          service.invoke('sendEvent', {'event': 'skipToNextPhase'});
                        },
                      ),
                    ) : const SizedBox.shrink(key: ValueKey('emptySkipBtn')),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 32),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: BouncingButton(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.isZoomMode
                    ? Colors.blueAccent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: state.isZoomMode
                      ? Colors.blueAccent.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                state.isZoomMode
                    ? Icons.zoom_in_map_rounded
                    : Icons.zoom_out_map_rounded,
                size: 28,
                color: state.isZoomMode ? Colors.blueAccent : Colors.white70,
              ),
            ),
            onPressed: () {
              service.invoke('sendEvent', {'event': 'toggleZoomMode'});
            },
          ),
        ),
      ],
    );
  }
}
