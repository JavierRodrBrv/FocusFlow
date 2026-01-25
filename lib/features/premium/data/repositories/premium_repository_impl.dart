
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/premium_repository.dart';
import '../models/premium_status.dart';

const String _premiumBox = 'premiumBox';
const String _premiumStatusKey = 'premiumStatus';

@LazySingleton(as: PremiumRepository)
class PremiumRepositoryImpl implements PremiumRepository {
  final Box<PremiumStatus> box;

  PremiumRepositoryImpl(this.box);

  @override
  Future<bool> isPremium() async {
    final status = box.get(_premiumStatusKey, defaultValue: PremiumStatus(isPremium: false));
    print('[PremiumRepository] Getting premium status: ${status!.isPremium}');
    return status.isPremium;
  }

  @override
  Future<void> setPremiumStatus(bool isPremium) async {
    print('[PremiumRepository] Setting premium status to: $isPremium');
    await box.put(_premiumStatusKey, PremiumStatus(isPremium: isPremium));
  }
}

// Factory to open the box before the repository is created.
@module
abstract class HiveModule {
  @preResolve
  @lazySingleton
  Future<Box<PremiumStatus>> get premiumBox async {
    return await Hive.openBox<PremiumStatus>(_premiumBox);
  }
}
