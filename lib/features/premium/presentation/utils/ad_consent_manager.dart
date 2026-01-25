import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdConsentManager {
  static final AdConsentManager _instance = AdConsentManager._internal();
  factory AdConsentManager() => _instance;
  AdConsentManager._internal();

  Future<bool> requestConsent() async {
    final completer = Completer<bool>();

    final params = ConsentRequestParameters();
    
    // Descomentar para pruebas:
    // final debugSettings = ConsentDebugSettings(
    //   debugGeography: DebugGeography.debugGeographyEea,
    //   testIdentifiers: ['TEST-DEVICE-HASH'], // Sacar del logcat
    // );
    // final params = ConsentRequestParameters(consentDebugSettings: debugSettings);

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
            if (formError != null) {
              // Error mostrando el formulario
              print('[AdConsentManager] Error showing consent form: ${formError.message}');
            }
            // Haya error o no, comprobamos si podemos pedir anuncios
            final canRequest = await ConsentInformation.instance.canRequestAds();
            completer.complete(canRequest);
          });
        } else {
          // No hay formulario disponible (ej: fuera de EU o ya tiene consentimiento)
          final canRequest = await ConsentInformation.instance.canRequestAds();
          completer.complete(canRequest);
        }
      },
      (FormError error) {
        print('[AdConsentManager] Error requesting consent info: ${error.message}');
        completer.complete(false); // Asumimos false por seguridad en error
      },
    );

    return completer.future;
  }
}
