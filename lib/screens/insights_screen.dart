import 'dart:async';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../models/entry.dart';
import '../models/weekly_summary.dart';
import '../services/insights_service.dart';
import '../services/storage_service.dart';
import '../services/weekly_summary_service.dart';
import '../theme/elio_colors.dart';
import '../widgets/calendar_heatmap.dart';
import '../widgets/day_entries_sheet.dart';
import '../widgets/day_pattern_chart.dart';
import '../widgets/insight_card.dart';
import '../widgets/mood_wave.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state_view.dart';
import 'weekly_summary_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

enum _NavigationDirection { forward, backward }

class _InsightsScreenState extends State<InsightsScreen> {
  late Future<_InsightsBaseData> _future;
  InsightsPeriod _period = InsightsPeriod.week;
  int _offset = 0;
  bool _useSampleData = false;
  _NavigationDirection _lastDirection = _NavigationDirection.forward;
  DateTime? _selectedCalendarDate;
  bool _showShimmer = false;
  Timer? _shimmerTimer;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    _shimmerTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _showShimmer = true);
    });
  }

  @override
  void dispose() {
    _shimmerTimer?.cancel();
    super.dispose();
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
      _selectedCalendarDate = null;
    });
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return;
    if (velocity < 0) {
      _navigatePeriod(-1);
    } else {
      _navigatePeriod(1);
    }
  }

  void _navigatePeriod(int direction) {
    if (direction > 0) {
      // Going forward (to present)
      if (_offset >= 0) return; // Already at current period
      setState(() {
        _lastDirection = _NavigationDirection.forward;
        _offset = (_offset + 1).clamp(-1000, 0);
      });
    } else {
      // Going backward (to past)
      setState(() {
        _lastDirection = _NavigationDirection.backward;
        _offset -= 1;
      });
    }
  }

  bool get _isCurrentPeriod => _offset == 0;

  Map<DateTime, List<Entry>> _groupEntriesByDate(List<Entry> entries, DateTime month) {
    final Map<DateTime, List<Entry>> grouped = {};
    for (final entry in entries) {
      final date = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
      // Only include entries from the displayed month
      if (date.year == month.year && date.month == month.month) {
        grouped.putIfAbsent(date, () => []).add(entry);
      }
    }
    return grouped;
  }

  DateTime _getDisplayedMonth(InsightsData data) {
    return DateTime(data.periodStart.year, data.periodStart.month);
  }

  DateTime _calculateFirstEntryMonth(List<Entry> allEntries) {
    if (allEntries.isEmpty) return DateTime(DateTime.now().year, DateTime.now().month);
    DateTime earliest = allEntries.first.createdAt;
    for (final entry in allEntries) {
      if (entry.createdAt.isBefore(earliest)) {
        earliest = entry.createdAt;
      }
    }
    return DateTime(earliest.year, earliest.month);
  }

  bool _canNavigateCalendarBack(DateTime displayedMonth, DateTime firstEntryMonth) {
    return displayedMonth.year > firstEntryMonth.year ||
        (displayedMonth.year == firstEntryMonth.year && displayedMonth.month > firstEntryMonth.month);
  }

  bool _canNavigateCalendarForward(DateTime displayedMonth) {
    final now = DateTime.now();
    return displayedMonth.year < now.year ||
        (displayedMonth.year == now.year && displayedMonth.month < now.month);
  }

  void _onCalendarMonthChanged(int direction) {
    _navigatePeriod(direction);
  }

  void _onCalendarDayTap(DateTime date, List<Entry> entries) {
    setState(() {
      _selectedCalendarDate = date;
    });

    // Sort entries newest first
    final sortedEntries = List<Entry>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Calculate average mood
    final avgMood = entries.fold(0.0, (sum, e) => sum + e.moodValue) / entries.length;

    // Build day label
    final dayLabel = _calendarDayLabel(date);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => DayEntriesSheet(
          dayName: dayLabel,
          entries: sortedEntries,
          averageMood: avgMood,
        ),
      ),
    ).then((_) {
      // Clear highlight when sheet is dismissed
      if (mounted) {
        setState(() {
          _selectedCalendarDate = null;
        });
      }
    });
  }

  String _calendarDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthName = monthNames[date.month - 1];
    if (date.year == now.year) {
      return '$monthName ${date.day}';
    }
    return '$monthName ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_InsightsBaseData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              if (!_showShimmer) {
                return const SizedBox.shrink();
              }
              return Skeletonizer(
                enabled: true,
                effect: ShimmerEffect(
                  baseColor: ElioColors.darkSurface,
                  highlightColor: ElioColors.darkSurface.withOpacity(0.6),
                  duration: const Duration(milliseconds: 1500),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  children: [
                    // Toggle bar placeholder
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: ElioColors.darkSurface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Wave chart placeholder
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: ElioColors.darkSurface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Stat cards placeholder
                    Row(
                      children: List.generate(4, (index) => Expanded(
                        child: Container(
                          height: 80,
                          margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                          decoration: BoxDecoration(
                            color: ElioColors.darkSurface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      )),
                    ),
                    const SizedBox(height: 24),
                    // Day pattern chart placeholder
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: ElioColors.darkSurface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ],
                ),
              );
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
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  EmptyStateView(
                    svgAsset: 'assets/empty_states/insights_empty.svg',
                    title: 'Patterns will emerge',
                    description: 'Check in a few times and your mood patterns will start to appear here.',
                  ),
                ],
              );
            }

            if (data.entries.isEmpty) {
              final label = _period == InsightsPeriod.week ? 'week' : 'month';
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  EmptyStateView(
                    svgAsset: 'assets/empty_states/insights_empty.svg',
                    title: 'No check-ins this $label yet',
                    description: 'Your first one could be now.',
                  ),
                ],
              );
            }

            return ListView(
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
                  _buildPeriodNavigation(context, data),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onHorizontalDragEnd: _onSwipe,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder: (child, animation) {
                        return _buildAnimatedTransition(child, animation);
                      },
                      child: _buildPeriodContent(context, data, entries),
                    ),
                  ),
                ],
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

  Widget _buildAnimatedTransition(Widget child, Animation<double> animation) {
    final offsetAnimation = Tween<Offset>(
      begin: _lastDirection == _NavigationDirection.backward
          ? const Offset(-0.3, 0.0) // Slide in from left
          : const Offset(0.3, 0.0), // Slide in from right
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    ));

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  Widget _buildPeriodContent(BuildContext context, InsightsData data, List<Entry> allEntries) {
    // Use a unique key based on period and offset to trigger animation
    final key = ValueKey('${_period.name}_$_offset');

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MoodWave(
          entries: data.entries,
          periodStart: data.periodStart,
          daysInPeriod: data.daysInPeriod,
        ),
        const SizedBox(height: 10),
        _buildAxisLabels(context, data.daysInPeriod),
        const SizedBox(height: 12),
        _buildComparisonLine(context, data),
        const SizedBox(height: 24),
        InsightCard(insights: data.insights),
        const SizedBox(height: 18),
        _buildStatsRow(context, data),
        const SizedBox(height: 24),
        DayPatternChart(
          pattern: data.dayOfWeekAverages,
          bestDay: data.bestDay,
          worstDay: data.worstDay,
          onDayTap: (dayOfWeek) => _showDayEntriesSheet(context, data, dayOfWeek),
        ),
        const SizedBox(height: 16),
        // Only show calendar in Month view
        if (_period == InsightsPeriod.month) ...[
          const SizedBox(height: 28),
          Text(
            'Mood Calendar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ElioColors.darkPrimaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildCalendarSection(context, allEntries, data),
        ],
        const SizedBox(height: 16),
        _buildPatternInsight(context, data.patternInsight),
        const SizedBox(height: 32),
        _buildWeeklyRecapsSection(context),
      ],
    );
  }

  Widget _buildPeriodNavigation(BuildContext context, InsightsData data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left arrow (always enabled - go to past)
        IconButton(
          icon: const Icon(Icons.chevron_left),
          color: ElioColors.darkPrimaryText,
          onPressed: () => _navigatePeriod(-1),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        // Period label
        Text(
          _periodLabel(data.periodStart, data.periodEnd, _period),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ElioColors.darkPrimaryText.withOpacity(0.7),
                fontSize: 16,
              ),
        ),
        const SizedBox(width: 12),
        // Right arrow (disabled at current period)
        IconButton(
          icon: const Icon(Icons.chevron_right),
          color: _isCurrentPeriod
              ? ElioColors.darkPrimaryText.withOpacity(0.3)
              : ElioColors.darkPrimaryText,
          onPressed: _isCurrentPeriod ? null : () => _navigatePeriod(1),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
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

  Widget _buildComparisonLine(BuildContext context, InsightsData data) {
    final avgFormatted = data.avgMood.toStringAsFixed(2);
    final periodName = _period == InsightsPeriod.week ? 'week' : 'month';

    String comparisonText = 'This $periodName: $avgFormatted avg';

    if (data.moodChangeVsPrevious != null) {
      final percentChange = (data.moodChangeVsPrevious! * 100).round();
      final arrow = percentChange > 0 ? '↑' : '↓';
      final color = percentChange > 0
          ? const Color(0xFF4CAF50)
          : ElioColors.darkPrimaryText.withOpacity(0.5);

      return Center(
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ElioColors.darkPrimaryText.withOpacity(0.7),
                  fontSize: 13,
                ),
            children: [
              TextSpan(text: comparisonText),
              const TextSpan(text: '  '),
              TextSpan(
                text: '$arrow${percentChange.abs()}%',
                style: TextStyle(color: color),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Text(
        comparisonText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ElioColors.darkPrimaryText.withOpacity(0.7),
              fontSize: 13,
            ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, InsightsData data) {
    final cards = _period == InsightsPeriod.week
        ? [
            StatCard(
              value: data.checkInCount.toString(),
              label: 'of 7 days',
              comparison: data.checkInChangeVsPrevious != null
                  ? (data.checkInChangeVsPrevious! >= 0
                      ? '↑${data.checkInChangeVsPrevious}'
                      : '↓${data.checkInChangeVsPrevious!.abs()}')
                  : null,
              isPositive: data.checkInChangeVsPrevious != null && data.checkInChangeVsPrevious! > 0,
            ),
            StatCard(
              value: data.streak.toString(),
              label: 'days',
              comparison: 'best: ${data.longestStreakAllTime}',
            ),
            StatCard(
              value: '${(data.reflectionRate * 100).round()}%',
              label: '${data.reflectionDays} of ${data.checkInCount}',
            ),
            StatCard(
              value: data.mostFelt,
              label: '',
            ),
          ]
        : [
            StatCard(
              value: data.checkInCount.toString(),
              label: 'of ${data.daysInPeriod} days',
              comparison: data.checkInChangeVsPrevious != null
                  ? (data.checkInChangeVsPrevious! >= 0
                      ? '↑${data.checkInChangeVsPrevious}'
                      : '↓${data.checkInChangeVsPrevious!.abs()}')
                  : null,
              isPositive: data.checkInChangeVsPrevious != null && data.checkInChangeVsPrevious! > 0,
            ),
            StatCard(
              value: data.streak.toString(),
              label: 'current',
              comparison: 'best: ${data.longestStreakAllTime}',
            ),
            StatCard(
              value: '${(data.reflectionRate * 100).round()}%',
              label: '${data.reflectionDays} of ${data.checkInCount}',
            ),
            StatCard(
              value: data.mostFelt,
              label: '${data.mostFeltCount} times',
            ),
          ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: cards[0]),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: cards[1]),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: cards[2]),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: cards[3]),
      ],
    );
  }

  Widget _buildPatternInsight(BuildContext context, String insight) {
    if (insight.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ElioColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElioColors.darkPrimaryText.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        insight,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ElioColors.darkPrimaryText.withOpacity(0.8),
              fontSize: 14,
            ),
      ),
    );
  }

  Widget _buildWeeklyRecapsSection(BuildContext context) {
    final summaries = WeeklySummaryService.instance.getAllSummaries();

    if (summaries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Recaps',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ElioColors.darkPrimaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete a full week to see your first recap',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ElioColors.darkPrimaryText.withOpacity(0.6),
                ),
          ),
        ],
      );
    }

    final displaySummaries = summaries.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Weekly Recaps',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ElioColors.darkPrimaryText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            if (summaries.length > 3)
              GestureDetector(
                onTap: () => _showAllSummaries(context, summaries),
                child: Text(
                  'View all',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ElioColors.darkAccent,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...displaySummaries.map((summary) => _buildSummaryListItem(context, summary)).toList(),
      ],
    );
  }

  Widget _buildSummaryListItem(BuildContext context, WeeklySummary summary) {
    final moodWord = _getMoodWord(summary.avgMood);
    final trendIcon = _getTrendIcon(summary.moodTrend);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WeeklySummaryScreen(summary: summary),
        ),
      ),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: ElioColors.darkSurface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  summary.weekLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ElioColors.darkPrimaryText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  '${summary.checkInCount} check-ins',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.6),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getMoodColor(summary.avgMood),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  moodWord,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.7),
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  trendIcon,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodWord(double avgMood) {
    if (avgMood < 0.14) return 'Heavy';
    if (avgMood < 0.28) return 'Tired';
    if (avgMood < 0.42) return 'Flat';
    if (avgMood < 0.56) return 'Okay';
    if (avgMood < 0.70) return 'Calm';
    if (avgMood < 0.84) return 'Good';
    if (avgMood < 0.90) return 'Energized';
    return 'Great';
  }

  Color _getMoodColor(double avgMood) {
    const low = Color(0xFF4B5A68);
    const high = ElioColors.darkAccent;
    return Color.lerp(low, high, avgMood) ?? high;
  }

  String _getTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return '↑';
      case 'down':
        return '↓';
      default:
        return '—';
    }
  }

  void _showAllSummaries(BuildContext context, List<WeeklySummary> summaries) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: ElioColors.darkBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ElioColors.darkPrimaryText.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'All Weekly Recaps',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: ElioColors.darkPrimaryText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: summaries.length,
                  itemBuilder: (context, index) {
                    return _buildSummaryListItem(context, summaries[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarSection(BuildContext context, List<Entry> allEntries, InsightsData data) {
    final displayedMonth = _getDisplayedMonth(data);
    final entriesByDate = _groupEntriesByDate(allEntries, displayedMonth);
    final firstEntryMonth = _calculateFirstEntryMonth(allEntries);

    return CalendarHeatmap(
      month: displayedMonth,
      entriesByDate: entriesByDate,
      onDayTap: _onCalendarDayTap,
      onMonthChanged: _onCalendarMonthChanged,
      selectedDate: _selectedCalendarDate,
      canNavigateBack: _canNavigateCalendarBack(displayedMonth, firstEntryMonth),
      canNavigateForward: _canNavigateCalendarForward(displayedMonth),
    );
  }

  void _showDayEntriesSheet(BuildContext context, InsightsData data, int dayOfWeek) {
    // Filter entries for this specific day of the week
    final dayEntries = data.entries.where((entry) {
      return entry.createdAt.weekday == dayOfWeek;
    }).toList();

    // Sort by date, newest first
    dayEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Get day name
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[dayOfWeek - 1];

    // Get average mood for this day
    final avgMood = data.dayOfWeekAverages[dayOfWeek] ?? 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => DayEntriesSheet(
          dayName: dayName,
          entries: dayEntries,
          averageMood: avgMood,
        ),
      ),
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
