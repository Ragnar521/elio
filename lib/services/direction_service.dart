import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/direction.dart';
import '../models/direction_check_in.dart';
import '../models/direction_connection.dart';
import '../models/direction_stats.dart';
import '../models/entry.dart';
import 'storage_service.dart';

class DirectionService {
  DirectionService._();

  static final DirectionService instance = DirectionService._();

  static const String _directionsBoxName = 'directions';
  static const String _connectionsBoxName = 'direction_connections';
  static const String _checkInsBoxName = 'direction_check_ins';

  final Uuid _uuid = const Uuid();
  Box<Direction>? _directionsBox;
  Box<DirectionConnection>? _connectionsBox;
  Box<DirectionCheckIn>? _checkInsBox;

  /// Initialize Hive boxes
  Future<void> init() async {
    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(DirectionTypeAdapter().typeId)) {
      Hive.registerAdapter(DirectionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(DirectionAdapter().typeId)) {
      Hive.registerAdapter(DirectionAdapter());
    }
    if (!Hive.isAdapterRegistered(DirectionConnectionAdapter().typeId)) {
      Hive.registerAdapter(DirectionConnectionAdapter());
    }
    if (!Hive.isAdapterRegistered(DirectionCheckInAdapter().typeId)) {
      Hive.registerAdapter(DirectionCheckInAdapter());
    }

    _directionsBox = await Hive.openBox<Direction>(_directionsBoxName);
    _connectionsBox = await Hive.openBox<DirectionConnection>(
      _connectionsBoxName,
    );
    _checkInsBox = await Hive.openBox<DirectionCheckIn>(_checkInsBoxName);
  }

  Box<Direction> get _directions {
    final box = _directionsBox;
    if (box == null) {
      throw StateError('DirectionService not initialized. Call init() first.');
    }
    return box;
  }

  Box<DirectionConnection> get _connections {
    final box = _connectionsBox;
    if (box == null) {
      throw StateError('DirectionService not initialized. Call init() first.');
    }
    return box;
  }

  Box<DirectionCheckIn>? get _optionalCheckIns {
    if (_checkInsBox != null) return _checkInsBox;
    if (Hive.isBoxOpen(_checkInsBoxName)) {
      _checkInsBox = Hive.box<DirectionCheckIn>(_checkInsBoxName);
      return _checkInsBox;
    }
    return null;
  }

  Future<Box<DirectionCheckIn>> _ensureCheckInsOpen() async {
    if (!Hive.isAdapterRegistered(DirectionCheckInAdapter().typeId)) {
      Hive.registerAdapter(DirectionCheckInAdapter());
    }
    if (_checkInsBox != null) return _checkInsBox!;
    _checkInsBox = await Hive.openBox<DirectionCheckIn>(_checkInsBoxName);
    return _checkInsBox!;
  }

  // ============ DIRECTIONS CRUD ============

