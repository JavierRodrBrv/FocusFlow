import 'package:hive/hive.dart';
import '../../domain/entities/sound_mix.dart';

class SoundMixModel extends HiveObject {
  final String id;
  final double rainVolume;
  final double fireVolume;
  final double brownNoiseVolume;
  final String name;
  final DateTime createdAt;

  SoundMixModel({
    required this.id,
    required this.rainVolume,
    required this.fireVolume,
    required this.brownNoiseVolume,
    required this.name,
    required this.createdAt,
  });

  factory SoundMixModel.fromEntity(SoundMix entity) {
    return SoundMixModel(
      id: entity.id,
      rainVolume: entity.rainVolume,
      fireVolume: entity.fireVolume,
      brownNoiseVolume: entity.brownNoiseVolume,
      name: entity.name,
      createdAt: entity.createdAt,
    );
  }

  SoundMix toEntity() {
    return SoundMix(
      id: id,
      name: name,
      rainVolume: rainVolume,
      fireVolume: fireVolume,
      brownNoiseVolume: brownNoiseVolume,
      createdAt: createdAt,
    );
  }
}

class SoundMixModelAdapter extends TypeAdapter<SoundMixModel> {
  @override
  final int typeId = 1;

  @override
  SoundMixModel read(BinaryReader reader) {
    return SoundMixModel(
      id: reader.readString(),
      rainVolume: reader.readDouble(),
      fireVolume: reader.readDouble(),
      brownNoiseVolume: reader.readDouble(),
      name: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, SoundMixModel obj) {
    writer.writeString(obj.id);
    writer.writeDouble(obj.rainVolume);
    writer.writeDouble(obj.fireVolume);
    writer.writeDouble(obj.brownNoiseVolume);
    writer.writeString(obj.name);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
