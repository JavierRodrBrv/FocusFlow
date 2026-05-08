part of 'feedback_bloc.dart';

sealed class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object> get props => [];
}

class SubmitFeedback extends FeedbackEvent {
  final String message;
  final String type;

  const SubmitFeedback({required this.message, required this.type});

  @override
  List<Object> get props => [message, type];
}

class ResetFeedback extends FeedbackEvent {}
