import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2504977656199670/3332416242';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2504977656199670/3364205835';
      }
      throw UnsupportedError('Unsupported platform');
    } else {
      // Test Banner IDs provided by Google
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2504977656199670/1609662349';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2504977656199670/9643085092';
      }
      throw UnsupportedError('Unsupported platform');
    } else {
      // Test Interstitial IDs provided by Google
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910';
      }
      throw UnsupportedError('Unsupported platform');
    }
  }
}
