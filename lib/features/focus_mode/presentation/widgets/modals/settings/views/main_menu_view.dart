import 'package:flutter/material.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';
import 'package:focus_flow/shared/theme/app_text_styles.dart';
import 'package:focus_flow/features/focus_mode/presentation/models/focus_state.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MainMenuView extends StatelessWidget {
  final FocusState state;
  final VoidCallback onToggleAlarm;
  final VoidCallback onToggleAutoTransition;
  final VoidCallback onGoToPomodoros;
  final VoidCallback onGoToWallpaper;
  final VoidCallback onGoToLanguage;
  final VoidCallback onGoToFeedback;
  final VoidCallback onShowTutorial;

  const MainMenuView({
    super.key,
    required this.state,
    required this.onToggleAlarm,
    required this.onToggleAutoTransition,
    required this.onGoToPomodoros,
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
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
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
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            l10n.alarmSoundSubtitle,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 12),
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
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            l10n.autoTransitionSubtitle,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 12),
          ),
          value: state.autoTransitionWhenForeground,
          onChanged: (_) => onToggleAutoTransition(),
          activeTrackColor: Colors.green,
          activeThumbColor: Colors.greenAccent,
        ),

        ListTile(
          leading: const Icon(
            Icons.timelapse,
            color: Colors.orangeAccent,
          ),
          title: Text(
            'Pomodoros',
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            state.isPomodoroMode
                ? 'Ciclo activo: ${state.pomodoroDuration.inMinutes} min / ${state.shortBreakDuration.inMinutes} min / ${state.longBreakDuration.inMinutes} min'
                : 'Temporizador normal (sin descansos)',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: Icon(Icons.chevron_right, color: AppColors.textPrimary.withValues(alpha: 0.3)),
          onTap: onGoToPomodoros,
        ),

        ListTile(
          leading: const Icon(
            Icons.palette_outlined,
            color: Colors.cyanAccent,
          ),
          title: Text(
            l10n.wallpaper,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          trailing: Icon(Icons.chevron_right, color: AppColors.textPrimary.withValues(alpha: 0.3)),
          onTap: onGoToWallpaper,
        ),

        ListTile(
          leading: const Icon(
            Icons.language,
            color: Colors.indigoAccent,
          ),
          title: Text(
            l10n.language,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            state.languageCode == 'en' ? l10n.english : l10n.spanish,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: Icon(Icons.chevron_right, color: AppColors.textPrimary.withValues(alpha: 0.3)),
          onTap: onGoToLanguage,
        ),

        Divider(color: AppColors.textPrimary.withValues(alpha: 0.1)),

        ListTile(
          leading: const Icon(Icons.menu_book, color: AppColors.textSecondary),
          title: Text(
            l10n.viewTutorial,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          onTap: onShowTutorial,
        ),

        ListTile(
          leading: const Icon(Icons.message, color: Colors.pinkAccent),
          title: Text(
            l10n.feedback,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            l10n.feedbackSubtitle,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 12),
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
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
