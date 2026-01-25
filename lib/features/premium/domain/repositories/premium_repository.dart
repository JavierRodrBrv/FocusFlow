
abstract class PremiumRepository {
  Future<bool> isPremium();
  Future<void> setPremiumStatus(bool isPremium);
}
