import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../models/weekly_summary.dart';
import '../services/storage_service.dart';
import '../services/weekly_summary_service.dart';
import '../services/direction_service.dart';
import '../theme/elio_colors.dart';
import '../widgets/mood_wave.dart';

class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key, required this.summary});

  final WeeklySummary summary;

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  List<Entry> _weekEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeekEntries();
    WeeklySummaryService.instance.markAsViewed(widget.summary.id);
  }

  Future<void> _loadWeekEntries() async {
    final entries = await StorageService.instance.getEntriesForPeriod(
      widget.summary.weekStart,
      widget.summary.weekEnd,
    );
    setState(() {
      _weekEntries = entries;
      _isLoading = false;
    });
  }

  String _getTrendIcon() {
    switch (widget.summary.moodTrend) {
      case 'up':
        return '↑';
      case 'down':
        return '↓';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElioColors.darkBackground,
      appBar: AppBar(
        backgroundColor: ElioColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ElioColors.darkPrimaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Week of ${widget.summary.weekLabel}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ElioColors.darkPrimaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMoodOverviewSection(context),
                    if (widget.summary.hasDirections) ...[
                      const SizedBox(height: 24),
                      _buildDirectionSection(context),
                    ],
                    if (widget.summary.hasReflections) ...[
                      const SizedBox(height: 24),
                      _buildReflectionSection(context),
                    ],
                    const SizedBox(height: 24),
                    _buildTakeawaySection(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMoodOverviewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mood Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ElioColors.darkPrimaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        MoodWave(
          entries: _weekEntries,
          periodStart: widget.summary.weekStart,
          daysInPeriod: 7,
          height: 160,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMiniStat(
              context,
              'Check-ins',
              '${widget.summary.checkInCount} of 7',
            ),
            _buildMiniStat(
              context,
              'Avg mood',
              widget.summary.avgMood.toStringAsFixed(2),
            ),
            _buildMiniStat(
              context,
              'Trend',
              '${_getTrendIcon()} ${widget.summary.moodTrend}',
            ),
          ],
        ),
        if (widget.summary.bestMoodDay != null) ...[
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Best day: ${widget.summary.bestMoodDay} — ${widget.summary.bestMoodWord}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ElioColors.darkAccent,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ElioColors.darkPrimaryText.withOpacity(0.6),
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ElioColors.darkPrimaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildDirectionSection(BuildContext context) {
    if (!widget.summary.hasDirections) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Directions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ElioColors.darkPrimaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add a direction to see how your mood connects to what matters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ElioColors.darkPrimaryText.withOpacity(0.6),
                ),
          ),
        ],
      );
    }

    final directionSummaries = widget.summary.directionSummaries!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Directions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ElioColors.darkPrimaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        // Top direction highlight
        if (widget.summary.topDirectionId != null) ...[
          Builder(
            builder: (context) {
              final topDir = directionSummaries.firstWhere(
                (dir) => dir['directionId'] == widget.summary.topDirectionId,
                orElse: () => <String, dynamic>{},
              );
              if (topDir.isEmpty) return const SizedBox.shrink();

              final moodDiff = topDir['moodDifference'] as double;
              final percentage = (moodDiff * 100).toStringAsFixed(0);

              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: ElioColors.darkSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ElioColors.darkAccent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '${topDir['emoji']} ${topDir['title']} boosted your mood by $percentage%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ElioColors.darkPrimaryText,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              );
            },
          ),
        ],
        // Direction mini cards
        ...directionSummaries.map((dirData) {
          final title = dirData['title'] as String;
          final emoji = dirData['emoji'] as String;
          final weeklyConnections = dirData['weeklyConnections'] as int;
          final moodDifference = dirData['moodDifference'] as double;

          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: ElioColors.darkSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$emoji $title',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ElioColors.darkPrimaryText,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '$weeklyConnections connections',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ElioColors.darkPrimaryText.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
                if (moodDifference.abs() >= 0.1) ...[
                  const SizedBox(height: 4),
                  Text(
                    moodDifference > 0
                        ? '↑ ${(moodDifference * 100).toStringAsFixed(0)}% higher mood'
                        : '↓ ${(moodDifference.abs() * 100).toStringAsFixed(0)}% lower mood',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: moodDifference > 0
                              ? const Color(0xFF4CAF50)
                              : ElioColors.darkAccent,
                          fontSize: 12,
                        ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildReflectionSection(BuildContext context) {
    if (!widget.summary.hasReflections) return const SizedBox.shrink();

    final reflections = widget.summary.standoutReflectionAnswers!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reflections',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ElioColors.darkPrimaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...reflections.map((reflection) {
          final questionText = reflection['questionText'] as String;
          final answer = reflection['answer'] as String;

          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: ElioColors.darkSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 16,
                      color: ElioColors.darkPrimaryText.withOpacity(0.4),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        questionText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ElioColors.darkPrimaryText.withOpacity(0.6),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  answer,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ElioColors.darkPrimaryText,
                      ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTakeawaySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ElioColors.darkAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          widget.summary.takeaway,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ElioColors.darkPrimaryText,
                height: 1.5,
              ),
        ),
      ),
    );
  }
}
