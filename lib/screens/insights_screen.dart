import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../services/insights_service.dart';
import '../services/storage_service.dart';
import '../theme/elio_colors.dart';
import '../widgets/insight_card.dart';
import '../widgets/mood_wave.dart';
import '../widgets/stat_card.dart';
import 'mood_entry_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late Future<_InsightsBaseData> _future;
  InsightsPeriod _period = InsightsPeriod.week;
  int _offset = 0;
  bool _useSampleData = false;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_InsightsBaseData> _loadData() async {
    final entries = await StorageService.instance.getAllEntries();
    final streak = await StorageService.instance.getCurrentStreak();
    final totalCount = await StorageService.instance.getEntryCount();
    return _InsightsBaseData(entries: entries, streak: streak, totalCount: totalCount);
  }

  void _setPeriod(InsightsPeriod period) {
    if (_period == period) return;
    setState(() {
      _period = period;
      _offset = 0;
    });
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return;
    if (velocity < 0) {
      setState(() => _offset -= 1);
    } else {
      setState(() => _offset = (_offset + 1).clamp(-1000, 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_InsightsBaseData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final base = snapshot.data;
            final entries = _useSampleData
                ? _buildSampleEntries(DateTime.now())
                : (base?.entries ?? <Entry>[]);
            final streak = _useSampleData
                ? _calculateStreak(entries)
                : (base?.streak ?? 0);
            final totalCount = _useSampleData ? entries.length : (base?.totalCount ?? 0);

            final data = InsightsService.buildSnapshot(
              now: DateTime.now(),
              allEntries: entries,
              period: _period,
              offset: _offset,
              streak: streak,
            );

            if (totalCount < 3) {
              return _buildEmptyState(
                context,
                title: 'Keep checking in.',
                subtitle: 'After a few entries, you\'ll start seeing patterns here.',
              );
            }

            if (data.entries.isEmpty) {
              final label = _period == InsightsPeriod.week ? 'week' : 'month';
              return _buildEmptyState(
                context,
                title: 'No check-ins this $label yet.',
                subtitle: 'Your first one could be now.',
              );
            }

            return GestureDetector(
              onHorizontalDragEnd: _onSwipe,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Insights',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      _SampleToggle(
                        enabled: _useSampleData,
                        onTap: () {
                          setState(() => _useSampleData = !_useSampleData);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildToggle(context),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      _periodLabel(data.periodStart, data.periodEnd, _period),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.7)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  MoodWave(
                    entries: data.entries,
                    periodStart: data.periodStart,
                    daysInPeriod: data.daysInPeriod,
                  ),
                  const SizedBox(height: 10),
                  _buildAxisLabels(context, data.daysInPeriod),
                  const SizedBox(height: 24),
                  InsightCard(text: data.insightText),
                  const SizedBox(height: 18),
                  _buildStatsRow(context, data),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ElioColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: 'Week',
              selected: _period == InsightsPeriod.week,
              onTap: () => _setPeriod(InsightsPeriod.week),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: 'Month',
              selected: _period == InsightsPeriod.month,
              onTap: () => _setPeriod(InsightsPeriod.month),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAxisLabels(BuildContext context, int daysInPeriod) {
    final labels = _period == InsightsPeriod.week
        ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : _monthAxisLabels(daysInPeriod);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels
          .map(
            (label) => Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.5)),
            ),
          )
          .toList(),
    );
  }

  List<String> _monthAxisLabels(int daysInPeriod) {
    final values = <int>{1, 5, 10, 15, 20, 25, daysInPeriod};
    final sorted = values.toList()..sort();
    return sorted.map((value) => value.toString()).toList();
  }

  Widget _buildStatsRow(BuildContext context, InsightsSnapshot data) {
    final cards = _period == InsightsPeriod.week
        ? [
            StatCard(value: data.checkInCount.toString(), label: 'check-ins'),
            StatCard(value: data.streak.toString(), label: 'day streak'),
            StatCard(value: data.mostFelt, label: 'most felt'),
          ]
        : [
            StatCard(value: data.checkInCount.toString(), label: 'check-ins'),
            StatCard(value: _daysPercent(data.daysWithEntries, data.daysInPeriod), label: 'of days'),
            StatCard(value: data.mostFelt, label: 'most felt'),
          ];

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
        const SizedBox(width: 12),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Insights',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            _SampleToggle(
              enabled: _useSampleData,
              onTap: () {
                setState(() => _useSampleData = !_useSampleData);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.85)),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.6)),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ElioColors.darkAccent,
            foregroundColor: ElioColors.darkBackground,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MoodEntryScreen()),
            );
          },
          child: const Text('Check In'),
        ),
      ],
    );
  }

  String _periodLabel(DateTime start, DateTime end, InsightsPeriod period) {
    if (period == InsightsPeriod.month) {
      final month = _monthName(start.month, full: true);
      return '$month ${start.year}';
    }
    final endDay = end.subtract(const Duration(days: 1));
    final startMonth = _monthName(start.month, full: false);
    final endMonth = _monthName(endDay.month, full: false);
    if (start.month == endDay.month) {
      return '$startMonth ${start.day} - ${endDay.day}';
    }
    return '$startMonth ${start.day} - $endMonth ${endDay.day}';
  }

  String _monthName(int month, {required bool full}) {
    const short = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const long = [
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
    return full ? long[month - 1] : short[month - 1];
  }

  String _daysPercent(int daysWithEntries, int daysInPeriod) {
    if (daysInPeriod == 0) return '0%';
    final percent = (daysWithEntries / daysInPeriod * 100).round();
    return '$percent%';
  }

  List<Entry> _buildSampleEntries(DateTime now) {
    final moods = ['Calm', 'Hopeful', 'Tired', 'Focused', 'Gentle', 'Bright', 'Grounded'];
    final intentions = [
      'Focus on one task',
      'Take a slow morning',
      'Go for a short walk',
      'Reach out to a friend',
      'Give myself permission to rest',
      'Keep the day simple',
      'Notice what helps',
    ];
    final entries = <Entry>[];
    var id = 0;
    for (var i = 0; i < 35; i += 1) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      if (i % 6 == 0) continue;
      final baseMood = 0.25 + (i % 5) * 0.15;
      entries.add(
        Entry(
          id: 'sample-${id++}',
          moodValue: baseMood.clamp(0.05, 0.95),
          moodWord: moods[i % moods.length],
          intention: intentions[i % intentions.length],
          createdAt: day.add(const Duration(hours: 20, minutes: 15)),
        ),
      );
      if (i % 7 == 0) {
        entries.add(
          Entry(
            id: 'sample-${id++}',
            moodValue: (baseMood + 0.12).clamp(0.05, 0.95),
            moodWord: moods[(i + 2) % moods.length],
            intention: intentions[(i + 3) % intentions.length],
            createdAt: day.add(const Duration(hours: 9, minutes: 40)),
          ),
        );
      }
    }
    return entries;
  }

  int _calculateStreak(List<Entry> entries) {
    if (entries.isEmpty) return 0;
    final days = <DateTime>{};
    for (final entry in entries) {
      days.add(DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day));
    }
    var streak = 0;
    var current = DateTime.now();
    current = DateTime(current.year, current.month, current.day);
    while (days.contains(current)) {
      streak += 1;
      current = current.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

class _SampleToggle extends StatelessWidget {
  const _SampleToggle({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: enabled ? ElioColors.darkAccent : ElioColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          enabled ? 'Sample On' : 'Sample',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: enabled ? ElioColors.darkBackground : ElioColors.darkPrimaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ElioColors.darkAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? ElioColors.darkBackground : ElioColors.darkPrimaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

class _InsightsBaseData {
  _InsightsBaseData({required this.entries, required this.streak, required this.totalCount});

  final List<Entry> entries;
  final int streak;
  final int totalCount;
}
