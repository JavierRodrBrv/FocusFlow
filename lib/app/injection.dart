import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/premium/presentation/utils/ad_consent_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: r'$initGetIt', // default
  preferRelativeImports: true, // default
  asExtension: false, // default
)
Future<void> configureDependencies() async {
  debugPrint('[Injection] Registering external singletons...');
  // Servicios de infraestructura que no son instanciables por injectable
  getIt.registerLazySingleton<FlutterBackgroundService>(
    () => FlutterBackgroundService(),
  );
  getIt.registerLazySingleton<AdConsentManager>(() => AdConsentManager());

  debugPrint('[Injection] Running generated initializer...');
  $initGetIt(getIt);
  debugPrint('[Injection] Dependencies initialized.');
}
