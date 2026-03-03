import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:focus_flow/features/premium/presentation/utils/ad_consent_manager.dart';

/// Servicio de orquestación de la pantalla principal.
/// Centraliza la lógica de deep links y gestión del consentimiento de anuncios,
/// manteniendo FocusView libre de lógica de negocio.
@lazySingleton
class FocusCoordinatorService {
  // Accedemos por GetIt porque FlutterBackgroundService y AdConsentManager
  // son singletons de infraestructura registrados manualmente fuera del
  // pipeline de injectable (son clases de terceros sin anotaciones).
  FlutterBackgroundService get _service =>
      GetIt.instance<FlutterBackgroundService>();
  AdConsentManager get _consentManager => GetIt.instance<AdConsentManager>();

  /// Procesa un deep link entrante y delega la acción al background service.
  void handleDeepLink(Uri uri) {
    if (uri.scheme != 'focusflow') return;
    final event = switch (uri.host) {
      'pause' => 'pauseTimer',
      'resume' => 'startTimer',
      'stop' => 'resetTimer',
      _ => null,
    };
    if (event != null) {
      _service.invoke('sendEvent', {'event': event});
    }
  }

  /// Solicita el consentimiento de anuncios y notifica el resultado al background service.
  Future<void> checkConsent() async {
    // Pequeña pausa para que el widget esté completamente montado antes de mostrar el diálogo
    await Future.delayed(const Duration(milliseconds: 500));
    final canRequest = await _consentManager.requestConsent();
    _service.invoke('sendEvent', {
      'event': 'updateConsentStatus',
      'canRequest': canRequest,
    });
  }
}
