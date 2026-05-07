import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../models/direction_stats.dart';
import '../models/entry.dart';
import '../services/direction_service.dart';
import '../widgets/direction_icon.dart';
import 'connect_entries_screen.dart';
import 'create_direction_screen.dart';
import 'entry_detail_screen.dart';

class DirectionDetailScreen extends StatefulWidget {
  final Direction direction;

  const DirectionDetailScreen({super.key, required this.direction});

  @override
  State<DirectionDetailScreen> createState() => _DirectionDetailScreenState();
}

class _DirectionDetailScreenState extends State<DirectionDetailScreen> {
  late Direction _direction;
  DirectionStats? _stats;

  @override
  void initState() {
    super.initState();
    _direction = widget.direction;
    _loadStats();
  }

  void _loadStats() async {
    final stats = await DirectionService.instance.getStats(_direction.id);
    final updatedDirection = DirectionService.instance.getDirection(
      _direction.id,
    );
    setState(() {
      _stats = stats;
      _direction = updatedDirection ?? _direction;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_stats == null) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              DirectionIcon(type: _direction.type, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_direction.title, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _navigateToEdit,
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            DirectionIcon(type: _direction.type, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_direction.title, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _navigateToEdit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overview card
          _buildOverviewCard(),
          const SizedBox(height: 16),

          // Direction details
          if (_hasDirectionDetails) ...[
            _buildDirectionDetailsCard(),
            const SizedBox(height: 16),
          ],

          // Mood correlation card
          _buildMoodCorrelationCard(),
          const SizedBox(height: 16),

          // Connect entry button
          _buildConnectButton(),
          const SizedBox(height: 16),

          // Recent connections
          _buildRecentConnections(),
          const SizedBox(height: 16),

          // Settings
          _buildSettings(),
          const SizedBox(height: 16),

          // Delete button
          _buildDeleteButton(),
        ],
      ),
    );
  }

  bool get _hasDirectionDetails =>
      (_direction.description ?? '').isNotEmpty ||
      (_direction.subtasks ?? '').isNotEmpty ||
      (_direction.actionItems ?? '').isNotEmpty ||
      (_direction.blockers ?? '').isNotEmpty ||
      (_direction.supportIdeas ?? '').isNotEmpty;

  Widget _buildOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OVERVIEW',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      Text(
                        '${_stats!.totalConnections}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text('connections'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Month',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      Text(
                        '${_stats!.monthlyConnections}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _stats!.monthlyProgress,
                        backgroundColor: Theme.of(context).dividerColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionDetailsCard() {
    final description = _direction.description ?? '';
    final legacySubtasks = _direction.subtasks ?? '';
    final actionItems = (_direction.actionItems ?? '').isNotEmpty
        ? _direction.actionItems ?? ''
        : legacySubtasks;
    final blockers = _direction.blockers ?? '';
    final supportIdeas = _direction.supportIdeas ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DETAILS',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
            _buildDetailTextSection('What I need to do', actionItems),
            _buildDetailTextSection('What is blocking or scaring me', blockers),
            _buildDetailTextSection('What might help', supportIdeas),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTextSection(String title, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildMoodCorrelationCard() {
    final hasData = _stats!.totalConnections > 0;
    final diff = _stats!.moodDifference;
    final isPositive = diff >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MOOD CORRELATION',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (!hasData)
              Text(
                'Connect more entries to see mood patterns.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('When connected:'),
                        Text(
                          '${_stats!.avgMoodWhenConnected.toStringAsFixed(2)} ${_getMoodLabel(_stats!.avgMoodWhenConnected)}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Overall avg:'),
                        Text(
                          _stats!.overallAvgMood.toStringAsFixed(2),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.orange)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${diff.abs().toStringAsFixed(2)} ${isPositive ? 'higher' : 'lower'} mood',
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectButton() {
    return FilledButton.icon(
      onPressed: _navigateToConnect,
      icon: const Icon(Icons.add),
      label: const Text('Connect an Entry'),
    );
  }

  Widget _buildRecentConnections() {
    if (_stats!.recentEntries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'No connections yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'After your next check-in, come back here to connect entries that relate to this direction.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'RECENT CONNECTIONS',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
          ),
          ..._stats!.recentEntries.map(
            (entry) => ListTile(
              leading: Icon(
                _getMoodIcon(entry.moodValue),
                color: _getMoodColor(entry.moodValue),
              ),
              title: Text(entry.intention),
              subtitle: Text(_formatDate(entry.createdAt)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToEntry(entry),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'SETTINGS',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
          ),
          SwitchListTile(
            title: const Text('Reflection questions'),
            subtitle: const Text(
              'Show direction-specific questions during check-in',
            ),
            value: _direction.reflectionEnabled,
            onChanged: _toggleReflection,
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return TextButton.icon(
      onPressed: _confirmDelete,
      icon: const Icon(Icons.delete_outline),
      label: const Text('Delete this direction'),
      style: TextButton.styleFrom(foregroundColor: Colors.red),
    );
  }

  String _getMoodLabel(double value) {
    if (value >= 0.8) return 'excellent';
    if (value >= 0.6) return 'good';
    if (value >= 0.4) return 'steady';
    if (value >= 0.2) return 'low';
    return 'very low';
  }

  IconData _getMoodIcon(double value) {
    if (value >= 0.75) return Icons.trending_up;
    if (value >= 0.5) return Icons.remove;
    return Icons.trending_down;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today, ${_formatTime(date)}';
    } else if (entryDate == yesterday) {
      return 'Yesterday, ${_formatTime(date)}';
    } else {
      return '${date.month}/${date.day}, ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  void _navigateToConnect() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ConnectEntriesScreen(direction: _direction),
      ),
    );

    if (result == true) {
      _loadStats();
    }
  }

  void _navigateToEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDirectionScreen(direction: _direction),
      ),
    );

    if (result == true) {
      _loadStats();
    }
  }

  void _navigateToEntry(Entry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryDetailScreen(
          entry: entry,
          timeLabel: _formatTime(entry.createdAt),
          dateLabel: _formatDate(entry.createdAt),
          moodColor: _getMoodColor(entry.moodValue),
        ),
      ),
    );
  }

  Color _getMoodColor(double moodValue) {
    if (moodValue >= 0.75) {
      return const Color(0xFF4CAF50); // Green
    } else if (moodValue >= 0.5) {
      return const Color(0xFF2196F3); // Blue
    } else if (moodValue >= 0.25) {
      return const Color(0xFFFFC107); // Amber
    } else {
      return const Color(0xFFFF5722); // Deep Orange
    }
  }

  void _toggleReflection(bool value) async {
    final updated = _direction.copyWith(reflectionEnabled: value);
    await DirectionService.instance.updateDirection(updated);
    _loadStats();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete direction?'),
        content: Text(
          'This will permanently delete "${_direction.title}" and remove its entry connections.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await DirectionService.instance.deleteDirection(_direction.id);
              if (!context.mounted) return;
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to list
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
