import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:focus_flow/core/domain/result.dart';
import '../../domain/usecases/send_feedback_usecase.dart';

part 'feedback_event.dart';
part 'feedback_state.dart';

@injectable
class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final SendFeedbackUseCase _sendFeedbackUseCase;

  FeedbackBloc(this._sendFeedbackUseCase) : super(const FeedbackState()) {
    on<SubmitFeedback>(_onSubmitFeedback);
    on<ResetFeedback>(_onResetFeedback);
  }

  Future<void> _onSubmitFeedback(
    SubmitFeedback event,
    Emitter<FeedbackState> emit,
  ) async {
    if (event.message.trim().isEmpty) return;

    emit(state.copyWith(status: FeedbackStatus.loading));

    final result = await _sendFeedbackUseCase(
      message: event.message,
      type: event.type,
    );

    if (result is Success) {
      emit(state.copyWith(status: FeedbackStatus.success));
    } else if (result is Error) {
      emit(state.copyWith(
        status: FeedbackStatus.failure,
        errorMessage: result.failure.message,
      ));
    }
  }

  void _onResetFeedback(ResetFeedback event, Emitter<FeedbackState> emit) {
    emit(const FeedbackState());
  }
}
