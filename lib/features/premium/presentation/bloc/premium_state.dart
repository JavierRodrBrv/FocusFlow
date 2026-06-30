part of 'premium_bloc.dart';

enum PremiumStatus { initial, loading, success, failure }

class PremiumState {
  final PremiumStatus status;

  const PremiumState({
    this.status = PremiumStatus.initial,
  });

  PremiumState copyWith({
    PremiumStatus? status,
  }) {
    return PremiumState(
      status: status ?? this.status,
    );
  }
}
