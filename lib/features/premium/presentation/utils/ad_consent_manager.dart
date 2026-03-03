import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdConsentManager {
  static final AdConsentManager _instance = AdConsentManager._internal();
  factory AdConsentManager() => _instance;
  AdConsentManager._internal();

  Future<bool> requestConsent() async {
    final completer = Completer<bool>();

    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
            if (formError != null) {
              debugPrint(
                '[AdConsentManager] Error showing consent form: ${formError.message}',
              );
            }
            final canRequest = await ConsentInformation.instance
                .canRequestAds();
            completer.complete(canRequest);
          });
        } else {
          final canRequest = await ConsentInformation.instance.canRequestAds();
          completer.complete(canRequest);
        }
      },
      (FormError error) {
        debugPrint(
          '[AdConsentManager] Error requesting consent info: ${error.message}',
        );
        completer.complete(false);
      },
    );

    return completer.future;
  }
}
