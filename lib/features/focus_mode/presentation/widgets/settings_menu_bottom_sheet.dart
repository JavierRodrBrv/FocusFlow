import 'package:flutter/material.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/feedback_bottom_sheet.dart';

class SettingsMenuBottomSheet extends StatelessWidget {
  const SettingsMenuBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Ajustes y Ayuda',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.menu_book, color: Colors.white70),
            title: const Text('Ver Tutorial', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context, 'tutorial');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.mail_outline, color: Colors.blueAccent),
            title: const Text('Enviar Feedback / Reportar Bug', style: TextStyle(color: Colors.white)),
            subtitle: const Text('¡Tu opinión nos ayuda a mejorar!', style: TextStyle(color: Colors.white38)),
            onTap: () async {
              // Close the menu first
              Navigator.pop(context);
              
              // Open the Feedback Sheet
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true, // Important for the input field to work well with keyboard
                builder: (context) => const FeedbackBottomSheet(),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white54),
            title: const Text('Versión 0.1.0 (Beta)', style: TextStyle(color: Colors.white54)),
            onTap: () {}, 
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
