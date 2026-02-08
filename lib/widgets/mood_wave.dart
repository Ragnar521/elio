import 'dart:math';

import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../screens/entry_detail_screen.dart';
import '../theme/elio_colors.dart';

class MoodWave extends StatefulWidget {
  const MoodWave({
    super.key,
    required this.entries,
    required this.periodStart,
    required this.daysInPeriod,
    this.height = 180,
  });

  final List<Entry> entries;
  final DateTime periodStart;
  final int daysInPeriod;
  final double height;

  @override
  State<MoodWave> createState() => _MoodWaveState();
}

class _MoodWaveState extends State<MoodWave> {
  _WavePoint? _selected;
  List<_WavePoint> _points = const [];
  Size _lastSize = Size.zero;

  @override
  void didUpdateWidget(covariant MoodWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, widget.height);
        final points = _buildPoints(size);
        _points = points;
        _lastSize = size;

        return GestureDetector(
          onTapDown: (details) {
            final selected = _hitTest(details.localPosition);
            setState(() => _selected = selected);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: size,
                painter: _WavePainter(points: points, daysInPeriod: widget.daysInPeriod),
              ),
              if (_selected != null) _buildTooltip(context, _selected!),
            ],
          ),
        );
      },
    );
  }

  _WavePoint? _hitTest(Offset position) {
    for (final point in _points) {
      if ((point.position - position).distance <= 16) {
        return point;
      }
    }
    return null;
  }

  List<_WavePoint> _buildPoints(Size size) {
    if (widget.entries.isEmpty || size.width <= 0) return const [];
    final sorted = widget.entries.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final grouped = <DateTime, List<Entry>>{};
    for (final entry in sorted) {
      final day = _dateOnly(entry.createdAt);
      grouped.putIfAbsent(day, () => []).add(entry);
    }

    final points = <_WavePoint>[];
    final usableHeight = size.height - 24;
    final dayWidth = widget.daysInPeriod > 1
        ? size.width / (widget.daysInPeriod - 1)
        : size.width;

    for (final entry in sorted) {
      final dayIndex = entry.createdAt.difference(widget.periodStart).inDays;
      if (dayIndex < 0 || dayIndex >= widget.daysInPeriod) continue;
      final dayEntries = grouped[_dateOnly(entry.createdAt)] ?? [entry];
      final offset = _offsetForEntry(entry, dayEntries, dayWidth);
      final x = (widget.daysInPeriod == 1)
          ? size.width / 2
          : dayIndex / (widget.daysInPeriod - 1) * size.width;
      final y = 12 + (1 - entry.moodValue) * usableHeight;
      points.add(
        _WavePoint(
          entry: entry,
          dayIndex: dayIndex,
          position: Offset(x + offset, y),
        ),
      );
    }

    return points;
  }

  double _offsetForEntry(Entry entry, List<Entry> entries, double dayWidth) {
    if (entries.length <= 1) return 0;
    final index = entries.indexOf(entry);
    if (index == -1) return 0;
    final spread = min(12.0, dayWidth * 0.5);
    if (entries.length == 2) {
      return index == 0 ? -spread / 2 : spread / 2;
    }
    final step = spread / (entries.length - 1);
    return -spread / 2 + step * index;
  }

  Widget _buildTooltip(BuildContext context, _WavePoint point) {
    final tooltipWidth = 210.0;
    final left = (point.position.dx - tooltipWidth / 2)
        .clamp(8.0, max(8.0, _lastSize.width - tooltipWidth - 8))
        .toDouble();
    final top = max(8.0, point.position.dy - 130).toDouble();

    return Positioned(
      left: left,
      top: top,
      width: tooltipWidth,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ElioColors.darkSurface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _detailLabel(point.entry.createdAt),
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.7)),
              ),
              const SizedBox(height: 6),
              Text(
                point.entry.moodWord,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: ElioColors.darkPrimaryText),
              ),
              const SizedBox(height: 4),
              Text(
                point.entry.intention,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.8)),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  // Close tooltip first
                  setState(() => _selected = null);

                  // Navigate to EntryDetailScreen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EntryDetailScreen(
                        entry: point.entry,
                        timeLabel: _timeLabel(point.entry.createdAt),
                        dateLabel: _dateLabel(point.entry.createdAt),
                        moodColor: _moodColor(point.entry.moodValue),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Entry',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: ElioColors.darkAccent,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: ElioColors.darkAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _detailLabel(DateTime date) {
    final weekday = _weekdayName(date.weekday);
    final month = _monthName(date.month);
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$weekday, $month ${date.day} at $hour12:$minute $period';
  }

  String _weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

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
    if (difference < 7) return _weekdayFullName(date.weekday);

    final month = _monthName(date.month);
    if (date.year == today.year) {
      return '$month ${date.day}';
    }
    return '$month ${date.day}, ${date.year}';
  }

  String _weekdayFullName(int weekday) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[weekday - 1];
  }

  Color _moodColor(double value) {
    const low = Color(0xFF4B5A68);
    const high = ElioColors.darkAccent;
    return Color.lerp(low, high, value) ?? high;
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.points, required this.daysInPeriod});

  final List<_WavePoint> points;
  final int daysInPeriod;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final segments = _segments(points);
    for (final segment in segments) {
      if (segment.length < 2) continue;
      final strokePath = _smoothPath(segment);
      final fillPath = Path.from(strokePath)
        ..lineTo(segment.last.position.dx, size.height)
        ..lineTo(segment.first.position.dx, size.height)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElioColors.darkAccent.withOpacity(0.2),
            ElioColors.darkAccent.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);

      final strokePaint = Paint()
        ..color = ElioColors.darkAccent.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawPath(strokePath, strokePaint);
    }

    final dotPaint = Paint()..color = ElioColors.darkAccent;
    for (final point in points) {
      canvas.drawCircle(point.position, 5, dotPaint);
    }
  }

  Path _smoothPath(List<_WavePoint> segment) {
    final path = Path();
    path.moveTo(segment.first.position.dx, segment.first.position.dy);
    for (var i = 1; i < segment.length; i += 1) {
      final prev = segment[i - 1].position;
      final current = segment[i].position;
      final mid = Offset((prev.dx + current.dx) / 2, (prev.dy + current.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    final last = segment.last.position;
    path.lineTo(last.dx, last.dy);
    return path;
  }

  List<List<_WavePoint>> _segments(List<_WavePoint> points) {
    final sorted = points.toList()
      ..sort((a, b) {
        final dayCompare = a.dayIndex.compareTo(b.dayIndex);
        if (dayCompare != 0) return dayCompare;
        return a.entry.createdAt.compareTo(b.entry.createdAt);
      });
    final segments = <List<_WavePoint>>[];
    var current = <_WavePoint>[];
    for (var i = 0; i < sorted.length; i += 1) {
      final point = sorted[i];
      if (current.isEmpty) {
        current = [point];
        continue;
      }
      final prev = current.last;
      if (point.dayIndex - prev.dayIndex <= 1) {
        current.add(point);
      } else {
        segments.add(current);
        current = [point];
      }
    }
    if (current.isNotEmpty) {
      segments.add(current);
    }
    return segments;
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.daysInPeriod != daysInPeriod;
  }
}

class _WavePoint {
  const _WavePoint({
    required this.entry,
    required this.position,
    required this.dayIndex,
  });

  final Entry entry;
  final Offset position;
  final int dayIndex;
}
