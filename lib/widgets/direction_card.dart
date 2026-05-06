import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../models/direction_stats.dart';
import 'animated_tap.dart';
import 'direction_icon.dart';

class DirectionCard extends StatelessWidget {
  final Direction direction;
  final DirectionStats stats;
  final VoidCallback onTap;

  const DirectionCard({
    super.key,
    required this.direction,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTap(
      onTap: onTap,
      pressScale: 0.98,
      enableHaptic: true,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  DirectionIcon(type: direction.type, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      direction.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),

              const SizedBox(height: 12),

              // Stats row
              Text(
                '${stats.totalConnections} connections',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 8),

              // Monthly progress
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: stats.monthlyProgress,
                      backgroundColor: Theme.of(context).dividerColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${stats.monthlyConnections} this month',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),

              // Mood correlation (if data available)
              if (stats.totalConnections >= 3) ...[
                const SizedBox(height: 8),
                Text(
                  'Avg mood: ${stats.avgMoodWhenConnected.toStringAsFixed(2)} ${_getMoodLabel(stats.avgMoodWhenConnected)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],

              // Reflection indicator
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.edit_note, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Reflection questions: ${direction.reflectionEnabled ? "On" : "Off"}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMoodLabel(double value) {
    if (value >= 0.8) return 'excellent';
    if (value >= 0.6) return 'good';
    if (value >= 0.4) return 'steady';
    if (value >= 0.2) return 'low';
    return 'very low';
  }
}
