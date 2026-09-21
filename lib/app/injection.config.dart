// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;

import '../core/device/audio/sound_effect_engine.dart' as _i395;
import '../core/device/audio/sound_mixer_engine.dart' as _i501;
import '../core/device/audio/unified_audio_manager.dart' as _i66;
import '../core/device/dnd_controller.dart' as _i721;
import '../core/device/haptic/haptic_engine.dart' as _i775;
import '../core/device/sensors/device_sensors.dart' as _i688;
import '../core/plugins/core_module.dart' as _i270;
import '../features/feedback/data/repositories/feedback_repository_impl.dart'
    as _i326;
import '../features/feedback/domain/repositories/feedback_repository.dart'
    as _i1011;
import '../features/feedback/domain/usecases/send_feedback_usecase.dart'
    as _i831;
import '../features/feedback/presentation/bloc/feedback_bloc.dart' as _i673;
import '../features/focus_mode/data/datasources/timer_service.dart' as _i150;
import '../features/focus_mode/data/repositories/focus_settings_repository_impl.dart'
    as _i909;
import '../features/focus_mode/data/repositories/sound_mix_repository_impl.dart'
    as _i910;
import '../features/focus_mode/domain/repositories/i_audio_manager.dart'
    as _i507;
import '../features/focus_mode/domain/repositories/i_focus_settings_repository.dart'
    as _i85;
import '../features/focus_mode/domain/repositories/sound_mix_repository.dart'
    as _i72;
import '../features/focus_mode/domain/services/focus_coordinator_service.dart'
    as _i322;
import '../features/focus_mode/domain/services/focus_session_manager.dart'
    as _i63;
import '../features/focus_mode/domain/services/penalty_tracker_service.dart'
    as _i349;
import '../features/focus_mode/domain/services/photo_service.dart' as _i765;
import '../features/focus_mode/domain/usecases/get_last_played_mix_usecase.dart'
    as _i1064;
import '../features/focus_mode/domain/usecases/get_saved_mixes_usecase.dart'
    as _i438;
import '../features/focus_mode/domain/usecases/i_process_session_usecase.dart'
    as _i719;
import '../features/focus_mode/domain/usecases/process_session_usecase.dart'
    as _i648;
import '../features/focus_mode/domain/usecases/save_last_played_mix_usecase.dart'
    as _i657;
import '../features/focus_mode/domain/usecases/save_sound_mix_usecase.dart'
    as _i676;
import '../features/focus_mode/presentation/bloc/audio_mix/audio_mix_bloc.dart'
    as _i724;
import '../features/focus_mode/presentation/bloc/settings/settings_bloc.dart'
    as _i477;
import '../features/focus_mode/presentation/bloc/timer/timer_bloc.dart'
    as _i661;
import '../features/premium/data/repositories/premium_repository_impl.dart'
    as _i380;
import '../features/premium/domain/repositories/premium_repository.dart'
    as _i843;
import '../features/premium/domain/usecases/purchase_premium_usecase.dart'
    as _i131;
import '../features/premium/presentation/bloc/premium_bloc.dart' as _i1023;
import '../features/session_history/data/repositories/session_history_repository_impl.dart'
    as _i777;
import '../features/session_history/domain/repositories/i_session_history_repository.dart'
    as _i506;
import '../features/session_history/domain/usecases/delete_session_usecase.dart'
    as _i684;
import '../features/session_history/domain/usecases/get_grouped_history_usecase.dart'
    as _i655;
import '../features/session_history/domain/usecases/get_session_history_usecase.dart'
    as _i37;
import '../features/session_history/domain/usecases/save_session_usecase.dart'
    as _i415;
import '../features/session_history/presentation/bloc/session_history_bloc.dart'
    as _i120;
import '../features/stats/data/repositories/hive_session_stats_repository_impl.dart'
    as _i405;
import '../features/stats/domain/repositories/i_session_stats_repository.dart'
    as _i18;
import '../features/stats/domain/usecases/get_weekly_stats_usecase.dart'
    as _i384;
