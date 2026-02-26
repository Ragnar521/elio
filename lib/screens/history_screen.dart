import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../services/storage_service.dart';
import '../theme/elio_colors.dart';
import '../widgets/entry_card.dart';
import 'entry_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<_HistoryData> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadData();
  }

  Future<_HistoryData> _loadData() async {
    final entries = await StorageService.instance.getAllEntries();
    final streak = await StorageService.instance.getCurrentStreak();
    return _HistoryData(entries: entries, streak: streak);
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _loadData();
    });
    await _historyFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_HistoryData>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data;
            final entries = data?.entries ?? [];
            final streak = data?.streak ?? 0;

            return RefreshIndicator(
              color: ElioColors.darkAccent,
              backgroundColor: ElioColors.darkSurface,
              onRefresh: _refresh,
              child: entries.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                      children: [
                        Text(
                          'History',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No check-ins yet',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.7)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your journey starts with one moment.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.6)),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      children: [
                        Text(
                          'Your Journey',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          streak > 0 ? '$streak day streak' : '${entries.length} check-ins',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.7)),
                        ),
                        const SizedBox(height: 24),
                        ..._buildEntrySections(entries),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildEntrySections(List<Entry> entries) {
    final widgets = <Widget>[];
    DateTime? currentDay;

    for (final entry in entries) {
      final entryDay = _dateOnly(entry.createdAt);
      if (currentDay == null || currentDay != entryDay) {
        currentDay = entryDay;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _dateLabel(entry.createdAt),
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.85)),
            ),
          ),
        );
      }

      widgets.add(
        EntryCard(
          entry: entry,
          timeLabel: _timeLabel(entry.createdAt),
          dateLabel: _dateLabel(entry.createdAt),
          moodColor: _moodIndicator(entry.moodValue),
          onTap: () async {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => EntryDetailScreen(
                  entry: entry,
                  timeLabel: _timeLabel(entry.createdAt),
                  dateLabel: _dateLabel(entry.createdAt),
                  moodColor: _moodIndicator(entry.moodValue),
                  onUndoDelete: () {
                    // Refresh history when undo is tapped
                    setState(() {
                      _historyFuture = _loadData();
                    });
                  },
                ),
              ),
            );
            // Always reload on return from detail (handles edits, deletes, and undos)
            setState(() {
              _historyFuture = _loadData();
            });
          },
        ),
      );
    }

    return widgets;
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  String _dateLabel(DateTime date) {
    final today = _dateOnly(DateTime.now());
    final target = _dateOnly(date);
    final difference = today.difference(target).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return _weekdayName(date.weekday);

    final month = _monthName(date.month);
    if (date.year == today.year) {
      return '$month ${date.day}';
    }
    return '$month ${date.day}, ${date.year}';
  }

  String _timeLabel(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }

  String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  Color _moodIndicator(double value) {
    const low = Color(0xFF4B5A68);
    const high = ElioColors.darkAccent;
    return Color.lerp(low, high, value) ?? high;
  }
}

class _HistoryData {
  _HistoryData({required this.entries, required this.streak});

  final List<Entry> entries;
  final int streak;
}
