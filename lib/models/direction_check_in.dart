import 'package:hive/hive.dart';

/// A goal/direction that was present during a saved mood entry.
class DirectionCheckIn {
  final String id;
  final String directionId;
  final String entryId;
  final String? stepText;
  final String? blockerText;
  final String? supportText;
  final String? reflectionAnswerId;
  final DateTime createdAt;

  DirectionCheckIn({
    required this.id,
    required this.directionId,
    required this.entryId,
    this.stepText,
    this.blockerText,
    this.supportText,
    this.reflectionAnswerId,
    required this.createdAt,
  });

  bool get hasStep => (stepText ?? '').trim().isNotEmpty;
  bool get hasBlocker => (blockerText ?? '').trim().isNotEmpty;

  DirectionCheckIn copyWith({
    String? stepText,
    String? blockerText,
    String? supportText,
    String? reflectionAnswerId,
  }) {
    return DirectionCheckIn(
      id: id,
      directionId: directionId,
      entryId: entryId,
      stepText: stepText ?? this.stepText,
      blockerText: blockerText ?? this.blockerText,
      supportText: supportText ?? this.supportText,
      reflectionAnswerId: reflectionAnswerId ?? this.reflectionAnswerId,
      createdAt: createdAt,
    );
  }
}

/// In-memory draft passed through the check-in flow before the entry exists.
class DirectionCheckInDraft {
  final String directionId;
  final String directionTitle;
  final String? stepText;
  final String? blockerText;
  final String? supportText;
  final bool wantsReflection;

  const DirectionCheckInDraft({
    required this.directionId,
    required this.directionTitle,
    this.stepText,
    this.blockerText,
    this.supportText,
    this.wantsReflection = false,
  });

  bool get hasStep => (stepText ?? '').trim().isNotEmpty;
  bool get hasBlocker => (blockerText ?? '').trim().isNotEmpty;
}

class DirectionCheckInAdapter extends TypeAdapter<DirectionCheckIn> {
  @override
  final int typeId = 8;

  @override
  DirectionCheckIn read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return DirectionCheckIn(
      id: fields[0] as String,
      directionId: fields[1] as String,
      entryId: fields[2] as String,
      stepText: fields[3] as String?,
      blockerText: fields[4] as String?,
      supportText: fields[5] as String?,
      reflectionAnswerId: fields[6] as String?,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DirectionCheckIn obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.directionId)
      ..writeByte(2)
      ..write(obj.entryId)
      ..writeByte(3)
      ..write(obj.stepText)
      ..writeByte(4)
      ..write(obj.blockerText)
      ..writeByte(5)
      ..write(obj.supportText)
      ..writeByte(6)
      ..write(obj.reflectionAnswerId)
      ..writeByte(7)
      ..write(obj.createdAt);
  }
}
