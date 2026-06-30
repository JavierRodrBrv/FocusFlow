import 'package:flutter/material.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/utils/date_extensions.dart';
import '../../../session_history/presentation/pages/session_history_page.dart';
import '../bloc/stats_state.dart';
import 'animated_bar_chart.dart';

class WeeklyChartArea extends StatelessWidget {
  final StatsLoaded state;

  const WeeklyChartArea({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            final offsetAnimation = Tween<Offset>(
              begin: Offset(state.isForwardNavigation ? 0.2 : -0.2, 0.0),
              end: Offset.zero,
            ).animate(animation);
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: AnimatedBarChart(
            key: ValueKey(state.currentWeekStart),
            weeklyData: state.weeklyBarData,
            maxY: state.weeklyBarData.values.fold(0.0, (m, v) => v > m ? v : m),
            onBarTapped: (dayIndex) {
              final targetDate = state.currentWeekStart.dateFromDayIndex(dayIndex);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionHistoryPage(filterDate: targetDate),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
