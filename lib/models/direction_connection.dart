import 'package:hive/hive.dart';

/// Links an entry to a direction (many-to-many relationship)
class DirectionConnection {
  final String id;
  final String directionId;
  final String entryId;
  final DateTime createdAt;

  DirectionConnection({
    required this.id,
    required this.directionId,
    required this.entryId,
    required this.createdAt,
  });
}

/// Hive adapter for DirectionConnection
class DirectionConnectionAdapter extends TypeAdapter<DirectionConnection> {
  @override
  final int typeId = 6;

  @override
  DirectionConnection read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return DirectionConnection(
      id: fields[0] as String,
      directionId: fields[1] as String,
      entryId: fields[2] as String,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DirectionConnection obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.directionId)
      ..writeByte(2)
      ..write(obj.entryId)
      ..writeByte(3)
      ..write(obj.createdAt);
  }
}
