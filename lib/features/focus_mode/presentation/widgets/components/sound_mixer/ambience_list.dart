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
        'name': 'Ninguno',
        'path': null,
        'icon': Icons.music_off_outlined,
      },
      {
        'name': 'Ranas',
        'path': 'assets/audio/frogs_sound.mp3',
        'svgPath': 'assets/icons/frog.svg'
      },
      {
        'name': 'Biblioteca',
        'path': 'assets/audio/library_sound.wav',
        'svgPath': 'assets/icons/library.svg'
      },
      {
        'name': 'Parque',
        'path': 'assets/audio/park_ambience.mp3',
        'icon': Icons.park,
      },
      {
        'name': 'Arroyo',
        'path': 'assets/audio/stream_ambience.mp3',
        'svgPath': 'assets/icons/arroyo.svg'
      },
      {
        'name': 'Media noche',
        'path': 'assets/audio/summer_midnight.wav',
        'icon': Icons.nights_stay,
      },
    ];

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

            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: item['path'] == null 
                  ? Icon(
                      Icons.music_off_outlined,
                      color: isSelected ? Colors.blueAccent : Colors.white38,
                      size: 20,
                    )
                  : (item['svgPath'] != null
                      ? SvgPicture.asset(
                          item['svgPath'] as String,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            isSelected ? Colors.blueAccent : Colors.white38,
                            BlendMode.srcIn,
                          ),
                        )
                      : Icon(
                          (item['icon'] as IconData?) ?? Icons.music_note_outlined,
                          color: isSelected ? Colors.blueAccent : Colors.white38,
                          size: 20,
                        )),
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
                  'path': item['path'],
                });
              },
            );
          },
        ),
      ],
    );
  }
}
