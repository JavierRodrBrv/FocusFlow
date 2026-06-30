import 'package:flutter/material.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/time_formatter.dart';
import '../bloc/stats_state.dart';
import 'stat_item.dart';

class OverviewCards extends StatelessWidget {
  final StatsLoaded state;

  const OverviewCards({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: StatItem(
              title: AppLocalizations.of(context)!.currentStreak,
              value: AppLocalizations.of(context)!.streakDays(state.currentStreak),
              icon: Icons.local_fire_department_rounded,
              color: AppColors.accent,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassCard(
            child: StatItem(
              title: AppLocalizations.of(context)!.totalFocused,
              value: state.totalSecondsFocus.toFormattedDuration(context),
              icon: Icons.timer_rounded,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
