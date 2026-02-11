import 'package:hive/hive.dart';

part 'premium_status.g.dart';

@HiveType(typeId: 0)
class PremiumStatus extends HiveObject {
  @HiveField(0)
  bool isPremium;

  PremiumStatus({required this.isPremium});
}
