import 'package:focus_flow/l10n/app_localizations.dart';

extension StatsDateExtension on DateTime {
  DateTime get endOfWeek => add(const Duration(days: 6));
  
  DateTime dateFromDayIndex(int dayIndex) => add(Duration(days: dayIndex - 1));

  String formatWeekRange(AppLocalizations l10n, bool isCurrentWeek) {
    if (isCurrentWeek) {
      return l10n.thisWeek;
    }
    return l10n.weekRange(
      '$day/$month',
      '${endOfWeek.day}/${endOfWeek.month}',
    );
  }
}
