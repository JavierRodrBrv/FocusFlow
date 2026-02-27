import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:hive/hive.dart';

class FocusSessionModel extends HiveObject {
  final String id;
  final String? groupId;
  final DateTime startTime;
  final int plannedDurationSeconds;
  final int actualDurationSeconds;
  final bool isHardcoreMode;
  final int penaltyCount;
  final int totalPenaltyTimeSeconds;
  final bool isResting;
  final bool isCompleted;

  FocusSessionModel({
    required this.id,
    this.groupId,
    required this.startTime,
    required this.plannedDurationSeconds,
    required this.actualDurationSeconds,
    required this.isHardcoreMode,
    required this.penaltyCount,
    required this.totalPenaltyTimeSeconds,
    required this.isResting,
    required this.isCompleted,
  });

  factory FocusSessionModel.fromEntity(FocusSession entity) {
    return FocusSessionModel(
      id: entity.id,
      groupId: entity.groupId,
      startTime: entity.startTime,
      plannedDurationSeconds: entity.plannedDuration.inSeconds,
      actualDurationSeconds: entity.actualDuration.inSeconds,
      isHardcoreMode: entity.isHardcoreMode,
      penaltyCount: entity.penaltyCount,
      totalPenaltyTimeSeconds: entity.totalPenaltyTime.inSeconds,
      isResting: entity.isResting,
      isCompleted: entity.isCompleted,
    );
  }

  FocusSession toEntity() {
    return FocusSession(
      id: id,
      groupId: groupId,
      startTime: startTime,
      plannedDuration: Duration(seconds: plannedDurationSeconds),
      actualDuration: Duration(seconds: actualDurationSeconds),
      isHardcoreMode: isHardcoreMode,
      penaltyCount: penaltyCount,
      totalPenaltyTime: Duration(seconds: totalPenaltyTimeSeconds),
      isResting: isResting,
      isCompleted: isCompleted,
    );
  }
}

class FocusSessionModelAdapter extends TypeAdapter<FocusSessionModel> {
  @override
  final int typeId = 2; // Unique ID for this adapter

  @override
  FocusSessionModel read(BinaryReader reader) {
    return FocusSessionModel(
      id: reader.readString(),
      startTime: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      plannedDurationSeconds: reader.readInt(),
      actualDurationSeconds: reader.readInt(),
      isHardcoreMode: reader.readBool(),
      penaltyCount: reader.readInt(),
      totalPenaltyTimeSeconds: reader.readInt(),
      isResting: reader.readBool(),
      isCompleted: reader.readBool(),
      groupId: reader.readBool()
          ? reader.readString()
          : null, // Handle nullable read
    );
  }

  @override
  void write(BinaryWriter writer, FocusSessionModel obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.startTime.millisecondsSinceEpoch);
    writer.writeInt(obj.plannedDurationSeconds);
    writer.writeInt(obj.actualDurationSeconds);
    writer.writeBool(obj.isHardcoreMode);
    writer.writeInt(obj.penaltyCount);
    writer.writeInt(obj.totalPenaltyTimeSeconds);
    writer.writeBool(obj.isResting);
    writer.writeBool(obj.isCompleted);
    writer.writeBool(obj.groupId != null);
    if (obj.groupId != null) {
      writer.writeString(obj.groupId!);
    }
  }
}
