import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/get_weekly_stats_usecase.dart';
import 'stats_event.dart';
import 'stats_state.dart';

@injectable
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final GetWeeklyStatsUseCase _getWeeklyStatsUseCase;

  StatsBloc(this._getWeeklyStatsUseCase) : super(StatsInitial()) {
    on<LoadDailyStats>(_onLoadDailyStats);

    FlutterBackgroundService().on('refresh_history').listen((_) {
      if (!isClosed) add(LoadDailyStats());
    });
  }

  Future<void> _onLoadDailyStats(LoadDailyStats event, Emitter<StatsState> emit) async {
    bool isForward = true;
    if (state is StatsLoaded && event.baseDate != null) {
      final oldStart = (state as StatsLoaded).currentWeekStart;
      if (event.baseDate!.isBefore(oldStart)) {
        isForward = false;
      }
    }
    
    emit(StatsLoading());

    try {
      final now = DateTime.now();
      final baseDate = event.baseDate ?? now;
      
      final statsData = await _getWeeklyStatsUseCase(baseDate);

      emit(StatsLoaded(
        currentStreak: statsData.currentStreak,
        totalSecondsFocus: statsData.totalSecondsFocus,
        weeklyBarData: statsData.weeklyBarData,
        currentWeekStart: statsData.currentWeekStart,
        previousWeekDate: statsData.previousWeekDate,
        nextWeekDate: statsData.nextWeekDate,
        isForwardNavigation: isForward,
      ));
    } catch (e) {
      emit(StatsError(e.toString()));
    }
  }
}
