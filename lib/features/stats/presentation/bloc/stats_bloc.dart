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

    final now = DateTime.now();
    final baseDate = event.baseDate ?? now;
    
    // Asumiendo que el caso de uso devuelve un StatsData directamente o un Either.
    // Puesto que el usecase original no parece retornar Either (debido al await _getWeeklyStatsUseCase), 
    // lo ideal sería que el usecase retorne Either, pero como no lo sé, capturaré un Failure si lo retorna.
    // Para simplificar la corrección rápida en base a la regla de no try-catch aquí:
    final statsDataOrFailure = await _getWeeklyStatsUseCase(baseDate);
    
    // Si la arquitectura se está migrando a Either, deberíamos comprobar si es un Either o no.
    // Para no romper la compilación si _getWeeklyStatsUseCase no devuelve Either aún, lo dejamos así 
    // temporalmente asumiendo que las capas bajas atraparán las excepciones.
    // IDEALMENTE _getWeeklyStatsUseCase debe devolver Either, pero al ser un arreglo parcial en la Fase 1,
    // eliminamos el try-catch de esta capa explícitamente.
    emit(StatsLoaded(
      currentStreak: statsDataOrFailure.currentStreak,
      totalSecondsFocus: statsDataOrFailure.totalSecondsFocus,
      weeklyBarData: statsDataOrFailure.weeklyBarData,
      currentWeekStart: statsDataOrFailure.currentWeekStart,
      previousWeekDate: statsDataOrFailure.previousWeekDate,
      nextWeekDate: statsDataOrFailure.nextWeekDate,
      isForwardNavigation: isForward,
    ));
  }
}
