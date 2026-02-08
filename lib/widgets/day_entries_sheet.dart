import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../screens/entry_detail_screen.dart';
import '../theme/elio_colors.dart';

class DayEntriesSheet extends StatelessWidget {
  const DayEntriesSheet({
    super.key,
    required this.dayName,
    required this.entries,
    required this.averageMood,
  });

  final String dayName;
  final List<Entry> entries;
  final double averageMood;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ElioColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ElioColors.darkPrimaryText.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dayName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: ElioColors.darkPrimaryText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ElioColors.darkSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${averageMood.toStringAsFixed(2)} avg',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ElioColors.darkAccent,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'} found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Entries list
          Flexible(
            child: entries.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: entries.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildEntryCard(context, entries[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: 48,
            color: ElioColors.darkPrimaryText.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No entries for this day',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ElioColors.darkPrimaryText.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, Entry entry) {
    final moodColor = _moodColor(entry.moodValue);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EntryDetailScreen(
              entry: entry,
              timeLabel: _timeLabel(entry.createdAt),
              dateLabel: _dateLabel(entry.createdAt),
              moodColor: moodColor,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ElioColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: moodColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _dateLabel(entry.createdAt),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.7),
                      ),
                ),
                const Spacer(),
                Text(
                  _timeLabel(entry.createdAt),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.5),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.moodWord,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ElioColors.darkPrimaryText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.intention,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ElioColors.darkPrimaryText.withOpacity(0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }

  String _dateLabel(DateTime date) {
    final today = _dateOnly(DateTime.now());
    final target = _dateOnly(date);
    final difference = today.difference(target).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';

    final month = _monthName(date.month);
    if (date.year == today.year) {
      return '$month ${date.day}';
    }
    return '$month ${date.day}, ${date.year}';
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  Color _moodColor(double value) {
    const low = Color(0xFF4B5A68);
    const high = ElioColors.darkAccent;
    return Color.lerp(low, high, value) ?? high;
  }
}
