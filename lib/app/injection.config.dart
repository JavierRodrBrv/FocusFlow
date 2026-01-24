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
import '../data/services/sound_mixer_service.dart' as _i671;
import '../domain/repositories/premium_repository.dart' as _i1012;
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
  await gh.lazySingletonAsync<_i979.Box<_i430.PremiumStatus>>(
    () => hiveModule.premiumBox,
    preResolve: true,
  );
  gh.lazySingleton<_i671.SoundMixerService>(() => _i671.SoundMixerService());
  gh.lazySingleton<_i1012.PremiumRepository>(
      () => _i360.PremiumRepositoryImpl(gh<_i979.Box<_i430.PremiumStatus>>()));
  gh.factory<_i278.FocusBloc>(() => _i278.FocusBloc(
        gh<_i1012.PremiumRepository>(),
        gh<_i671.SoundMixerService>(),
      ));
  return getIt;
}

class _$HiveModule extends _i360.HiveModule {}
