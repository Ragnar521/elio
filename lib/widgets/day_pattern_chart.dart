import 'package:flutter/material.dart';

import '../theme/elio_colors.dart';

class DayPatternChart extends StatelessWidget {
  const DayPatternChart({
    super.key,
    required this.pattern,
    this.bestDay,
    this.worstDay,
    this.onDayTap,
  });

  final Map<int, double> pattern;
  final int? bestDay;
  final int? worstDay;
  final Function(int dayOfWeek)? onDayTap;

  static const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    if (pattern.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR WEEK PATTERN',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: ElioColors.darkPrimaryText.withOpacity(0.6),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(7, (index) {
          final day = index + 1; // 1-7 (Monday-Sunday)
          final value = pattern[day] ?? 0.0;
          return _buildDayRow(
            context,
            dayNames[index],
            day,
            value,
            isBest: day == bestDay,
            isWorst: day == worstDay,
          );
        }),
      ],
    );
  }

  Widget _buildDayRow(
    BuildContext context,
    String day,
    int dayIndex,
    double value, {
    required bool isBest,
    required bool isWorst,
  }) {
    final hasTapHandler = onDayTap != null;

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Day label
          SizedBox(
            width: 36,
            child: Text(
              day,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ElioColors.darkPrimaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Bar
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: ElioColors.darkSurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: ElioColors.darkAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Value
          SizedBox(
            width: 40,
            child: Text(
              value.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ElioColors.darkPrimaryText.withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Marker or chevron
          SizedBox(
            width: 24,
            child: isBest || isWorst
                ? Icon(
                    isBest ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: isBest
                        ? const Color(0xFF4CAF50)
                        : ElioColors.darkAccent,
                  )
                : (hasTapHandler
                      ? Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: ElioColors.darkPrimaryText.withOpacity(0.4),
                        )
                      : const SizedBox.shrink()),
          ),
        ],
      ),
    );

    if (!hasTapHandler || value == 0) {
      return content;
    }

    return InkWell(
      onTap: () => onDayTap!(dayIndex),
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }
}
