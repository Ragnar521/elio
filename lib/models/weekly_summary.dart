import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class WeeklySummary {
  WeeklySummary({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.checkInCount,
    required this.daysWithEntries,
    required this.avgMood,
    required this.moodTrend,
    required this.mostFeltMood,
    this.bestMoodDay,
    this.bestMoodValue,
    this.bestMoodWord,
    this.directionSummaries,
    this.topDirectionId,
    this.standoutReflectionAnswers,
    required this.takeaway,
    required this.createdAt,
    this.viewedAt,
  });

  final String id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int checkInCount;
  final int daysWithEntries;
  final double avgMood;
  final String moodTrend; // 'up', 'down', 'stable'
  final String mostFeltMood;
  final String? bestMoodDay;
  final double? bestMoodValue;
  final String? bestMoodWord;
  final List<Map<String, dynamic>>? directionSummaries;
  final String? topDirectionId;
  final List<Map<String, dynamic>>? standoutReflectionAnswers;
  final String takeaway;
  final DateTime createdAt;
  final DateTime? viewedAt;

  /// Check if the summary has been viewed
  bool get hasBeenViewed => viewedAt != null;

  /// Get formatted week label (e.g., "Feb 17 - Feb 23")
  String get weekLabel {
    final startFormat = DateFormat('MMM d');
    final endFormat = DateFormat('MMM d');
    return '${startFormat.format(weekStart)} - ${endFormat.format(weekEnd.subtract(const Duration(days: 1)))}';
  }

  /// Check if summary has direction data
  bool get hasDirections => directionSummaries != null && directionSummaries!.isNotEmpty;

  /// Check if summary has reflection highlights
  bool get hasReflections => standoutReflectionAnswers != null && standoutReflectionAnswers!.isNotEmpty;
}

class WeeklySummaryAdapter extends TypeAdapter<WeeklySummary> {
  @override
  final int typeId = 7;

  @override
  WeeklySummary read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return WeeklySummary(
      id: fields[0] as String,
      weekStart: fields[1] as DateTime,
      weekEnd: fields[2] as DateTime,
      checkInCount: fields[3] as int,
      daysWithEntries: fields[4] as int,
      avgMood: fields[5] as double,
      moodTrend: fields[6] as String,
      mostFeltMood: fields[7] as String,
      bestMoodDay: fields[8] as String?,
      bestMoodValue: fields[9] as double?,
      bestMoodWord: fields[10] as String?,
      directionSummaries: (fields[11] as List?)?.cast<Map<String, dynamic>>(),
      topDirectionId: fields[12] as String?,
      standoutReflectionAnswers: (fields[13] as List?)?.cast<Map<String, dynamic>>(),
      takeaway: fields[14] as String,
      createdAt: fields[15] as DateTime,
      viewedAt: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklySummary obj) {
    writer
      ..writeByte(17) // field count
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.weekStart)
      ..writeByte(2)
      ..write(obj.weekEnd)
      ..writeByte(3)
      ..write(obj.checkInCount)
      ..writeByte(4)
      ..write(obj.daysWithEntries)
      ..writeByte(5)
      ..write(obj.avgMood)
      ..writeByte(6)
      ..write(obj.moodTrend)
      ..writeByte(7)
      ..write(obj.mostFeltMood)
      ..writeByte(8)
      ..write(obj.bestMoodDay)
      ..writeByte(9)
      ..write(obj.bestMoodValue)
      ..writeByte(10)
      ..write(obj.bestMoodWord)
      ..writeByte(11)
      ..write(obj.directionSummaries)
      ..writeByte(12)
      ..write(obj.topDirectionId)
      ..writeByte(13)
      ..write(obj.standoutReflectionAnswers)
      ..writeByte(14)
      ..write(obj.takeaway)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.viewedAt);
  }
}
