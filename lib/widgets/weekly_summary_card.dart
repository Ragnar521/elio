import 'package:flutter/material.dart';

import '../models/weekly_summary.dart';
import '../theme/elio_colors.dart';

class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({
    super.key,
    required this.summary,
    required this.onTap,
    required this.onDismiss,
  });

  final WeeklySummary summary;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  String _moodWordForAvg(double avgMood) {
    if (avgMood < 0.14) return 'Heavy';
    if (avgMood < 0.28) return 'Tired';
    if (avgMood < 0.42) return 'Flat';
    if (avgMood < 0.56) return 'Okay';
    if (avgMood < 0.70) return 'Calm';
    if (avgMood < 0.84) return 'Good';
    if (avgMood < 0.90) return 'Energized';
    return 'Great';
  }

  @override
  Widget build(BuildContext context) {
    final moodWord = _moodWordForAvg(summary.avgMood);
    final takeawayPreview = summary.takeaway.length > 60
        ? '${summary.takeaway.substring(0, 60)}...'
        : summary.takeaway;

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
              color: ElioColors.darkAccent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Weekly Recap',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.6),
                        fontSize: 12,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  summary.weekLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.6),
                        fontSize: 12,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: ElioColors.darkPrimaryText.withOpacity(0.6),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${summary.checkInCount} check-ins · avg $moodWord',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ElioColors.darkPrimaryText,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              takeawayPreview,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ElioColors.darkPrimaryText.withOpacity(0.7),
                    fontSize: 13,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
