import 'dart:async';
import 'package:focus_flow/shared/theme/app_colors.dart';
import 'package:focus_flow/shared/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class AlternatingButtonText extends StatefulWidget {
  const AlternatingButtonText({super.key});

  @override
  State<AlternatingButtonText> createState() => _AlternatingButtonTextState();
}

class _AlternatingButtonTextState extends State<AlternatingButtonText> {
  bool _showHint = false;
  Timer? _timer;
  bool _isFirstCycle = true;

  @override
  void initState() {
    super.initState();
    _scheduleNextToggle();
  }

  void _scheduleNextToggle() {
    int nextDurationSeconds;
    
    if (_isFirstCycle) {
      nextDurationSeconds = 4;
      _isFirstCycle = false;
    } else {
      nextDurationSeconds = 10;
    }

    _timer = Timer(Duration(seconds: nextDurationSeconds), () {
      if (mounted) {
        setState(() {
          _showHint = !_showHint;
        });
        _scheduleNextToggle();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInBack,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: _showHint
          ? Text(
              'Recuerda lo jodido\nque has acabado esta sesión',
              key: ValueKey('hint'),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            )
          : Text(
              '¿Sonríes?',
              key: ValueKey('main'),
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}
