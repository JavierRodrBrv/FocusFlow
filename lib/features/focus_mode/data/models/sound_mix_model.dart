import 'package:hive/hive.dart';

class SoundMixModel extends HiveObject {
  final double rainVolume;
  final double fireVolume;
  final double brownNoiseVolume;
  final String name;
  final DateTime createdAt;

  SoundMixModel({
    required this.rainVolume,
    required this.fireVolume,
    required this.brownNoiseVolume,
    required this.name,
    required this.createdAt,
  });
}

// Adaptador manual para evitar dependencia de build_runner en este paso
class SoundMixModelAdapter extends TypeAdapter<SoundMixModel> {
  @override
  final int typeId = 1;

  @override
  SoundMixModel read(BinaryReader reader) {
    return SoundMixModel(
      rainVolume: reader.readDouble(),
      fireVolume: reader.readDouble(),
      brownNoiseVolume: reader.readDouble(),
      name: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, SoundMixModel obj) {
    writer.writeDouble(obj.rainVolume);
    writer.writeDouble(obj.fireVolume);
    writer.writeDouble(obj.brownNoiseVolume);
    writer.writeString(obj.name);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
