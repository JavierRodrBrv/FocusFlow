import 'package:flutter/material.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';
import 'package:focus_flow/shared/theme/app_text_styles.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/presentation/models/focus_state.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AmbienceList extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const AmbienceList({super.key, required this.state, required this.service});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ambiences = [
      {'name': l10n.none, 'path': null, 'icon': Icons.music_off_outlined},
      {
        'name': l10n.frogs,
        'path': 'assets/audio/frogs_sound.mp3',
        'svgPath': 'assets/icons/frog.svg',
      },
      {
        'name': l10n.library,
        'path': 'assets/audio/library_sound.wav',
        'svgPath': 'assets/icons/library.svg',
      },
      {
        'name': l10n.park,
        'path': 'assets/audio/park_ambience.mp3',
        'icon': Icons.park,
      },
      {
        'name': l10n.stream,
        'path': 'assets/audio/stream_ambience.mp3',
        'svgPath': 'assets/icons/arroyo.svg',
      },
      {
        'name': l10n.midnight,
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
                      color: isSelected ? Colors.blueAccent : AppColors.textSecondary,
                      size: 20,
                    )
                  : (item['svgPath'] != null
                        ? SvgPicture.asset(
                            item['svgPath'] as String,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              isSelected ? Colors.blueAccent : AppColors.textSecondary,
                              BlendMode.srcIn,
                            ),
                          )
                        : Icon(
                            (item['icon'] as IconData?) ??
                                Icons.music_note_outlined,
                            color: isSelected
                                ? Colors.blueAccent
                                : AppColors.textSecondary,
                            size: 20,
                          )),
              title: Text(
                item['name'] as String,
                style: AppTextStyles.body.copyWith(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
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
