import 'package:equatable/equatable.dart';

class SessionRecord extends Equatable {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final String status;

  const SessionRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.status,
  });

  @override
  List<Object?> get props => [id, startTime, endTime, durationSeconds, status];
}
