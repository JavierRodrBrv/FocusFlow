import 'dart:async';
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
    int nextDurationSeconds = 4;
    
    if (!_showHint) {
      // Currently showing "¿Sonríes?"
      if (_isFirstCycle) {
        nextDurationSeconds = 4;
        _isFirstCycle = false;
      } else {
        nextDurationSeconds = 10;
      }
    } else {
      // Currently showing the hint text
      nextDurationSeconds = 4;
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
          ? const Text(
              'Recuerda lo jodido\nque has acabado',
              key: ValueKey('hint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            )
          : const Text(
              '¿Sonríes?',
              key: ValueKey('main'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}
