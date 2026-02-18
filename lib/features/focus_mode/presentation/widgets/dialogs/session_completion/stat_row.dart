import 'package:flutter/material.dart';

class StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
