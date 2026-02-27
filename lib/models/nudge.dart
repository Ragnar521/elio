enum NudgeType { dormantDirection, moodPattern, streakCelebration }

class Nudge {
  final String id;
  final NudgeType type;
  final String message;
  final String? actionText; // e.g., "Reconnect →"
  final String? directionId; // For navigation to DirectionDetailScreen

  const Nudge({
    required this.id,
    required this.type,
    required this.message,
    this.actionText,
    this.directionId,
  });
}
