# Elio — Directions Module Implementation Guide

## ✅ Implementation Status

**Status:** COMPLETE (February 9, 2026)
**Branch:** `directions-module`
**Version:** 1.1.0
**Commit:** ae24a96

This module has been fully implemented and is ready for testing/review. See commit message for full details.

## Overview

**Module:** Directions (Life Compass)
**Purpose:** Help users connect daily mood entries to life areas they care about
**Philosophy:** Compass, not checklist — ongoing awareness, not completion

**Key Decisions:**
- Selection happens **only in Directions tab** (not during check-in flow)
- Maximum **5 directions** per user
- Progress shows **all three:** count, monthly bar, mood correlation
- Reflection questions are **optional per direction**
- Naming: **"Directions"** (softer than "Goals")

**Implementation Notes:**
- Manual Hive adapters used (typeIds 4, 5, 6) - no build_runner
- Singleton service pattern matching existing codebase
- All database operations are async
- Direction insights only show in week view to maintain relevance

---

## Navigation Update

Add Directions as the **3rd tab** (middle position):

```
┌─────┬─────┬─────┬─────┬─────┐
│ 😊  │ 📊  │ 🧭  │ 📜  │ ⚙️  │
│Check│Insig│ Dir │Hist │Set  │
└─────┴─────┴─────┴─────┴─────┘
```

**Tab order:** Check-in → Insights → **Directions** → History → Settings

Update `main.dart` or navigation widget to include the new tab with compass icon (🧭 or `Icons.explore`).

---

## Data Models

### File: `lib/models/direction.dart`

```dart
import 'package:hive/hive.dart';

part 'direction.g.dart';

/// Direction types representing life areas
@HiveType(typeId: 10)
enum DirectionType {
  @HiveField(0)
  career,       // 💼
  
  @HiveField(1)
  health,       // 💪
  
  @HiveField(2)
  relationships, // 👥
  
  @HiveField(3)
  growth,       // 🌱
  
  @HiveField(4)
  peace,        // 🧘
  
  @HiveField(5)
  creativity,   // 🎨
}

/// Extension for DirectionType utilities
extension DirectionTypeExtension on DirectionType {
  String get emoji {
    switch (this) {
      case DirectionType.career:
        return '💼';
      case DirectionType.health:
        return '💪';
      case DirectionType.relationships:
        return '👥';
      case DirectionType.growth:
        return '🌱';
      case DirectionType.peace:
        return '🧘';
      case DirectionType.creativity:
        return '🎨';
    }
  }
  
  String get label {
    switch (this) {
      case DirectionType.career:
        return 'Career';
      case DirectionType.health:
        return 'Health';
      case DirectionType.relationships:
        return 'Relationships';
      case DirectionType.growth:
        return 'Growth';
      case DirectionType.peace:
        return 'Peace';
      case DirectionType.creativity:
        return 'Creativity';
    }
  }
  
  /// Example prompts for this direction type
  List<String> get examples {
    switch (this) {
      case DirectionType.career:
        return [
          'Find work that energizes me',
          'Build skills I\'m proud of',
          'Create more than I consume',
        ];
      case DirectionType.health:
        return [
          'Feel strong and rested',
          'Move my body daily',
          'Sleep better, stress less',
        ];
      case DirectionType.relationships:
        return [
          'Be more present with family',
          'Nurture meaningful friendships',
          'Listen more, react less',
        ];
      case DirectionType.growth:
        return [
          'Learn something new regularly',
          'Read more, scroll less',
          'Step outside comfort zone',
        ];
      case DirectionType.peace:
        return [
          'Worry less about what I can\'t control',
          'Find calm in busy days',
          'Let go of perfectionism',
        ];
      case DirectionType.creativity:
        return [
          'Make time for creative expression',
          'Start projects I\'ve postponed',
          'Play more, plan less',
        ];
    }
  }
  
  /// Reflection questions for this direction type
  List<String> get reflectionQuestions {
    switch (this) {
      case DirectionType.career:
        return [
          'Did today move you closer to work that energizes you?',
          'What would make tomorrow better at work?',
        ];
      case DirectionType.health:
        return [
          'How did your body feel today?',
          'What\'s one thing you did for your energy today?',
        ];
      case DirectionType.relationships:
        return [
          'Who mattered most today?',
          'How present were you with the people around you?',
        ];
      case DirectionType.growth:
        return [
          'What did you learn or try today?',
          'What challenged you in a good way?',
        ];
      case DirectionType.peace:
        return [
          'What did you let go of today?',
          'Where did you find calm?',
        ];
      case DirectionType.creativity:
        return [
          'Did you make something today?',
          'What inspired you?',
        ];
    }
  }
}

/// A life direction the user wants to be aware of
@HiveType(typeId: 11)
class Direction extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title; // max 50 chars
  
  @HiveField(2)
  final DirectionType type;
  
  @HiveField(3)
  final bool reflectionEnabled; // show questions during check-in
  
  @HiveField(4)
  final bool isArchived;
  
  @HiveField(5)
  final DateTime createdAt;
  
  Direction({
    required this.id,
    required this.title,
    required this.type,
    required this.reflectionEnabled,
    this.isArchived = false,
    required this.createdAt,
  });
  
  /// Get emoji from type
  String get emoji => type.emoji;
  
  /// Create a copy with updated fields
  Direction copyWith({
    String? title,
    bool? reflectionEnabled,
    bool? isArchived,
  }) {
    return Direction(
      id: id,
      title: title ?? this.title,
      type: type,
      reflectionEnabled: reflectionEnabled ?? this.reflectionEnabled,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
    );
  }
}
```

