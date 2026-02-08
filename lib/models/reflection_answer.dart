import 'package:hive/hive.dart';

class ReflectionAnswer {
  ReflectionAnswer({
    required this.id,
    required this.entryId,
    required this.questionId,
    required this.questionText,
    required this.answer,
    required this.createdAt,
  });

  final String id;
  final String entryId;
  final String questionId;
  final String questionText;
  final String answer;
  final DateTime createdAt;
}

class ReflectionAnswerAdapter extends TypeAdapter<ReflectionAnswer> {
  @override
  final int typeId = 2;

  @override
  ReflectionAnswer read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return ReflectionAnswer(
      id: fields[0] as String,
      entryId: fields[1] as String,
      questionId: fields[2] as String,
      questionText: fields[3] as String,
      answer: fields[4] as String,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ReflectionAnswer obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entryId)
      ..writeByte(2)
      ..write(obj.questionId)
      ..writeByte(3)
      ..write(obj.questionText)
      ..writeByte(4)
      ..write(obj.answer)
      ..writeByte(5)
      ..write(obj.createdAt);
  }
}
