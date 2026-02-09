import 'package:hive/hive.dart';

class Entry {
  Entry({
    required this.id,
    required this.moodValue,
    required this.moodWord,
    required this.intention,
    required this.createdAt,
    this.reflectionAnswerIds,
  });

  final String id;
  final double moodValue;
  final String moodWord;
  final String intention;
  final DateTime createdAt;
  final List<String>? reflectionAnswerIds;
}

/// Extension for Entry utilities
extension EntryExtension on Entry {
  /// Get mood emoji derived from moodValue
  String get moodEmoji {
    if (moodValue >= 0.8) return '😊';
    if (moodValue >= 0.6) return '😌';
    if (moodValue >= 0.4) return '😐';
    if (moodValue >= 0.2) return '😔';
    return '😢';
  }
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
      reflectionAnswerIds: fields[5] as List<String>?,
    );
  }

  @override
  void write(BinaryWriter writer, Entry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.moodValue)
      ..writeByte(2)
      ..write(obj.moodWord)
      ..writeByte(3)
      ..write(obj.intention)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.reflectionAnswerIds);
  }
}
