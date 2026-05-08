import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/premium_repository.dart';
import '../models/premium_status.dart';

const String _premiumBox = 'premiumBox';
const String _premiumStatusKey = 'premiumStatus';

@LazySingleton(as: PremiumRepository)
class PremiumRepositoryImpl implements PremiumRepository {
  PremiumRepositoryImpl();

  Future<Box<PremiumStatus>> get _box async {
    if (Hive.isBoxOpen(_premiumBox)) {
      return Hive.box<PremiumStatus>(_premiumBox);
    }
    return await Hive.openBox<PremiumStatus>(_premiumBox).timeout(const Duration(seconds: 3));
  }

  @override
  Future<bool> isPremium() async {
    try {
      final box = await _box;
      final status = box.get(
        _premiumStatusKey,
        defaultValue: PremiumStatus(isPremium: false),
      );
      debugPrint('[PremiumRepository] Getting premium status: ${status!.isPremium}');
      return status.isPremium;
    } catch (e) {
      debugPrint('[PremiumRepository] Error getting premium status: $e');
      return false;
    }
  }

  @override
  Future<void> setPremiumStatus(bool isPremium) async {
    try {
      debugPrint('[PremiumRepository] Setting premium status to: $isPremium');
      final box = await _box;
      await box.put(_premiumStatusKey, PremiumStatus(isPremium: isPremium));
    } catch (e) {
      debugPrint('[PremiumRepository] Error setting premium status: $e');
    }
  }
}
