import 'package:flutter/material.dart';

import '../models/nudge.dart';
import '../theme/elio_colors.dart';

class NudgeCard extends StatelessWidget {
  const NudgeCard({
    super.key,
    required this.nudge,
    required this.onDismiss,
    this.onTap,
  });

  final Nudge nudge;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  IconData _iconForType(NudgeType type) {
    switch (type) {
      case NudgeType.streakCelebration:
        return Icons.local_fire_department_outlined;
      case NudgeType.dormantDirection:
        return Icons.explore_outlined;
      case NudgeType.moodPattern:
        return Icons.insights_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ElioColors.darkSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border(
            left: BorderSide(
              color: ElioColors.darkAccent.withOpacity(0.6),
              width: 3,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Icon(
              _iconForType(nudge.type),
              size: 20,
              color: ElioColors.darkPrimaryText.withOpacity(0.7),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nudge.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ElioColors.darkPrimaryText,
                        ),
                  ),
                  if (nudge.actionText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      nudge.actionText!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ElioColors.darkAccent.withOpacity(0.8),
                            fontSize: 12,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            // Close button
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: ElioColors.darkPrimaryText.withOpacity(0.6),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
