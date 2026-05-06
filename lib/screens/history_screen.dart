import 'dart:async';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../models/entry.dart';
import '../models/entry_filter.dart';
import '../models/direction.dart';
import '../services/storage_service.dart';
import '../services/filter_service.dart';
import '../services/direction_service.dart';
import '../theme/elio_colors.dart';
import '../widgets/direction_icon.dart';
import '../widgets/entry_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/empty_state_view.dart';
import 'entry_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<_HistoryData> _historyFuture;
  EntryFilter _filter = const EntryFilter();
  List<Entry> _allEntries = [];
  List<Entry> _filteredEntries = [];
  List<Direction> _activeDirections = [];
  Set<String>? _connectedEntryIds;
  String? _lastDirectionId;
  final _searchBarKey = GlobalKey<DebouncedSearchBarState>();
  bool _showShimmer = false;
  Timer? _shimmerTimer;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadData();
    _shimmerTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _showShimmer = true);
    });
  }

  @override
  void dispose() {
    _shimmerTimer?.cancel();
    super.dispose();
  }

  Future<_HistoryData> _loadData() async {
    final entries = await StorageService.instance.getAllEntries();
    final streak = await StorageService.instance.getCurrentStreak();
    final directions = DirectionService.instance.getActiveDirections();

    _allEntries = entries;
    _activeDirections = directions;
    await _applyFilters();

    return _HistoryData(entries: entries, streak: streak);
  }

  Future<void> _refresh() async {
    setState(() {
      _showShimmer = false;
      _shimmerTimer?.cancel();
      _shimmerTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _showShimmer = true);
      });
      _historyFuture = _loadData();
    });
    await _historyFuture;
  }

  Future<void> _applyFilters() async {
    // Pre-fetch connected entry IDs if direction filter active
    if (_filter.directionId != null &&
        _filter.directionId != _lastDirectionId) {
      _connectedEntryIds = await FilterService.instance.getConnectedEntryIds(
        _filter.directionId!,
      );
      _lastDirectionId = _filter.directionId;
    } else if (_filter.directionId == null) {
      _connectedEntryIds = null;
      _lastDirectionId = null;
    }

    setState(() {
      _filteredEntries = FilterService.instance.filterEntries(
        entries: _allEntries,
        filter: _filter,
        connectedEntryIds: _connectedEntryIds,
      );
    });
  }

  void _onSearchChanged(String query) {
    _filter = _filter.copyWith(searchQuery: query.isEmpty ? null : query);
    _applyFilters();
  }

  void _onMoodRangeToggled(MoodRange range) {
    final newRanges = Set<MoodRange>.from(_filter.moodRanges);
    if (newRanges.contains(range)) {
      newRanges.remove(range);
    } else {
      newRanges.add(range);
    }
    _filter = _filter.copyWith(moodRanges: newRanges);
    _applyFilters();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _filter.dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: ElioColors.darkAccent,
              surface: ElioColors.darkSurface,
              onSurface: ElioColors.darkPrimaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _filter = _filter.copyWith(dateRange: picked);
      _applyFilters();
    }
  }

  void _onDirectionSelected(String? directionId) {
    _filter = _filter.copyWith(directionId: directionId);
    _applyFilters();
  }

  void _clearFilters() {
    _filter = _filter.cleared();
    _connectedEntryIds = null;
    _lastDirectionId = null;
    _searchBarKey.currentState?.clear();
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_HistoryData>(
          future: _historyFuture,
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
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                  itemCount: 5,
                  itemBuilder: (context, index) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ElioColors.darkSurface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: ElioColors.darkSurface,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 80,
                              height: 16,
                              color: ElioColors.darkSurface,
                            ),
                            const Spacer(),
                            Container(
                              width: 60,
                              height: 12,
                              color: ElioColors.darkSurface,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 14,
                          color: ElioColors.darkSurface,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 200,
                          height: 14,
                          color: ElioColors.darkSurface,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final data = snapshot.data;
            final streak = data?.streak ?? 0;

            return RefreshIndicator(
              color: ElioColors.darkAccent,
              backgroundColor: ElioColors.darkSurface,
              onRefresh: _refresh,
              child: _allEntries.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                      children: [
                        EmptyStateView(
                          svgAsset: 'assets/empty_states/history_empty.svg',
                          title: 'Your story starts here',
                          description:
                              'Check in with your mood to start building your personal timeline.',
                          ctaLabel: 'Start your first check-in',
                          onCtaPressed: () {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      children: [
                        Text(
                          'Your Journey',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _filter.hasActiveFilters
                              ? '${_filteredEntries.length} of ${_allEntries.length} entries'
                              : (streak > 0
                                    ? '$streak day streak'
                                    : '${_allEntries.length} check-ins'),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: ElioColors.darkPrimaryText.withOpacity(
                                  0.7,
                                ),
                              ),
                        ),
                        const SizedBox(height: 24),
                        _buildFilterSection(),
                        const SizedBox(height: 16),
                        if (_allEntries.isNotEmpty &&
                            _filteredEntries.isEmpty &&
                            _filter.hasActiveFilters)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                'No entries match your filters',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: ElioColors.darkPrimaryText
                                          .withOpacity(0.6),
                                    ),
                              ),
                            ),
                          )
                        else
                          ..._buildEntrySections(_filteredEntries),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        DebouncedSearchBar(key: _searchBarKey, onSearch: _onSearchChanged),
        const SizedBox(height: 12),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Mood range chips
              ...MoodRange.values.map((range) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(range.label),
                    selected: _filter.moodRanges.contains(range),
                    onSelected: (_) => _onMoodRangeToggled(range),
                    selectedColor: ElioColors.darkAccent.withOpacity(0.3),
                    checkmarkColor: ElioColors.darkAccent,
                    backgroundColor: ElioColors.darkSurface,
                    labelStyle: const TextStyle(
                      color: ElioColors.darkPrimaryText,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
              }),

              // Date range chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    _filter.dateRange != null
                        ? '${_monthName(_filter.dateRange!.start.month)} ${_filter.dateRange!.start.day} - ${_monthName(_filter.dateRange!.end.month)} ${_filter.dateRange!.end.day}'
                        : 'Dates',
                  ),
                  selected: _filter.dateRange != null,
                  onSelected: (_) => _selectDateRange(),
                  onDeleted: _filter.dateRange != null
                      ? () {
                          _filter = _filter.copyWith(dateRange: null);
                          _applyFilters();
                        }
                      : null,
                  selectedColor: ElioColors.darkAccent.withOpacity(0.3),
                  checkmarkColor: ElioColors.darkAccent,
                  backgroundColor: ElioColors.darkSurface,
                  labelStyle: const TextStyle(
                    color: ElioColors.darkPrimaryText,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              // Direction chips
              ..._activeDirections.map((direction) {
                final isSelected = _filter.directionId == direction.id;
                final title = direction.title.length > 12
                    ? '${direction.title.substring(0, 12)}...'
                    : direction.title;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: DirectionIcon(type: direction.type, size: 20),
                    label: Text(title),
                    selected: isSelected,
                    onSelected: (_) =>
                        _onDirectionSelected(isSelected ? null : direction.id),
                    selectedColor: ElioColors.darkAccent.withOpacity(0.3),
                    checkmarkColor: ElioColors.darkAccent,
                    backgroundColor: ElioColors.darkSurface,
                    labelStyle: const TextStyle(
                      color: ElioColors.darkPrimaryText,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
              }),

              // Clear all chip
              if (_filter.hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      'Clear all',
                      style: TextStyle(
                        color: ElioColors.darkPrimaryText.withOpacity(0.6),
                      ),
                    ),
                    onPressed: _clearFilters,
                    backgroundColor: ElioColors.darkSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Results count
        if (_filter.hasActiveFilters) ...[
          const SizedBox(height: 12),
          Text(
            '${_filteredEntries.length} entries found',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ElioColors.darkPrimaryText.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ElioColors.darkPrimaryText.withOpacity(0.85),
              ),
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

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

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