import '../features/stats/presentation/bloc/stats_bloc.dart' as _i1057;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final coreModule = _$CoreModule();
  gh.factory<_i150.TimerService>(() => _i150.TimerService());
  gh.lazySingleton<_i395.SoundEffectEngine>(
    () => _i395.SoundEffectEngine(),
    dispose: (i) => i.dispose(),
  );
  gh.lazySingleton<_i501.SoundMixerEngine>(() => _i501.SoundMixerEngine());
  gh.lazySingleton<_i721.DndController>(() => _i721.DndController());
  gh.lazySingleton<_i775.HapticEngine>(
    () => _i775.HapticEngine(),
    dispose: (i) => i.dispose(),
  );
  gh.lazySingleton<_i688.DeviceSensors>(
    () => _i688.DeviceSensors(),
    dispose: (i) => i.dispose(),
  );
  gh.lazySingleton<_i519.Client>(() => coreModule.httpClient);
  gh.lazySingleton<_i322.FocusCoordinatorService>(
      () => _i322.FocusCoordinatorService());
  gh.lazySingleton<_i765.PhotoService>(() => _i765.PhotoService());
  gh.lazySingleton<_i131.PurchasePremiumUseCase>(
      () => _i131.PurchasePremiumUseCase());
  gh.lazySingleton<_i843.PremiumRepository>(
      () => _i380.PremiumRepositoryImpl());
  gh.lazySingleton<_i72.ISoundMixRepository>(
      () => _i910.SoundMixRepositoryImpl());
  gh.lazySingleton<_i85.IFocusSettingsRepository>(
      () => _i909.FocusSettingsRepositoryImpl());
  gh.lazySingleton<_i1011.IFeedbackRepository>(
      () => _i326.FeedbackRepositoryImpl(gh<_i519.Client>()));
  gh.lazySingleton<_i507.IAudioManager>(() => _i66.UnifiedAudioManager(
        gh<_i501.SoundMixerEngine>(),
        gh<_i395.SoundEffectEngine>(),
      ));
  gh.lazySingleton<_i1064.GetLastPlayedMixUseCase>(
      () => _i1064.GetLastPlayedMixUseCase(gh<_i72.ISoundMixRepository>()));
  gh.lazySingleton<_i657.SaveLastPlayedMixUseCase>(
      () => _i657.SaveLastPlayedMixUseCase(gh<_i72.ISoundMixRepository>()));
  gh.factory<_i438.GetSavedMixesUseCase>(
      () => _i438.GetSavedMixesUseCase(gh<_i72.ISoundMixRepository>()));
  gh.factory<_i676.SaveSoundMixUseCase>(
      () => _i676.SaveSoundMixUseCase(gh<_i72.ISoundMixRepository>()));
  gh.lazySingleton<_i506.ISessionHistoryRepository>(
      () => _i777.SessionHistoryRepositoryImpl());
  gh.lazySingleton<_i18.ISessionStatsRepository>(() =>
      _i405.SessionStatsRepositoryImpl(gh<_i506.ISessionHistoryRepository>()));
  gh.factory<_i1023.PremiumBloc>(
      () => _i1023.PremiumBloc(gh<_i131.PurchasePremiumUseCase>()));
  gh.factory<_i831.SendFeedbackUseCase>(
      () => _i831.SendFeedbackUseCase(gh<_i1011.IFeedbackRepository>()));
  gh.factory<_i384.GetWeeklyStatsUseCase>(
      () => _i384.GetWeeklyStatsUseCase(gh<_i18.ISessionStatsRepository>()));
  gh.lazySingleton<_i684.DeleteSessionUseCase>(
      () => _i684.DeleteSessionUseCase(gh<_i506.ISessionHistoryRepository>()));
  gh.lazySingleton<_i37.GetSessionHistoryUseCase>(() =>
      _i37.GetSessionHistoryUseCase(gh<_i506.ISessionHistoryRepository>()));
  gh.lazySingleton<_i415.SaveSessionUseCase>(
      () => _i415.SaveSessionUseCase(gh<_i506.ISessionHistoryRepository>()));
  gh.lazySingleton<_i349.PenaltyTrackerService>(
      () => _i349.PenaltyTrackerService(
            gh<_i507.IAudioManager>(),
            gh<_i775.HapticEngine>(),
          ));
  gh.lazySingleton<_i63.FocusSessionManager>(() => _i63.FocusSessionManager(
        gh<_i507.IAudioManager>(),
        gh<_i775.HapticEngine>(),
        gh<_i688.DeviceSensors>(),
        gh<_i150.TimerService>(),
        gh<_i721.DndController>(),
        gh<_i85.IFocusSettingsRepository>(),
        gh<_i349.PenaltyTrackerService>(),
      ));
  gh.lazySingleton<_i719.IProcessSessionUseCase>(
      () => _i648.ProcessSessionUseCase(gh<_i415.SaveSessionUseCase>()));
  gh.factory<_i673.FeedbackBloc>(
      () => _i673.FeedbackBloc(gh<_i831.SendFeedbackUseCase>()));
  gh.factory<_i1057.StatsBloc>(
      () => _i1057.StatsBloc(gh<_i384.GetWeeklyStatsUseCase>()));
  gh.factory<_i477.SettingsBloc>(
      () => _i477.SettingsBloc(gh<_i63.FocusSessionManager>()));
  gh.factory<_i724.AudioMixBloc>(() => _i724.AudioMixBloc(
        gh<_i63.FocusSessionManager>(),
        gh<_i676.SaveSoundMixUseCase>(),
        gh<_i438.GetSavedMixesUseCase>(),
        gh<_i1064.GetLastPlayedMixUseCase>(),
        gh<_i657.SaveLastPlayedMixUseCase>(),
      ));
  gh.factory<_i655.GetGroupedHistoryUseCase>(
      () => _i655.GetGroupedHistoryUseCase(
            gh<_i37.GetSessionHistoryUseCase>(),
            gh<_i63.FocusSessionManager>(),
          ));
  gh.factory<_i120.SessionHistoryBloc>(() => _i120.SessionHistoryBloc(
        gh<_i655.GetGroupedHistoryUseCase>(),
        gh<_i684.DeleteSessionUseCase>(),
      ));
  gh.factory<_i661.TimerBloc>(() => _i661.TimerBloc(
        gh<_i63.FocusSessionManager>(),
        gh<_i719.IProcessSessionUseCase>(),
      ));
  return getIt;
}

class _$CoreModule extends _i270.CoreModule {}