### File: `lib/models/direction_connection.dart`

```dart
import 'package:hive/hive.dart';

part 'direction_connection.g.dart';

/// Links an entry to a direction (many-to-many relationship)
@HiveType(typeId: 12)
class DirectionConnection extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String directionId;
  
  @HiveField(2)
  final String entryId;
  
  @HiveField(3)
  final DateTime createdAt;
  
  DirectionConnection({
    required this.id,
    required this.directionId,
    required this.entryId,
    required this.createdAt,
  });
}
```

### File: `lib/models/direction_stats.dart`

```dart
import 'entry.dart';

/// Statistics for a direction
class DirectionStats {
  final int totalConnections;
  final int monthlyConnections;
  final int monthlyTarget; // always 10 for progress bar
  final double avgMoodWhenConnected;
  final double overallAvgMood;
  final List<Entry> recentEntries; // last 5 connected entries
  
  DirectionStats({
    required this.totalConnections,
    required this.monthlyConnections,
    this.monthlyTarget = 10,
    required this.avgMoodWhenConnected,
    required this.overallAvgMood,
    required this.recentEntries,
  });
  
  /// Mood difference (positive = better mood when connected)
  double get moodDifference => avgMoodWhenConnected - overallAvgMood;
  
  /// Progress percentage for monthly bar (0.0 - 1.0)
  double get monthlyProgress => 
      (monthlyConnections / monthlyTarget).clamp(0.0, 1.0);
  
  /// Whether this direction correlates with higher mood
  bool get hasPositiveCorrelation => moodDifference >= 0.1;
  
  /// Whether this direction correlates with lower mood
  bool get hasNegativeCorrelation => moodDifference <= -0.1;
}
```

---

## Service Layer

### File: `lib/services/direction_service.dart`

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/direction.dart';
import '../models/direction_connection.dart';
import '../models/direction_stats.dart';
import '../models/entry.dart';
import 'entry_service.dart';

class DirectionService {
  static const String _directionsBoxName = 'directions';
  static const String _connectionsBoxName = 'direction_connections';
  static const int maxDirections = 5;
  
  final Uuid _uuid = const Uuid();
  late Box<Direction> _directionsBox;
  late Box<DirectionConnection> _connectionsBox;
  final EntryService _entryService;
  
  DirectionService(this._entryService);
  
  /// Initialize Hive boxes
  Future<void> init() async {
    _directionsBox = await Hive.openBox<Direction>(_directionsBoxName);
    _connectionsBox = await Hive.openBox<DirectionConnection>(_connectionsBoxName);
  }
  
  // ============ DIRECTIONS CRUD ============
  
