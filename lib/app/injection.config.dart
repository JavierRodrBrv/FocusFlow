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

import '../data/models/premium_status.dart' as _i430;
import '../data/repositories/premium_repository_impl.dart' as _i360;
import '../data/services/haptic_feedback_service.dart' as _i102;
import '../data/services/sensor_service.dart' as _i262;
import '../data/services/sound_effect_service.dart' as _i426;
import '../data/services/sound_mixer_service.dart' as _i671;
import '../data/services/timer_service.dart' as _i271;
import '../data/services/unified_audio_manager.dart' as _i937;
import '../domain/repositories/premium_repository.dart' as _i1012;
import '../features/focus_mode/domain/repositories/i_audio_manager.dart'
    as _i507;
import '../features/focus_mode/domain/usecases/focus_session_manager.dart'
    as _i582;
import '../presentation/bloc/focus_bloc.dart' as _i278;

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
  gh.factory<_i271.TimerService>(() => _i271.TimerService());
  await gh.lazySingletonAsync<_i979.Box<_i430.PremiumStatus>>(
    () => hiveModule.premiumBox,
    preResolve: true,
  );
  gh.lazySingleton<_i102.HapticFeedbackService>(
    () => _i102.HapticFeedbackService(),
    dispose: (i) => i.dispose(),
  );
  gh.lazySingleton<_i262.SensorService>(
    () => _i262.SensorService(),
    dispose: (i) => i.dispose(),
  );
  gh.lazySingleton<_i426.SoundEffectService>(
    () => _i426.SoundEffectService(),
    dispose: (i) => i.dispose(),
  );
  gh.lazySingleton<_i671.SoundMixerService>(() => _i671.SoundMixerService());
  gh.lazySingleton<_i1012.PremiumRepository>(
      () => _i360.PremiumRepositoryImpl(gh<_i979.Box<_i430.PremiumStatus>>()));
  gh.lazySingleton<_i507.IAudioManager>(() => _i937.UnifiedAudioManager(
        gh<_i671.SoundMixerService>(),
        gh<_i426.SoundEffectService>(),
      ));
  gh.lazySingleton<_i582.FocusSessionManager>(() => _i582.FocusSessionManager(
        gh<_i507.IAudioManager>(),
        gh<_i262.SensorService>(),
        gh<_i271.TimerService>(),
        gh<_i102.HapticFeedbackService>(),
      ));
  gh.factory<_i278.FocusBloc>(() => _i278.FocusBloc(
        gh<_i1012.PremiumRepository>(),
        gh<_i582.FocusSessionManager>(),
      ));
  return getIt;
}

class _$HiveModule extends _i360.HiveModule {}
