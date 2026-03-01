import 'package:flutter/material.dart';

class MixerHeader extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final Animation<double> expandAnimation;

  const MixerHeader({
    super.key,
    required this.isPlaying,
    required this.onTap,
    required this.expandAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(
              Icons.tune,
              color: isPlaying ? Colors.blueAccent : Colors.white70,
              size: 22,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Mezclador de Sonido',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            RotationTransition(
              turns: Tween(begin: 0.0, end: 0.5).animate(expandAnimation),
              child: const Icon(Icons.expand_more, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}