  /// Get all visible directions
  List<Direction> getActiveDirections() {
    return _directions.values.where((d) => !d.isArchived).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get all directions, including older archived records
  List<Direction> getAllDirections() {
    return _directions.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get direction by ID
  Direction? getDirection(String id) {
    try {
      return _directions.values.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Check if user can add more directions
  bool canAddDirection() {
    return true;
  }

  /// Get count of active directions
  int getActiveCount() {
    return getActiveDirections().length;
  }

  /// Create a new direction
  Future<Direction> createDirection({
    required String title,
    String description = '',
    String subtasks = '',
    String actionItems = '',
    String blockers = '',
    String supportIdeas = '',
    required DirectionType type,
    required bool reflectionEnabled,
  }) async {
    final trimmedTitle = title.trim();

    final direction = Direction(
      id: _uuid.v4(),
      title: trimmedTitle.substring(0, trimmedTitle.length.clamp(0, 50)),
      description: description.trim(),
      subtasks: subtasks.trim(),
      actionItems: actionItems.trim(),
      blockers: blockers.trim(),
      supportIdeas: supportIdeas.trim(),
      type: type,
      reflectionEnabled: reflectionEnabled,
      createdAt: DateTime.now(),
    );

    await _directions.put(direction.id, direction);
    return direction;
  }

  /// Update a direction
  Future<void> updateDirection(Direction direction) async {
    await _directions.put(direction.id, direction);
  }

  /// Delete a direction. Kept for compatibility with older call sites.
  Future<void> archiveDirection(String id) async {
    await deleteDirection(id);
  }

  /// Restore an archived direction
  Future<void> restoreDirection(String id) async {
    final direction = getDirection(id);
    if (direction != null) {
      await _directions.put(id, direction.copyWith(isArchived: false));
    }
  }

  /// Permanently delete a direction and its connections
  Future<void> deleteDirection(String id) async {
    // Delete all connections first
    final connectionsToDelete = _connections.values
        .where((c) => c.directionId == id)
        .toList();
    for (final connection in connectionsToDelete) {
      await _connections.delete(connection.id);
    }

    final checkInsBox = await _ensureCheckInsOpen();
    final checkInsToDelete = checkInsBox.values
        .where((c) => c.directionId == id)
        .toList();
    for (final checkIn in checkInsToDelete) {
      await checkInsBox.delete(checkIn.id);
    }

    // Delete the direction
    await _directions.delete(id);
  }

  // ============ CONNECTIONS ============

  /// Connect an entry to a direction
  Future<DirectionConnection> connectEntry({
    required String directionId,
    required String entryId,
  }) async {
    // Check if already connected
    final existing = _connections.values.where(
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

    await _connections.put(connection.id, connection);
    return connection;
  }

  /// Disconnect an entry from a direction
  Future<void> disconnectEntry({
    required String directionId,
    required String entryId,
  }) async {
    final toDelete = _connections.values
        .where((c) => c.directionId == directionId && c.entryId == entryId)
        .toList();

    for (final connection in toDelete) {
      await _connections.delete(connection.id);
    }
  }

  /// Record goal presence/progress for a saved entry.
  Future<List<DirectionCheckIn>> recordCheckIns({
    required String entryId,
    required List<DirectionCheckInDraft> drafts,
    Map<String, String> reflectionAnswerIdsByDirectionId = const {},
  }) async {
    final saved = <DirectionCheckIn>[];
    final checkInsBox = await _ensureCheckInsOpen();

    for (final draft in drafts) {
      await connectEntry(directionId: draft.directionId, entryId: entryId);

      final existing = checkInsBox.values
          .where(
            (c) => c.directionId == draft.directionId && c.entryId == entryId,
          )
          .toList();
      final reflectionAnswerId =
          reflectionAnswerIdsByDirectionId[draft.directionId];

      final checkIn = existing.isNotEmpty
          ? DirectionCheckIn(
              id: existing.first.id,
              directionId: existing.first.directionId,
              entryId: existing.first.entryId,
              stepText: draft.stepText?.trim(),
              blockerText: draft.blockerText?.trim(),
              supportText: draft.supportText?.trim(),
              reflectionAnswerId: reflectionAnswerId,
              createdAt: existing.first.createdAt,
            )
          : DirectionCheckIn(
              id: _uuid.v4(),
              directionId: draft.directionId,
              entryId: entryId,
              stepText: draft.stepText?.trim(),
              blockerText: draft.blockerText?.trim(),
              supportText: draft.supportText?.trim(),
              reflectionAnswerId: reflectionAnswerId,
              createdAt: DateTime.now(),
            );

      await checkInsBox.put(checkIn.id, checkIn);
      saved.add(checkIn);
    }

    return saved;
  }

  /// Check if entry is connected to direction
  bool isEntryConnected(String directionId, String entryId) {
    return _connections.values.any(
      (c) => c.directionId == directionId && c.entryId == entryId,
    );
  }

  /// Get all entries connected to a direction
  Future<List<Entry>> getConnectedEntries(String directionId) async {
    final entryIds = _connections.values
        .where((c) => c.directionId == directionId)
        .map((c) => c.entryId)
        .toSet();

    final allEntries = await StorageService.instance.getAllEntries();
    return allEntries.where((e) => entryIds.contains(e.id)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first
  }

  /// Get all directions connected to an entry
  List<Direction> getDirectionsForEntry(String entryId) {
    final directionIds = _connections.values
        .where((c) => c.entryId == entryId)
        .map((c) => c.directionId)
        .toSet();

    return getActiveDirections()
        .where((d) => directionIds.contains(d.id))
        .toList();
  }

  List<DirectionCheckIn> getCheckInsForEntry(String entryId) {
    final box = _optionalCheckIns;
    if (box == null) return [];
    return box.values.where((c) => c.entryId == entryId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<DirectionCheckIn> getCheckInsForDirection(String directionId) {
    final box = _optionalCheckIns;
    if (box == null) return [];
    return box.values.where((c) => c.directionId == directionId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<DirectionCheckIn> getCheckInsForDirectionInPeriod({
    required String directionId,
    required DateTime start,
    required DateTime end,
  }) {
    return getCheckInsForDirection(directionId)
        .where((c) => !c.createdAt.isBefore(start) && c.createdAt.isBefore(end))
        .toList();
  }

  /// Get recent unconnected entries (for connection picker)
  Future<List<Entry>> getUnconnectedEntries(
    String directionId, {
    int limit = 20,
  }) async {
    final connectedIds = _connections.values
        .where((c) => c.directionId == directionId)
        .map((c) => c.entryId)
        .toSet();

    final allEntries = await StorageService.instance.getAllEntries();
    return allEntries
        .where((e) => !connectedIds.contains(e.id))
        .take(limit)
        .toList();
  }

  // ============ STATISTICS ============

  /// Get connection count for a direction
  int getConnectionCount(String directionId) {
    return _connections.values
        .where((c) => c.directionId == directionId)
        .length;
  }

  /// Get monthly connection count for a direction
  int getMonthlyConnectionCount(String directionId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return _connections.values
        .where(
          (c) =>
              c.directionId == directionId && c.createdAt.isAfter(startOfMonth),
        )
        .length;
  }

  int getMonthlyCheckInCount(String directionId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final box = _optionalCheckIns;
    if (box == null) return 0;
    return box.values
        .where(
          (c) =>
              c.directionId == directionId && c.createdAt.isAfter(startOfMonth),
        )
        .length;
  }

  /// Get average mood when connected to a direction
  Future<double> getAverageMoodWhenConnected(String directionId) async {
    final entries = await getConnectedEntries(directionId);
    if (entries.isEmpty) return 0.0;

    final sum = entries.fold<double>(0.0, (sum, e) => sum + e.moodValue);
    return sum / entries.length;
  }

  /// Get overall average mood (all entries)
  Future<double> getOverallAverageMood() async {
    final entries = await StorageService.instance.getAllEntries();
    if (entries.isEmpty) return 0.0;

    final sum = entries.fold<double>(0.0, (sum, e) => sum + e.moodValue);
    return sum / entries.length;
  }

  /// Get complete stats for a direction
  Future<DirectionStats> getStats(String directionId) async {
    final connectedEntries = await getConnectedEntries(directionId);
    final checkIns = getCheckInsForDirection(directionId);
    final avgConnected = connectedEntries.isEmpty
        ? 0.0
        : connectedEntries.fold<double>(0.0, (sum, e) => sum + e.moodValue) /
              connectedEntries.length;

    return DirectionStats(
      totalConnections: getConnectionCount(directionId),
      monthlyConnections: getMonthlyConnectionCount(directionId),
      avgMoodWhenConnected: avgConnected,
      overallAvgMood: await getOverallAverageMood(),
      recentEntries: connectedEntries.take(5).toList(),
      totalGoalCheckIns: checkIns.length,
      monthlyGoalCheckIns: getMonthlyCheckInCount(directionId),
      progressCount: checkIns.where((c) => c.hasStep).length,
      blockerCount: checkIns.where((c) => c.hasBlocker).length,
      recentCheckIns: checkIns.take(5).toList(),
    );
  }

  // ============ REFLECTION INTEGRATION ============

  /// Get directions that have reflection enabled
  List<Direction> getDirectionsWithReflection() {
    return getActiveDirections().where((d) => d.reflectionEnabled).toList();
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
  Future<List<Direction>> getFrequentDirectionsThisWeek() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final frequentIds = <String, int>{};
    for (final connection in _connections.values) {
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

  /// Get connection count for a direction in the past week
  int getWeeklyConnectionCount(String directionId) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return _connections.values
        .where(
          (c) => c.directionId == directionId && c.createdAt.isAfter(weekAgo),
        )
        .length;
  }

  int getWeeklyCheckInCount(String directionId) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final box = _optionalCheckIns;
    if (box == null) return 0;
    return box.values
        .where(
          (c) => c.directionId == directionId && c.createdAt.isAfter(weekAgo),
        )
        .length;
  }

  int getWeeklyProgressCount(String directionId) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final box = _optionalCheckIns;
    if (box == null) return 0;
    return box.values
        .where(
          (c) =>
              c.directionId == directionId &&
              c.createdAt.isAfter(weekAgo) &&
              c.hasStep,
        )
        .length;
  }

  int getWeeklyBlockerCount(String directionId) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final box = _optionalCheckIns;
    if (box == null) return 0;
    return box.values
        .where(
          (c) =>
              c.directionId == directionId &&
              c.createdAt.isAfter(weekAgo) &&
              c.hasBlocker,
        )
        .length;
  }

  List<MapEntry<Direction, int>> getDirectionsWithProgressThisWeek() {
    final entries = <MapEntry<Direction, int>>[];
    for (final direction in getActiveDirections()) {
      final count = getWeeklyProgressCount(direction.id);
      if (count > 0) entries.add(MapEntry(direction, count));
    }
    return entries..sort((a, b) => b.value.compareTo(a.value));
  }

  List<MapEntry<Direction, int>> getDirectionsWithBlockersThisWeek() {
    final entries = <MapEntry<Direction, int>>[];
    for (final direction in getActiveDirections()) {
      final count = getWeeklyBlockerCount(direction.id);
      if (count > 0) entries.add(MapEntry(direction, count));
    }
    return entries..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Get directions not connected in 7+ days
  List<Direction> getDormantDirections() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return getActiveDirections().where((d) {
      final lastConnection = _connections.values
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
  Future<List<MapEntry<Direction, double>>>
  getDirectionsWithMoodCorrelation() async {
    final overallAvg = await getOverallAverageMood();

    final results = <MapEntry<Direction, double>>[];
    for (final d in getActiveDirections()) {
      final avg = await getAverageMoodWhenConnected(d.id);
      final diff = avg - overallAvg;
      results.add(MapEntry(d, diff));
    }

    return results
        .where((e) => e.value.abs() >= 0.1) // significant correlation
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // highest first
  }
}
