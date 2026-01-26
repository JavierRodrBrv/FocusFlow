// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:hive/hive.dart' as _i979;
import 'package:injectable/injectable.dart' as _i526;

import '../core/services/audio/sound_effect_service.dart' as _i48;
import '../core/services/audio/sound_mixer_service.dart' as _i582;
import '../core/services/audio/unified_audio_manager.dart' as _i171;
import '../core/services/haptic/haptic_feedback_service.dart' as _i182;
import '../core/services/sensors/sensor_service.dart' as _i350;
import '../features/focus_mode/data/datasources/timer_service.dart' as _i150;
import '../features/focus_mode/data/repositories/sound_mix_repository_impl.dart'
    as _i910;
import '../features/focus_mode/domain/repositories/i_audio_manager.dart'
    as _i507;
import '../features/focus_mode/domain/repositories/sound_mix_repository.dart'
    as _i72;
import '../features/focus_mode/domain/usecases/focus_session_manager.dart'
    as _i582;
import '../features/focus_mode/presentation/bloc/focus_bloc.dart' as _i176;
import '../features/premium/data/models/premium_status.dart' as _i434;
import '../features/premium/data/repositories/premium_repository_impl.dart'
    as _i380;
import '../features/premium/domain/repositories/premium_repository.dart'
    as _i843;

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i174.GetIt> $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final hiveModule = _$HiveModule();
  gh.factory<_i150.TimerService>(() => _i150.TimerService());
  gh.lazySingleton<_i48.SoundEffectService>(
    () => _i48.SoundEffectService(),
    dispose: (i) => i.dispose(),
  );
  gh.lazySingleton<_i582.SoundMixerService>(() => _i582.SoundMixerService());
  gh.lazySingleton<_i182.HapticFeedbackService>(
    () => _i182.HapticFeedbackService(),
    dispose: (i) => i.dispose(),
  );
  gh.lazySingleton<_i350.SensorService>(
    () => _i350.SensorService(),
    dispose: (i) => i.dispose(),
  );
  await gh.lazySingletonAsync<_i979.Box<_i434.PremiumStatus>>(
    () => hiveModule.premiumBox,
    preResolve: true,
  );
  gh.lazySingleton<_i72.SoundMixRepository>(
      () => _i910.SoundMixRepositoryImpl());
  gh.lazySingleton<_i507.IAudioManager>(() => _i171.UnifiedAudioManager(
        gh<_i582.SoundMixerService>(),
        gh<_i48.SoundEffectService>(),
      ));
  gh.lazySingleton<_i843.PremiumRepository>(
      () => _i380.PremiumRepositoryImpl(gh<_i979.Box<_i434.PremiumStatus>>()));
  gh.lazySingleton<_i582.FocusSessionManager>(() => _i582.FocusSessionManager(
        gh<_i507.IAudioManager>(),
        gh<_i350.SensorService>(),
        gh<_i150.TimerService>(),
        gh<_i182.HapticFeedbackService>(),
      ));
  gh.factory<_i176.FocusBloc>(() => _i176.FocusBloc(
        gh<_i843.PremiumRepository>(),
        gh<_i582.FocusSessionManager>(),
        gh<_i72.SoundMixRepository>(),
      ));
  return getIt;
}

class _$HiveModule extends _i380.HiveModule {}
