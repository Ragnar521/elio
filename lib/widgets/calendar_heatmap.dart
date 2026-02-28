import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../theme/elio_colors.dart';

class CalendarHeatmap extends StatelessWidget {
  const CalendarHeatmap({
    super.key,
    required this.month,
    required this.entriesByDate,
    required this.onDayTap,
    required this.onMonthChanged,
    this.selectedDate,
    this.canNavigateBack = true,
    this.canNavigateForward = true,
  });

  final DateTime month;
  final Map<DateTime, List<Entry>> entriesByDate;
  final Function(DateTime date, List<Entry> entries) onDayTap;
  final Function(int offset) onMonthChanged;
  final DateTime? selectedDate;
  final bool canNavigateBack;
  final bool canNavigateForward;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Month navigation header
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              color: canNavigateBack
                  ? ElioColors.darkPrimaryText
                  : ElioColors.darkPrimaryText.withOpacity(0.3),
              onPressed: canNavigateBack ? () => onMonthChanged(-1) : null,
            ),
            Expanded(
              child: Text(
                _monthLabel(month),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ElioColors.darkPrimaryText,
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              color: canNavigateForward
                  ? ElioColors.darkPrimaryText
                  : ElioColors.darkPrimaryText.withOpacity(0.3),
              onPressed: canNavigateForward ? () => onMonthChanged(1) : null,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. Weekday labels row
        Row(
          children: [
            for (final day in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ElioColors.darkPrimaryText.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // 3. Calendar grid with swipe gestures
        GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 200) return;
            if (velocity < 0 && canNavigateForward) onMonthChanged(1);
            if (velocity > 0 && canNavigateBack) onMonthChanged(-1);
          },
          child: Column(
            children: _buildCalendarRows(context),
          ),
        ),

        // 4. Color legend
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Low',
              style: TextStyle(
                fontSize: 11,
                color: ElioColors.darkPrimaryText.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 120,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4B5A68),
                    Color(0xFFFF6436),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'High',
              style: TextStyle(
                fontSize: 11,
                color: ElioColors.darkPrimaryText.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build calendar grid as rows of 7 days each
  List<Widget> _buildCalendarRows(BuildContext context) {
    final days = _buildCalendarDays(month);
    final rows = <Widget>[];

    for (int i = 0; i < days.length; i += 7) {
      final rowDays = days.sublist(i, i + 7);
      rows.add(
        Row(
          children: rowDays
              .map((date) => Expanded(child: _buildDayCell(context, date)))
              .toList(),
        ),
      );
      // Add spacing between rows (except after last row)
      if (i + 7 < days.length) {
        rows.add(const SizedBox(height: 4));
      }
    }

    return rows;
  }

  /// Build list of dates for the month, including leading/trailing null cells
  List<DateTime?> _buildCalendarDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime?>[];

    // Add leading empty cells (Monday = 1, Sunday = 7)
    final leadingEmpties = firstDay.weekday - 1;
    for (int i = 0; i < leadingEmpties; i++) {
      days.add(null);
    }

    // Add all days of the month
    for (int day = 1; day <= lastDay.day; day++) {
      days.add(DateTime(month.year, month.month, day));
    }

    // Add trailing empty cells to complete the grid
    while (days.length % 7 != 0) {
      days.add(null);
    }

    return days;
  }

  /// Build a single day cell
  Widget _buildDayCell(BuildContext context, DateTime? date) {
    // Empty cell
    if (date == null) {
      return const SizedBox.shrink();
    }

    // Normalize date to midnight for lookup
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final entries = entriesByDate[normalizedDate] ?? [];
    final hasEntries = entries.isNotEmpty;

    // Calculate average mood for days with multiple entries
    final avgMood = hasEntries
        ? entries.fold(0.0, (sum, e) => sum + e.moodValue) / entries.length
        : 0.0;

    // Determine states
    final today = DateTime.now();
    final isToday = _isSameDay(date, today);
    final isSelected =
        selectedDate != null && _isSameDay(date, selectedDate!);

    // Visual properties
    final backgroundColor = hasEntries
        ? _moodColor(avgMood)
        : ElioColors.darkSurface.withOpacity(0.3);

    final border = isToday && isSelected
        ? Border.all(color: ElioColors.darkAccent, width: 2.5)
        : isToday
            ? Border.all(color: ElioColors.darkAccent, width: 2)
            : isSelected
                ? Border.all(color: ElioColors.darkAccent, width: 1.5)
                : null;

    final textColor = hasEntries
        ? Colors.white
        : ElioColors.darkPrimaryText.withOpacity(0.35);

    final textWeight = isToday ? FontWeight.w700 : FontWeight.w400;

    return GestureDetector(
      onTap: hasEntries ? () => onDayTap(date, entries) : null,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: textWeight,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Calculate mood color using gradient
  Color _moodColor(double value) {
    const low = Color(0xFF4B5A68);
    const high = Color(0xFFFF6436);
    return Color.lerp(low, high, value) ?? high;
  }

  /// Format month label
  String _monthLabel(DateTime month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[month.month - 1]} ${month.year}';
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
