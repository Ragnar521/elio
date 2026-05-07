import 'package:hive/hive.dart';

/// Direction types representing life areas
enum DirectionType { career, health, relationships, growth, peace, creativity }

/// Extension for DirectionType utilities
extension DirectionTypeExtension on DirectionType {
  String get iconAsset {
    switch (this) {
      case DirectionType.career:
        return 'assets/direction_icons/career.png';
      case DirectionType.health:
        return 'assets/direction_icons/health.png';
      case DirectionType.relationships:
        return 'assets/direction_icons/relationships.png';
      case DirectionType.growth:
        return 'assets/direction_icons/growth.png';
      case DirectionType.peace:
        return 'assets/direction_icons/peace.png';
      case DirectionType.creativity:
        return 'assets/direction_icons/creativity.png';
    }
  }

  String get label {
    switch (this) {
      case DirectionType.career:
        return 'Career';
      case DirectionType.health:
        return 'Health';
      case DirectionType.relationships:
        return 'Relationships';
      case DirectionType.growth:
        return 'Growth';
      case DirectionType.peace:
        return 'Peace';
      case DirectionType.creativity:
        return 'Creativity';
    }
  }

  /// Example prompts for this direction type
  List<String> get examples {
    switch (this) {
      case DirectionType.career:
        return [
          'Find work that energizes me',
          'Build skills I\'m proud of',
          'Create more than I consume',
        ];
      case DirectionType.health:
        return [
          'Feel strong and rested',
          'Move my body daily',
          'Sleep better, stress less',
        ];
      case DirectionType.relationships:
        return [
          'Be more present with family',
          'Nurture meaningful friendships',
          'Listen more, react less',
        ];
      case DirectionType.growth:
        return [
          'Learn something new regularly',
          'Read more, scroll less',
          'Step outside comfort zone',
        ];
      case DirectionType.peace:
        return [
          'Worry less about what I can\'t control',
          'Find calm in busy days',
          'Let go of perfectionism',
        ];
      case DirectionType.creativity:
        return [
          'Make time for creative expression',
          'Start projects I\'ve postponed',
          'Play more, plan less',
        ];
    }
  }

  /// Reflection questions for this direction type
  List<String> get reflectionQuestions {
    switch (this) {
      case DirectionType.career:
        return [
          'Did today move you closer to work that energizes you?',
          'What would make tomorrow better at work?',
        ];
      case DirectionType.health:
        return [
          'How did your body feel today?',
          'What\'s one thing you did for your energy today?',
        ];
      case DirectionType.relationships:
        return [
          'Who mattered most today?',
          'How present were you with the people around you?',
        ];
      case DirectionType.growth:
        return [
          'What did you learn or try today?',
          'What challenged you in a good way?',
        ];
      case DirectionType.peace:
        return ['What did you let go of today?', 'Where did you find calm?'];
      case DirectionType.creativity:
        return ['Did you make something today?', 'What inspired you?'];
    }
  }
}

/// A life direction the user wants to be aware of
class Direction {
  final String id;
  final String title; // max 50 chars
  final String? description;
  final String? subtasks;
  final String? actionItems;
  final String? blockers;
  final String? supportIdeas;
  final DirectionType type;
  final bool reflectionEnabled; // show questions during check-in
  final bool isArchived;
  final DateTime createdAt;

  Direction({
    required this.id,
    required this.title,
    this.description = '',
    this.subtasks = '',
    this.actionItems = '',
    this.blockers = '',
    this.supportIdeas = '',
    required this.type,
    required this.reflectionEnabled,
    this.isArchived = false,
    required this.createdAt,
  });

  /// Generated icon asset for this direction type.
  String get iconAsset => type.iconAsset;

  /// Create a copy with updated fields
  Direction copyWith({
    String? title,
    String? description,
    String? subtasks,
    String? actionItems,
    String? blockers,
    String? supportIdeas,
    DirectionType? type,
    bool? reflectionEnabled,
    bool? isArchived,
  }) {
    return Direction(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      subtasks: subtasks ?? this.subtasks,
      actionItems: actionItems ?? this.actionItems,
      blockers: blockers ?? this.blockers,
      supportIdeas: supportIdeas ?? this.supportIdeas,
      type: type ?? this.type,
      reflectionEnabled: reflectionEnabled ?? this.reflectionEnabled,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
    );
  }
}

/// Hive adapter for DirectionType
class DirectionTypeAdapter extends TypeAdapter<DirectionType> {
  @override
  final int typeId = 4;

  @override
  DirectionType read(BinaryReader reader) {
    return DirectionType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, DirectionType obj) {
    writer.writeByte(obj.index);
  }
}

/// Hive adapter for Direction
class DirectionAdapter extends TypeAdapter<Direction> {
  @override
  final int typeId = 5;

  @override
  Direction read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return Direction(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as DirectionType,
      reflectionEnabled: fields[3] as bool,
      isArchived: fields[4] as bool? ?? false,
      createdAt: fields[5] as DateTime,
      description: fields[6] as String? ?? '',
      subtasks: fields[7] as String? ?? '',
      actionItems: fields[8] as String? ?? '',
      blockers: fields[9] as String? ?? '',
      supportIdeas: fields[10] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Direction obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.reflectionEnabled)
      ..writeByte(4)
      ..write(obj.isArchived)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.description ?? '')
      ..writeByte(7)
      ..write(obj.subtasks ?? '')
      ..writeByte(8)
      ..write(obj.actionItems ?? '')
      ..writeByte(9)
      ..write(obj.blockers ?? '')
      ..writeByte(10)
      ..write(obj.supportIdeas ?? '');
  }
}