  /// Get all active (non-archived) directions
  List<Direction> getActiveDirections() {
    return _directionsBox.values
        .where((d) => !d.isArchived)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
  
  /// Get all directions including archived
  List<Direction> getAllDirections() {
    return _directionsBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
  
  /// Get direction by ID
  Direction? getDirection(String id) {
    try {
      return _directionsBox.values.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
  
  /// Check if user can add more directions
  bool canAddDirection() {
    return getActiveDirections().length < maxDirections;
  }
  
  /// Get count of active directions
  int getActiveCount() {
    return getActiveDirections().length;
  }
  
  /// Create a new direction
  Future<Direction> createDirection({
    required String title,
    required DirectionType type,
    required bool reflectionEnabled,
  }) async {
    if (!canAddDirection()) {
      throw Exception('Maximum $maxDirections directions allowed');
    }
    
    final direction = Direction(
      id: _uuid.v4(),
      title: title.trim().substring(0, title.length.clamp(0, 50)),
      type: type,
      reflectionEnabled: reflectionEnabled,
      createdAt: DateTime.now(),
    );
    
    await _directionsBox.put(direction.id, direction);
    return direction;
  }
  
  /// Update a direction
  Future<void> updateDirection(Direction direction) async {
    await _directionsBox.put(direction.id, direction);
  }
  
  /// Archive a direction (soft delete)
  Future<void> archiveDirection(String id) async {
    final direction = getDirection(id);
    if (direction != null) {
      await _directionsBox.put(id, direction.copyWith(isArchived: true));
    }
  }
  
  /// Restore an archived direction
  Future<void> restoreDirection(String id) async {
    final direction = getDirection(id);
    if (direction != null && canAddDirection()) {
      await _directionsBox.put(id, direction.copyWith(isArchived: false));
    }
  }
  
  /// Permanently delete a direction and its connections
  Future<void> deleteDirection(String id) async {
    // Delete all connections first
    final connectionsToDelete = _connectionsBox.values
        .where((c) => c.directionId == id)
        .toList();
    for (final connection in connectionsToDelete) {
      await _connectionsBox.delete(connection.id);
    }
    
    // Delete the direction
    await _directionsBox.delete(id);
  }
  
  // ============ CONNECTIONS ============
  
  /// Connect an entry to a direction
  Future<DirectionConnection> connectEntry({
    required String directionId,
    required String entryId,
  }) async {
    // Check if already connected
    final existing = _connectionsBox.values.where(
      (c) => c.directionId == directionId && c.entryId == entryId,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }
    
    final connection = DirectionConnection(
      id: _uuid.v4(),
      directionId: directionId,
      entryId: entryId,
      createdAt: DateTime.now(),
    );
    
    await _connectionsBox.put(connection.id, connection);
    return connection;
  }
  
  /// Disconnect an entry from a direction
  Future<void> disconnectEntry({
    required String directionId,
    required String entryId,
  }) async {
    final toDelete = _connectionsBox.values.where(
      (c) => c.directionId == directionId && c.entryId == entryId,
    ).toList();
    
    for (final connection in toDelete) {
      await _connectionsBox.delete(connection.id);
    }
  }
  
  /// Check if entry is connected to direction
  bool isEntryConnected(String directionId, String entryId) {
    return _connectionsBox.values.any(
      (c) => c.directionId == directionId && c.entryId == entryId,
    );
  }
  
  /// Get all entries connected to a direction
  List<Entry> getConnectedEntries(String directionId) {
    final entryIds = _connectionsBox.values
        .where((c) => c.directionId == directionId)
        .map((c) => c.entryId)
        .toSet();
    
    return _entryService.getAllEntries()
        .where((e) => entryIds.contains(e.id))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // newest first
  }
  
  /// Get all directions connected to an entry
  List<Direction> getDirectionsForEntry(String entryId) {
    final directionIds = _connectionsBox.values
        .where((c) => c.entryId == entryId)
        .map((c) => c.directionId)
        .toSet();
    
    return getActiveDirections()
        .where((d) => directionIds.contains(d.id))
        .toList();
  }
  
  /// Get recent unconnected entries (for connection picker)
  List<Entry> getUnconnectedEntries(String directionId, {int limit = 20}) {
    final connectedIds = _connectionsBox.values
        .where((c) => c.directionId == directionId)
        .map((c) => c.entryId)
        .toSet();
    
    return _entryService.getAllEntries()
        .where((e) => !connectedIds.contains(e.id))
        .take(limit)
        .toList();
  }
  
  // ============ STATISTICS ============
  
  /// Get connection count for a direction
  int getConnectionCount(String directionId) {
    return _connectionsBox.values
        .where((c) => c.directionId == directionId)
        .length;
  }
  
  /// Get monthly connection count for a direction
  int getMonthlyConnectionCount(String directionId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    return _connectionsBox.values
        .where((c) => 
            c.directionId == directionId && 
            c.createdAt.isAfter(startOfMonth))
        .length;
  }
  
  /// Get average mood when connected to a direction
  double getAverageMoodWhenConnected(String directionId) {
    final entries = getConnectedEntries(directionId);
    if (entries.isEmpty) return 0.0;
    
    final sum = entries.fold<double>(0.0, (sum, e) => sum + e.moodValue);
    return sum / entries.length;
  }
  
  /// Get overall average mood (all entries)
  double getOverallAverageMood() {
    final entries = _entryService.getAllEntries();
    if (entries.isEmpty) return 0.0;
    
    final sum = entries.fold<double>(0.0, (sum, e) => sum + e.moodValue);
    return sum / entries.length;
  }
  
  /// Get complete stats for a direction
  DirectionStats getStats(String directionId) {
    final connectedEntries = getConnectedEntries(directionId);
    final avgConnected = connectedEntries.isEmpty 
        ? 0.0 
        : connectedEntries.fold<double>(0.0, (sum, e) => sum + e.moodValue) / connectedEntries.length;
    
    return DirectionStats(
      totalConnections: getConnectionCount(directionId),
      monthlyConnections: getMonthlyConnectionCount(directionId),
      avgMoodWhenConnected: avgConnected,
      overallAvgMood: getOverallAverageMood(),
      recentEntries: connectedEntries.take(5).toList(),
    );
  }
  
  // ============ REFLECTION INTEGRATION ============
  
  /// Get directions that have reflection enabled
  List<Direction> getDirectionsWithReflection() {
    return getActiveDirections()
        .where((d) => d.reflectionEnabled)
        .toList();
  }
  
  /// Get a random reflection question from enabled directions
  /// Returns null if no directions have reflection enabled
  String? getDailyDirectionQuestion() {
    final enabledDirections = getDirectionsWithReflection();
    if (enabledDirections.isEmpty) return null;
    
    // Pick random direction
    enabledDirections.shuffle();
    final direction = enabledDirections.first;
    
    // Pick random question from that direction
    final questions = direction.type.reflectionQuestions;
    questions.shuffle();
    
    return questions.first;
  }
  
  /// Get the direction associated with a reflection question
  Direction? getDirectionForQuestion(String question) {
    for (final direction in getDirectionsWithReflection()) {
      if (direction.type.reflectionQuestions.contains(question)) {
        return direction;
      }
    }
    return null;
  }
  
  // ============ INSIGHTS INTEGRATION ============
  
  /// Get directions connected 5+ times this week
  List<Direction> getFrequentDirectionsThisWeek() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final frequentIds = <String, int>{};
    for (final connection in _connectionsBox.values) {
      if (connection.createdAt.isAfter(weekAgo)) {
        frequentIds[connection.directionId] = 
            (frequentIds[connection.directionId] ?? 0) + 1;
      }
    }
    
    return frequentIds.entries
        .where((e) => e.value >= 5)
        .map((e) => getDirection(e.key))
        .whereType<Direction>()
        .where((d) => !d.isArchived)
        .toList();
  }
  
  /// Get directions not connected in 7+ days
  List<Direction> getDormantDirections() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    return getActiveDirections().where((d) {
      final lastConnection = _connectionsBox.values
          .where((c) => c.directionId == d.id)
          .fold<DateTime?>(null, (latest, c) {
            if (latest == null || c.createdAt.isAfter(latest)) {
              return c.createdAt;
            }
            return latest;
          });
      
      return lastConnection == null || lastConnection.isBefore(weekAgo);
    }).toList();
  }
  
  /// Get directions with significant mood correlation
  List<MapEntry<Direction, double>> getDirectionsWithMoodCorrelation() {
    final overallAvg = getOverallAverageMood();
    
    return getActiveDirections()
        .map((d) {
          final avg = getAverageMoodWhenConnected(d.id);
          final diff = avg - overallAvg;
          return MapEntry(d, diff);
        })
        .where((e) => e.value.abs() >= 0.1) // significant correlation
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // highest first
  }
}
```

---

## Hive Registration

### Update `main.dart` initialization

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'models/direction.dart';
import 'models/direction_connection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  // Register existing adapters...
  // Hive.registerAdapter(EntryAdapter());
  // etc.
  
  // Register Direction adapters
  Hive.registerAdapter(DirectionTypeAdapter());
  Hive.registerAdapter(DirectionAdapter());
  Hive.registerAdapter(DirectionConnectionAdapter());
  
  // Initialize services
  final entryService = EntryService();
  await entryService.init();
  
  final directionService = DirectionService(entryService);
  await directionService.init();
  
  runApp(MyApp(
    entryService: entryService,
    directionService: directionService,
  ));
}
```

**Remember to run:** `flutter packages pub run build_runner build` to generate Hive adapters.

---

## Screens

### File: `lib/screens/directions_screen.dart`

Main tab showing all directions with stats cards.

```dart
import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../services/direction_service.dart';
import '../widgets/direction_card.dart';
import 'create_direction_screen.dart';
import 'direction_detail_screen.dart';

class DirectionsScreen extends StatefulWidget {
  final DirectionService directionService;
  
  const DirectionsScreen({
    super.key,
    required this.directionService,
  });
  
  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  List<Direction> _directions = [];
  
  @override
  void initState() {
    super.initState();
    _loadDirections();
  }
  
  void _loadDirections() {
    setState(() {
      _directions = widget.directionService.getActiveDirections();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final canAdd = widget.directionService.canAddDirection();
    final activeCount = widget.directionService.getActiveCount();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directions'),
        actions: [
          if (canAdd)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _navigateToCreate,
            ),
        ],
      ),
      body: _directions.isEmpty
          ? _buildEmptyState()
          : _buildDirectionsList(canAdd, activeCount),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🧭',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'What matters to you?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Directions help you see how your mood connects to the things you care about.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _navigateToCreate,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Direction'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDirectionsList(bool canAdd, int activeCount) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header text
        Text(
          'Your life compass. Connect your daily check-ins to see patterns.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        
        // Direction cards
        ..._directions.map((direction) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DirectionCard(
            direction: direction,
            stats: widget.directionService.getStats(direction.id),
            onTap: () => _navigateToDetail(direction),
          ),
        )),
        
        // Add direction card
        if (canAdd)
          _buildAddCard(activeCount),
      ],
    );
  }
  
  Widget _buildAddCard(int activeCount) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: _navigateToCreate,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 20),
              const SizedBox(width: 8),
              Text('Add direction ($activeCount of 5)'),
            ],
          ),
        ),
      ),
    );
  }
  
  void _navigateToCreate() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDirectionScreen(
          directionService: widget.directionService,
        ),
      ),
    );
    
    if (result == true) {
      _loadDirections();
    }
  }
  
  void _navigateToDetail(Direction direction) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectionDetailScreen(
          direction: direction,
          directionService: widget.directionService,
        ),
      ),
    );
    
    _loadDirections(); // Refresh in case of changes
  }
}
```

### File: `lib/screens/create_direction_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../services/direction_service.dart';

class CreateDirectionScreen extends StatefulWidget {
  final DirectionService directionService;
  
  const CreateDirectionScreen({
    super.key,
    required this.directionService,
  });
  
  @override
  State<CreateDirectionScreen> createState() => _CreateDirectionScreenState();
}

class _CreateDirectionScreenState extends State<CreateDirectionScreen> {
  DirectionType? _selectedType;
  final _titleController = TextEditingController();
  bool _reflectionEnabled = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
  
  bool get _canCreate =>
      _selectedType != null && _titleController.text.trim().isNotEmpty;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Direction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selection
            Text(
              'What area of life?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildTypeGrid(),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            // Title input
            Text(
              'Describe it in your words:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              maxLength: 50,
              decoration: const InputDecoration(
                hintText: 'e.g., Feel strong and rested',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            
            // Examples
            if (_selectedType != null) ...[
              const SizedBox(height: 8),
              Text(
                'Examples:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              ..._selectedType!.examples.map((example) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• "$example"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              )),
            ],
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            // Reflection toggle
            SwitchListTile(
              title: const Text('Enable reflection questions'),
              subtitle: const Text(
                'Ask about this direction during check-ins',
              ),
              value: _reflectionEnabled,
              onChanged: (value) => setState(() => _reflectionEnabled = value),
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 32),
            
            // Create button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canCreate ? _create : null,
                child: const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTypeGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: DirectionType.values.map((type) {
        final isSelected = _selectedType == type;
        return InkWell(
          onTap: () => setState(() => _selectedType = type),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  type.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  type.label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Future<void> _create() async {
    if (!_canCreate) return;
    
    await widget.directionService.createDirection(
      title: _titleController.text.trim(),
      type: _selectedType!,
      reflectionEnabled: _reflectionEnabled,
    );
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}
```

### File: `lib/screens/direction_detail_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../models/direction_stats.dart';
import '../services/direction_service.dart';
import 'connect_entries_screen.dart';
import 'entry_detail_screen.dart';

class DirectionDetailScreen extends StatefulWidget {
  final Direction direction;
  final DirectionService directionService;
  
  const DirectionDetailScreen({
    super.key,
    required this.direction,
    required this.directionService,
  });
  
  @override
  State<DirectionDetailScreen> createState() => _DirectionDetailScreenState();
}

class _DirectionDetailScreenState extends State<DirectionDetailScreen> {
  late Direction _direction;
  late DirectionStats _stats;
  
  @override
  void initState() {
    super.initState();
    _direction = widget.direction;
    _loadStats();
  }
  
  void _loadStats() {
    setState(() {
      _stats = widget.directionService.getStats(_direction.id);
      // Reload direction in case it was updated
      _direction = widget.directionService.getDirection(_direction.id) ?? _direction;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_direction.emoji),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _direction.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overview card
          _buildOverviewCard(),
          const SizedBox(height: 16),
          
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
          
          // Archive button
          _buildArchiveButton(),
        ],
      ),
    );
  }
  
  Widget _buildOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OVERVIEW',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey,
              ),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${_stats.totalConnections}',
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${_stats.monthlyConnections}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _stats.monthlyProgress,
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
  
  Widget _buildMoodCorrelationCard() {
    final hasData = _stats.totalConnections > 0;
    final diff = _stats.moodDifference;
    final isPositive = diff >= 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MOOD CORRELATION',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            if (!hasData)
              Text(
                'Connect more entries to see mood patterns.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
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
                          '${_stats.avgMoodWhenConnected.toStringAsFixed(2)} ${_getMoodEmoji(_stats.avgMoodWhenConnected)}',
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
                          _stats.overallAvgMood.toStringAsFixed(2),
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
                  color: (isPositive ? Colors.green : Colors.orange).withOpacity(0.1),
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
    if (_stats.recentEntries.isEmpty) {
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
          ..._stats.recentEntries.map((entry) => ListTile(
            leading: Text(
              entry.moodEmoji,
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(entry.intention ?? 'No intention'),
            subtitle: Text(_formatDate(entry.timestamp)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToEntry(entry),
          )),
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey,
              ),
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
  
  Widget _buildArchiveButton() {
    return TextButton.icon(
      onPressed: _confirmArchive,
      icon: const Icon(Icons.archive_outlined),
      label: const Text('Archive this direction'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey,
      ),
    );
  }
  
  String _getMoodEmoji(double value) {
    if (value >= 0.8) return '😄';
    if (value >= 0.6) return '😊';
    if (value >= 0.4) return '😐';
    if (value >= 0.2) return '😔';
    return '😢';
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
        builder: (context) => ConnectEntriesScreen(
          direction: _direction,
          directionService: widget.directionService,
        ),
      ),
    );
    
    if (result == true) {
      _loadStats();
    }
  }
  
  void _navigateToEntry(entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryDetailScreen(
          entry: entry,
          // Pass other required services...
        ),
      ),
    );
  }
  
  void _toggleReflection(bool value) async {
    final updated = _direction.copyWith(reflectionEnabled: value);
    await widget.directionService.updateDirection(updated);
    _loadStats();
  }
  
  void _confirmArchive() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive direction?'),
        content: Text(
          'This will hide "${_direction.title}" from your directions. Your connections will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.directionService.archiveDirection(_direction.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to list
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}
```

### File: `lib/screens/connect_entries_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../models/entry.dart';
import '../services/direction_service.dart';

class ConnectEntriesScreen extends StatefulWidget {
  final Direction direction;
  final DirectionService directionService;
  
  const ConnectEntriesScreen({
    super.key,
    required this.direction,
    required this.directionService,
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
  
  void _loadEntries() {
    setState(() {
      if (_showConnected) {
        _entries = widget.directionService.getConnectedEntries(widget.direction.id);
      } else {
        _entries = widget.directionService.getUnconnectedEntries(widget.direction.id);
      }
    });
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
                        title: Text(entry.intention ?? 'No intention'),
                        subtitle: Text(_formatDate(entry.timestamp)),
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
      await widget.directionService.connectEntry(
        directionId: widget.direction.id,
        entryId: entryId,
      );
    }
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}
```

---

## Widgets

### File: `lib/widgets/direction_card.dart`

```dart
import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../models/direction_stats.dart';

class DirectionCard extends StatelessWidget {
  final Direction direction;
  final DirectionStats stats;
  final VoidCallback onTap;
  
  const DirectionCard({
    super.key,
    required this.direction,
    required this.stats,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Text(
                    direction.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      direction.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Stats row
              Text(
                '${stats.totalConnections} connections',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              const SizedBox(height: 8),
              
              // Monthly progress
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: stats.monthlyProgress,
                      backgroundColor: Theme.of(context).dividerColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${stats.monthlyConnections} this month',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              // Mood correlation (if data available)
              if (stats.totalConnections >= 3) ...[
                const SizedBox(height: 8),
                Text(
                  'Avg mood: ${stats.avgMoodWhenConnected.toStringAsFixed(2)} ${_getMoodEmoji(stats.avgMoodWhenConnected)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
              
              // Reflection indicator
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reflection questions: ${direction.reflectionEnabled ? "On" : "Off"}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getMoodEmoji(double value) {
    if (value >= 0.8) return '😄';
    if (value >= 0.6) return '😊';
    if (value >= 0.4) return '😐';
    if (value >= 0.2) return '😔';
    return '😢';
  }
}
```

---

## Insights Integration

Add these insight rules to your existing `InsightsService`:

```dart
// In insight generation logic, add these rules:

// Priority 15: Direction connected 5+ times this week
final frequentDirections = directionService.getFrequentDirectionsThisWeek();
for (final direction in frequentDirections) {
  insights.add(Insight(
    priority: 15,
    icon: '🧭',
    text: '\'${direction.title}\' showed up ${_getWeeklyCount(direction.id)} times this week. It\'s clearly important to you.',
  ));
}

// Priority 16: High mood correlation (≥0.15 difference)
final positiveCorrelations = directionService.getDirectionsWithMoodCorrelation()
    .where((e) => e.value >= 0.15);
for (final entry in positiveCorrelations) {
  insights.add(Insight(
    priority: 16,
    icon: '✨',
    text: 'Your mood is higher when \'${entry.key.title}\' is part of your day.',
  ));
}

// Priority 17: Low mood correlation (≤-0.1 difference)
final negativeCorrelations = directionService.getDirectionsWithMoodCorrelation()
    .where((e) => e.value <= -0.1);
for (final entry in negativeCorrelations) {
  insights.add(Insight(
    priority: 17,
    icon: '💭',
    text: '\'${entry.key.title}\' often comes up on tougher days. Worth reflecting on.',
  ));
}

// Priority 18: Direction not connected in 7+ days
final dormantDirections = directionService.getDormantDirections();
for (final direction in dormantDirections) {
  insights.add(Insight(
    priority: 18,
    icon: '🌱',
    text: 'Haven\'t connected to \'${direction.title}\' lately. Still matters?',
  ));
}
```

---

## Entry Detail Integration

Add direction chips to the Entry Detail screen:

```dart
// In EntryDetailScreen, add a section for directions:

Widget _buildDirectionSection() {
  final directions = directionService.getDirectionsForEntry(entry.id);
  final allDirections = directionService.getActiveDirections();
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Connected to:',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.grey,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Connected directions
          ...directions.map((d) => Chip(
            avatar: Text(d.emoji),
            label: Text(d.title),
            onDeleted: () => _disconnectDirection(d),
          )),
          
          // Add button
          ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
            onPressed: () => _showDirectionPicker(allDirections, directions),
          ),
        ],
      ),
    ],
  );
}
```

---

## Testing Checklist

- [ ] Create direction (all 6 types)
- [ ] Respect 5 direction limit
- [ ] Connect entries from Directions tab
- [ ] Connect entries from Entry Detail
- [ ] View stats: total, monthly, mood correlation
- [ ] Toggle reflection questions
- [ ] Archive direction
- [ ] Direction-specific insights appear
- [ ] Reflection questions from enabled directions appear in check-in
- [ ] Empty states display correctly
- [ ] Navigation works (tab, detail, back)

---

## Colors & Styling

Use existing Elio theme colors:
- Background: Warm Charcoal (#1C1C1E)
- Accent: Soft Cream (#F9DFC1)
- CTA: Warm Orange (#FF6436)
- Progress bars: Use theme primary with lowered opacity for background
- Cards: Use theme surface color with subtle border

---

## Implementation Order

✅ All steps completed:

1. ✅ **Models** — Direction, DirectionConnection, DirectionStats
2. ✅ **Hive setup** — Manual adapters (typeIds 4, 5, 6), box registration
3. ✅ **DirectionService** — CRUD, connections, stats
4. ✅ **DirectionsScreen** — Main tab with cards
5. ✅ **CreateDirectionScreen** — Type picker + title input
6. ✅ **DirectionDetailScreen** — Stats, connections, settings
7. ✅ **ConnectEntriesScreen** — Multi-select entry picker
8. ✅ **DirectionCard widget** — Reusable card component
9. ✅ **Navigation update** — Add Directions tab (5 tabs total)
10. ⏸️ **Entry Detail integration** — Direction chips (Future Phase 2)
11. ⏸️ **Reflection integration** — Direction questions in check-in (Future Phase 2)
12. ✅ **Insights integration** — Direction-based insights (Priorities 15-18)

---

## 🎉 Implementation Complete

### What Was Built

**Files Created:**
- `lib/models/direction.dart` - Direction model + DirectionType enum + manual adapters
- `lib/models/direction_connection.dart` - Connection model + manual adapter
- `lib/models/direction_stats.dart` - Stats model (non-Hive)
- `lib/services/direction_service.dart` - Complete service layer
- `lib/screens/directions_screen.dart` - Main Directions tab
- `lib/screens/create_direction_screen.dart` - Create direction flow
- `lib/screens/direction_detail_screen.dart` - Detail view with stats
- `lib/screens/connect_entries_screen.dart` - Multi-select connection UI
- `lib/widgets/direction_card.dart` - Reusable direction card

**Files Modified:**
- `lib/main.dart` - Added DirectionService initialization
- `lib/models/entry.dart` - Added moodEmoji extension method
- `lib/screens/home_shell.dart` - Updated to 5 tabs with Directions at index 2
- `lib/services/insights_service.dart` - Added direction insights (priorities 15-18)

### Testing Checklist

Before merging, verify:

- [ ] Create direction (all 6 types)
- [ ] Respect 5 direction limit
- [ ] Connect entries from Directions tab
- [ ] View stats: total, monthly, mood correlation
- [ ] Toggle reflection questions
- [ ] Archive direction
- [ ] Direction-specific insights appear in weekly view
- [ ] Empty states display correctly
- [ ] Navigation works (5 tabs)
- [ ] No compilation errors (`flutter analyze`)

### Known Limitations

**Not Implemented (Phase 2):**
- Direction chips in Entry Detail screen
- Direction-specific reflection questions during check-in flow
- These were designed but deferred to keep scope manageable

**Future Enhancements:**
- Edit direction title/settings
- Reorder directions
- Direction templates/presets
- Export direction data
- Direction-based goals/milestones

### Migration Notes

**For Existing Users:**
- No migration needed - new feature is opt-in
- Existing entries remain unchanged
- No breaking changes to current functionality

**For New Installs:**
- DirectionService automatically initializes
- No seed data - starts empty
- User must manually create first direction

---

*This specification was implemented by Claude Code on February 9, 2026.*
