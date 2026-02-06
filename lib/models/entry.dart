import 'package:hive/hive.dart';

class Entry {
  Entry({
    required this.id,
    required this.moodValue,
    required this.moodWord,
    required this.intention,
    required this.createdAt,
  });

  final String id;
  final double moodValue;
  final String moodWord;
  final String intention;
  final DateTime createdAt;
}

class EntryAdapter extends TypeAdapter<Entry> {
  @override
  final int typeId = 0;

  @override
  Entry read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return Entry(
      id: fields[0] as String,
      moodValue: fields[1] as double,
      moodWord: fields[2] as String,
      intention: fields[3] as String,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Entry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.moodValue)
      ..writeByte(2)
      ..write(obj.moodWord)
      ..writeByte(3)
      ..write(obj.intention)
      ..writeByte(4)
      ..write(obj.createdAt);
  }
}
