import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../models/entry.dart';
import '../services/direction_service.dart';

class ConnectEntriesScreen extends StatefulWidget {
  final Direction direction;

  const ConnectEntriesScreen({
    super.key,
    required this.direction,
  });

  @override
  State<ConnectEntriesScreen> createState() => _ConnectEntriesScreenState();
}

class _ConnectEntriesScreenState extends State<ConnectEntriesScreen> {
  List<Entry> _entries = [];
  final Set<String> _selectedIds = {};
  bool _showConnected = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() async {
    if (_showConnected) {
      final entries = await DirectionService.instance.getConnectedEntries(widget.direction.id);
      setState(() {
        _entries = entries;
      });
    } else {
      final entries = await DirectionService.instance.getUnconnectedEntries(widget.direction.id);
      setState(() {
        _entries = entries;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect to ${widget.direction.emoji}'),
        actions: [
          if (_selectedIds.isNotEmpty)
            TextButton(
              onPressed: _connect,
              child: Text('Connect (${_selectedIds.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Toggle between unconnected/connected
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Unconnected')),
                ButtonSegment(value: true, label: Text('Connected')),
              ],
              selected: {_showConnected},
              onSelectionChanged: (selected) {
                setState(() {
                  _showConnected = selected.first;
                  _selectedIds.clear();
                });
                _loadEntries();
              },
            ),
          ),

          // Entry list
          Expanded(
            child: _entries.isEmpty
                ? Center(
                    child: Text(
                      _showConnected
                          ? 'No connected entries yet'
                          : 'All recent entries are connected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      final isSelected = _selectedIds.contains(entry.id);

                      return CheckboxListTile(
                        value: _showConnected || isSelected,
                        onChanged: _showConnected
                            ? null // Can't uncheck from this screen
                            : (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedIds.add(entry.id);
                                  } else {
                                    _selectedIds.remove(entry.id);
                                  }
                                });
                              },
                        secondary: Text(
                          entry.moodEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(entry.intention),
                        subtitle: Text(_formatDate(entry.createdAt)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today, ${_formatTime(date)}';
    } else if (entryDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _connect() async {
    for (final entryId in _selectedIds) {
      await DirectionService.instance.connectEntry(
        directionId: widget.direction.id,
        entryId: entryId,
      );
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}
