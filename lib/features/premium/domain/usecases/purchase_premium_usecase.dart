import 'package:focus_flow/flavors.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:focus_flow/core/error/failures.dart';

@lazySingleton
class PurchasePremiumUseCase {
  Future<Either<Failure, bool>> call() async {
    if (F.appFlavor == Flavor.dev) {
      // En entorno de desarrollo (DEV), simulamos la compra invocando al Background Service
      FlutterBackgroundService().invoke('sendEvent', {
        'event': 'togglePremium',
      });
      
      // Simulamos un pequeño retraso de red
      await Future.delayed(const Duration(milliseconds: 1500));
      return const Right(true);
    } else {
      // TODO: En producción, implementar In-App Purchases de Google Play / App Store
      await Future.delayed(const Duration(milliseconds: 1500));
      return const Right(false); // Hasta que se implemente
    }
  }
}
