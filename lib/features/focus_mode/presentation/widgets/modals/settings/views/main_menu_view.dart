import 'package:flutter/material.dart';
import 'package:focus_flow/features/focus_mode/presentation/models/focus_state.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MainMenuView extends StatelessWidget {
  final FocusState state;
  final VoidCallback onToggleAlarm;
  final VoidCallback onToggleAutoTransition;
  final VoidCallback onGoToBreaks;
  final VoidCallback onGoToWallpaper;
  final VoidCallback onGoToLanguage;
  final VoidCallback onGoToFeedback;
  final VoidCallback onShowTutorial;

  const MainMenuView({
    super.key,
    required this.state,
    required this.onToggleAlarm,
    required this.onToggleAutoTransition,
    required this.onGoToBreaks,
    required this.onGoToWallpaper,
    required this.onGoToLanguage,
    required this.onGoToFeedback,
    required this.onShowTutorial,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
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

        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            l10n.settingsAndHelp,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SwitchListTile(
          secondary: Icon(
            state.isAlarmSoundEnabled ? Icons.volume_up : Icons.volume_off,
            color: state.isAlarmSoundEnabled ? Colors.amber : Colors.grey,
          ),
          title: Text(
            l10n.alarmSound,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            l10n.alarmSoundSubtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          value: state.isAlarmSoundEnabled,
          onChanged: (_) => onToggleAlarm(),
          activeTrackColor: Colors.amber,
          activeThumbColor: Colors.amberAccent,
        ),

        SwitchListTile(
          secondary: Icon(
            state.autoTransitionWhenForeground ? Icons.autorenew : Icons.sync_disabled,
            color: state.autoTransitionWhenForeground ? Colors.greenAccent : Colors.grey,
          ),
          title: Text(
            l10n.autoTransition,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            l10n.autoTransitionSubtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          value: state.autoTransitionWhenForeground,
          onChanged: (_) => onToggleAutoTransition(),
          activeTrackColor: Colors.green,
          activeThumbColor: Colors.greenAccent,
        ),

        ListTile(
          leading: const Icon(
            Icons.coffee,
            color: Colors.orangeAccent,
          ),
          title: Text(
            l10n.breaks,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            state.defaultBreakDuration != null
                ? l10n.breaksPresetSubtitle(state.defaultBreakDuration!.inMinutes)
                : l10n.breaksSubtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white30),
          onTap: onGoToBreaks,
        ),

        ListTile(
          leading: const Icon(
            Icons.palette_outlined,
            color: Colors.cyanAccent,
          ),
          title: Text(
            l10n.wallpaper,
            style: const TextStyle(color: Colors.white),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white30),
          onTap: onGoToWallpaper,
        ),

        ListTile(
          leading: const Icon(
            Icons.language,
            color: Colors.indigoAccent,
          ),
          title: Text(
            l10n.language,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            state.languageCode == 'en' ? l10n.english : l10n.spanish,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white30),
          onTap: onGoToLanguage,
        ),

        const Divider(color: Colors.white10),

        ListTile(
          leading: const Icon(Icons.menu_book, color: Colors.white70),
          title: Text(
            l10n.viewTutorial,
            style: const TextStyle(color: Colors.white),
          ),
          onTap: onShowTutorial,
        ),

        ListTile(
          leading: const Icon(Icons.message, color: Colors.pinkAccent),
          title: Text(
            l10n.feedback,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            l10n.feedbackSubtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          onTap: onGoToFeedback,
        ),

        const SizedBox(height: 16),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final versionText = snapshot.data?.version ?? '...';
            return Center(
              child: Text(
                l10n.versionInfo(versionText),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white38,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
