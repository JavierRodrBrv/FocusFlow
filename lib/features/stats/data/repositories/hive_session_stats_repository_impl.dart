import 'package:focus_flow/features/stats/domain/entities/session_record.dart';
import 'package:focus_flow/features/stats/domain/repositories/i_session_stats_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ISessionStatsRepository)
class HiveSessionStatsRepositoryImpl implements ISessionStatsRepository {
  static const String _boxName = 'session_stats_box';

  /// Execute an operation safely by opening and closing the box
  Future<T> _withBox<T>(Future<T> Function(Box<Map> box) operation) async {
    final box = await Hive.openBox<Map>(_boxName);
    try {
      return await operation(box);
    } finally {
      if (box.isOpen) {
        await box.close();
      }
    }
  }

  @override
  Future<void> saveSession(SessionRecord record) async {
    await _withBox((box) async {
      final data = {
        'id': record.id,
        'startTime': record.startTime.toIso8601String(),
        'endTime': record.endTime.toIso8601String(),
        'durationSeconds': record.durationSeconds,
        'status': record.status,
      };
      await box.put(record.id, data);
    });
  }

  @override
  Future<List<SessionRecord>> getSessionsByDateRange(DateTime start, DateTime end) async {
    return await _withBox((box) async {
      final records = <SessionRecord>[];
      for (var value in box.values) {
        final startTime = DateTime.parse(value['startTime'] as String);
        if (startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
            startTime.isBefore(end.add(const Duration(seconds: 1)))) {
          records.add(
            SessionRecord(
              id: value['id'] as String,
              startTime: startTime,
              endTime: DateTime.parse(value['endTime'] as String),
              durationSeconds: value['durationSeconds'] as int,
              status: value['status'] as String,
            ),
          );
        }
      }
      return records;
    });
  }
}
