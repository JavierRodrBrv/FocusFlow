import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/date_extensions.dart';
import '../bloc/stats_bloc.dart';
import '../bloc/stats_event.dart';
import '../bloc/stats_state.dart';

class WeekSelector extends StatelessWidget {
  final StatsLoaded state;

  const WeekSelector({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCurrentWeek = state.nextWeekDate == null;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (state.previousWeekDate != null)
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () {
              context.read<StatsBloc>().add(LoadDailyStats(
                baseDate: state.previousWeekDate!,
              ));
            },
          )
        else
          const SizedBox(width: 48),

        Expanded(
          child: Text(
            state.currentWeekStart.formatWeekRange(l10n, isCurrentWeek),
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),

        if (state.nextWeekDate != null)
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () {
              context.read<StatsBloc>().add(LoadDailyStats(
                baseDate: state.nextWeekDate!,
              ));
            },
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }
}
