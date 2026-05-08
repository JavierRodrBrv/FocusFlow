import 'package:flutter/material.dart';

class LanguageTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.greenAccent)
          : null,
      onTap: onTap,
    );
  }
}
