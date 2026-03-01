import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../../models/focus_state.dart';

import 'package:flutter_svg/flutter_svg.dart';
import '../shared/bouncing_button.dart';

class AmbienceList extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const AmbienceList({super.key, required this.state, required this.service});

  @override
  Widget build(BuildContext context) {
    final ambiences = [
      {
        'name': 'Ranas',
        'path': 'assets/audio/frogs_sound.mp3',
        'icon': Icons.nature,
        'svgPath': 'assets/icons/frog.svg'
      },
      {
        'name': 'Biblioteca',
        'path': 'assets/audio/library_sound.wav',
        'icon': Icons.library_books,
        'svgPath': 'assets/icons/library.svg'
      },
      {
        'name': 'Parque',
        'path': 'assets/audio/park_ambience.mp3',
        'icon': Icons.park,
      },
      {
        'name': 'Arroyo',
        'path': 'assets/audio/stream_ambience.wav',
        'icon': Icons.water,
        'svgPath': 'assets/icons/arroyo.svg'
      },
      {
        'name': 'Media noche',
        'path': 'assets/audio/summer_midnight.wav',
        'icon': Icons.nights_stay,
      },
    ];

    final isPlayingAmbience = state.selectedAmbiencePath != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ambiences.length,
          itemBuilder: (context, index) {
            final item = ambiences[index];
            final isSelected = state.selectedAmbiencePath == item['path'];
            final String? svgPath = item['svgPath'] as String?;

            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: svgPath != null
                  ? SvgPicture.asset(
                      svgPath,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        isSelected ? Colors.blueAccent : Colors.white38,
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(
                      item['icon'] as IconData,
                      color: isSelected ? Colors.blueAccent : Colors.white38,
                      size: 20,
                    ),
              title: Text(
                item['name'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blueAccent, size: 18)
                  : null,
              onTap: () {
                service.invoke('sendEvent', {
                  'event': 'setAmbienceSound',
                  'path': isSelected ? null : item['path'],
                });
              },
            );
          },
        ),
        const SizedBox(height: 24),
        Center(
          child: BouncingButton(
            onPressed: isPlayingAmbience 
                ? () => service.invoke('sendEvent', {
                    'event': 'setAmbienceSound',
                    'path': state.selectedAmbiencePath, // Toggle off
                  })
                : null, // No hace nada si no hay selección previa
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPlayingAmbience
                    ? Colors.blueAccent
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                boxShadow: isPlayingAmbience
                    ? [
                        BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                isPlayingAmbience ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isPlayingAmbience ? Colors.white : Colors.white24,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isPlayingAmbience ? "DETENER AMBIENTE" : "SELECCIONA UN SONIDO",
          style: TextStyle(
            color: isPlayingAmbience ? Colors.blueAccent : Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
