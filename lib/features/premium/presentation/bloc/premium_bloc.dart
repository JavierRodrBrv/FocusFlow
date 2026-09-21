import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/purchase_premium_usecase.dart';

part 'premium_event.dart';
part 'premium_state.dart';

@injectable
class PremiumBloc extends Bloc<PremiumEvent, PremiumState> {
  final PurchasePremiumUseCase _purchasePremiumUseCase;

  PremiumBloc(this._purchasePremiumUseCase) : super(const PremiumState()) {
    on<PurchasePremiumRequested>(_onPurchasePremiumRequested);
  }

  Future<void> _onPurchasePremiumRequested(
    PurchasePremiumRequested event,
    Emitter<PremiumState> emit,
  ) async {
    emit(state.copyWith(status: PremiumStatus.loading));
    
    final result = await _purchasePremiumUseCase();
    
    result.fold(
      (failure) => emit(state.copyWith(status: PremiumStatus.failure)),
      (success) {
        if (success) {
          emit(state.copyWith(status: PremiumStatus.success));
        } else {
          emit(state.copyWith(status: PremiumStatus.failure));
        }
      },
    );
  }
}
