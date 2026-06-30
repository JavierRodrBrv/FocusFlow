import 'package:flutter/material.dart';
import '../../../../shared/theme/app_text_styles.dart';

class StatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatItem({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.caption,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTextStyles.h1,
          ),
        ),
      ],
    );
  }
}
