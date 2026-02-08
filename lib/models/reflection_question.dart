import 'package:hive/hive.dart';

class ReflectionQuestion {
  ReflectionQuestion({
    required this.id,
    required this.text,
    required this.category,
    required this.isCustom,
    required this.isFavorite,
    required this.isSelected,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String category;
  final bool isCustom;
  final bool isFavorite;
  final bool isSelected;
  final DateTime createdAt;

  ReflectionQuestion copyWith({
    String? id,
    String? text,
    String? category,
    bool? isCustom,
    bool? isFavorite,
    bool? isSelected,
    DateTime? createdAt,
  }) {
    return ReflectionQuestion(
      id: id ?? this.id,
      text: text ?? this.text,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
      isFavorite: isFavorite ?? this.isFavorite,
      isSelected: isSelected ?? this.isSelected,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ReflectionQuestionAdapter extends TypeAdapter<ReflectionQuestion> {
  @override
  final int typeId = 1;

  @override
  ReflectionQuestion read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return ReflectionQuestion(
      id: fields[0] as String,
      text: fields[1] as String,
      category: fields[2] as String,
      isCustom: fields[3] as bool,
      isFavorite: fields[4] as bool,
      isSelected: fields[5] as bool,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ReflectionQuestion obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.isCustom)
      ..writeByte(4)
      ..write(obj.isFavorite)
      ..writeByte(5)
      ..write(obj.isSelected)
      ..writeByte(6)
      ..write(obj.createdAt);
  }
}
