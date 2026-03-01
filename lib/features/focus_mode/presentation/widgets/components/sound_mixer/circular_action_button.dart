import 'package:flutter/material.dart';

class CircularActionButton extends StatelessWidget {
  final IconData icon;
  final bool isPremium;
  final VoidCallback onPressed;
  final Color color;

  const CircularActionButton({
    super.key,
    required this.icon,
    required this.isPremium,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              color: isPremium ? color : Colors.white24,
              size: 24,
            ),
            if (!isPremium)
              const Positioned(
                right: -4,
                bottom: -4,
                child: Icon(Icons.lock, size: 14, color: Colors.amber),
              ),
          ],
        ),
      ),
    );
  }
}
