part of 'feedback_bloc.dart';

enum FeedbackStatus { initial, loading, success, failure }

class FeedbackState extends Equatable {
  final FeedbackStatus status;
  final String? errorMessage;

  const FeedbackState({
    this.status = FeedbackStatus.initial,
    this.errorMessage,
  });

  FeedbackState copyWith({
    FeedbackStatus? status,
    String? errorMessage,
  }) {
    return FeedbackState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
