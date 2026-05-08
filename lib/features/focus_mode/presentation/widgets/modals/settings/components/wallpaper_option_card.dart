import 'package:flutter/material.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/background_effect.dart';

class WallpaperOptionCard extends StatelessWidget {
  final String label;
  final BackgroundEffect effect;
  final bool isSelected;
  final Widget preview;
  final VoidCallback onTap;

  const WallpaperOptionCard({
    super.key,
    required this.label,
    required this.effect,
    required this.isSelected,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 160,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: preview,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? Colors.blueAccent : Colors.white30,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
