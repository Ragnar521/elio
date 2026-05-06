import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/entry.dart';
import '../models/direction.dart';
import '../models/direction_connection.dart';
import '../models/reflection_answer.dart';
import '../models/reflection_question.dart';
import '../models/weekly_summary.dart';
import 'reflection_service.dart';

class ReflectionAnswerDraft {
  const ReflectionAnswerDraft({
    required this.questionId,
    required this.questionText,
    required this.answer,
  });

  final String questionId;
  final String questionText;
  final String answer;
}

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const _entriesBoxName = 'entries';
  static const _settingsBoxName = 'settings';
  static const _uuid = Uuid();
  static const _userNameKey = 'user_name';
  static const _onboardingCompletedKey = 'onboarding_completed';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _reflectionEnabledKey = 'reflection_enabled';
  static const _longestStreakKey = 'longest_streak';
  static const _launcherCompletedKey = 'launcher_completed';

  Box<Entry>? _entriesBox;
  Box<dynamic>? _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(EntryAdapter().typeId)) {
      Hive.registerAdapter(EntryAdapter());
    }
    _entriesBox = await Hive.openBox<Entry>(_entriesBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);

    // Backfill longest streak on first run
    await _backfillLongestStreak();

    // Cleanup old soft-deleted entries
    await _permanentDeleteOldEntries();
  }

  Future<Entry> saveEntry({
    required double moodValue,
    required String moodWord,
    required String intention,
    List<String>? reflectionAnswerIds,
  }) async {
    final entry = Entry(
      id: _uuid.v4(),
      moodValue: moodValue,
      moodWord: moodWord,
      intention: intention,
      createdAt: DateTime.now(),
      reflectionAnswerIds: reflectionAnswerIds,
    );
    await _box.put(entry.id, entry);

    // Update longest streak if current streak is higher
    final currentStreak = await getCurrentStreak();
    await updateLongestStreak(currentStreak);

    return entry;
  }

  Future<Entry> saveEntryWithReflectionAnswers({
    required double moodValue,
    required String moodWord,
    required String intention,
    required List<ReflectionAnswerDraft> reflectionAnswers,
  }) async {
    final entry = Entry(
      id: _uuid.v4(),
      moodValue: moodValue,
      moodWord: moodWord,
      intention: intention,
      createdAt: DateTime.now(),
    );
    final answerIds = <String>[];

    try {
      await _box.put(entry.id, entry);

      for (final draft in reflectionAnswers) {
        final answer = await ReflectionService.instance.saveAnswer(
          entryId: entry.id,
          questionId: draft.questionId,
          questionText: draft.questionText,
          answer: draft.answer,
        );
        answerIds.add(answer.id);
      }

      final updatedEntry = Entry(
        id: entry.id,
        moodValue: entry.moodValue,
        moodWord: entry.moodWord,
        intention: entry.intention,
        createdAt: entry.createdAt,
        reflectionAnswerIds: answerIds,
      );
      await _box.put(entry.id, updatedEntry);

      final currentStreak = await getCurrentStreak();
      await updateLongestStreak(currentStreak);

      return updatedEntry;
    } catch (_) {
      for (final answerId in answerIds) {
        await ReflectionService.instance.deleteAnswer(answerId);
      }
      await _box.delete(entry.id);
      rethrow;
    }
  }

  Future<List<Entry>> getAllEntries() async {
    final entries = _box.values.where((entry) => !entry.isDeleted).toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<List<Entry>> getEntriesForDate(DateTime date) async {
    final target = _dateOnly(date);
    final entries = _box.values.where((entry) {
      return _dateOnly(entry.createdAt) == target && !entry.isDeleted;
    }).toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<int> getEntryCount() async {
    return _box.length;
  }

  Future<int> getCurrentStreak() async {
    final entries = await getAllEntries();
    if (entries.isEmpty) return 0;

    final daysWithEntries = <DateTime>{};
    for (final entry in entries) {
      daysWithEntries.add(_dateOnly(entry.createdAt));
    }

    var streak = 0;
    var currentDay = _dateOnly(DateTime.now());

    while (daysWithEntries.contains(currentDay)) {
      streak += 1;
      currentDay = currentDay.subtract(const Duration(days: 1));
    }

    return streak;
  }

  DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  Box<Entry> get _box {
    final box = _entriesBox;
    if (box == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return box;
  }

  Box<dynamic> get _settings {
    final box = _settingsBox;
    if (box == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return box;
  }

  String get userName {
    final value = _settings.get(_userNameKey, defaultValue: 'there');
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return 'there';
  }

  Future<void> setUserName(String name) async {
    final trimmed = name.trim();
    await _settings.put(_userNameKey, trimmed.isEmpty ? 'there' : trimmed);
  }

  bool get onboardingCompleted {
    final value = _settings.get(_onboardingCompletedKey, defaultValue: false);
    return value is bool ? value : false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _settings.put(_onboardingCompletedKey, completed);
  }

  bool get notificationsEnabled {
    final value = _settings.get(_notificationsEnabledKey, defaultValue: false);
    return value is bool ? value : false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settings.put(_notificationsEnabledKey, enabled);
  }

  bool get reflectionEnabled {
    final value = _settings.get(_reflectionEnabledKey, defaultValue: true);
    return value is bool ? value : true;
  }

  Future<void> setReflectionEnabled(bool enabled) async {
    await _settings.put(_reflectionEnabledKey, enabled);
  }

  bool get launcherCompleted {
    final value = _settings.get(_launcherCompletedKey, defaultValue: false);
    return value is bool ? value : false;
  }

  Future<void> setLauncherCompleted(bool completed) async {
    await _settings.put(_launcherCompletedKey, completed);
  }

  Future<int> getLongestStreak() async {
    final value = _settings.get(_longestStreakKey, defaultValue: 0);
    return value is int ? value : 0;
  }

  Future<void> updateLongestStreak(int currentStreak) async {
    final longest = await getLongestStreak();
    if (currentStreak > longest) {
      await _settings.put(_longestStreakKey, currentStreak);
    }
  }

  Future<List<Entry>> getEntriesForPeriod(DateTime start, DateTime end) async {
    final entries = _box.values.where((entry) {
      return !entry.createdAt.isBefore(start) &&
          entry.createdAt.isBefore(end) &&
          !entry.isDeleted;
    }).toList();
    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries;
  }

  Entry? getEntry(String id) {
    return _box.get(id);
  }

  Future<void> updateEntry(Entry entry) async {
    final updated = Entry(
      id: entry.id,
      moodValue: entry.moodValue,
      moodWord: entry.moodWord,
      intention: entry.intention,
      createdAt: entry.createdAt,
      reflectionAnswerIds: entry.reflectionAnswerIds,
      isDeleted: entry.isDeleted,
      deletedAt: entry.deletedAt,
      updatedAt: DateTime.now(),
    );
    await _box.put(entry.id, updated);
  }

  Future<void> softDeleteEntry(String entryId) async {
    final entry = _box.get(entryId);
    if (entry == null) return;

    final deleted = Entry(
      id: entry.id,
      moodValue: entry.moodValue,
      moodWord: entry.moodWord,
      intention: entry.intention,
      createdAt: entry.createdAt,
      reflectionAnswerIds: entry.reflectionAnswerIds,
      isDeleted: true,
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _box.put(entryId, deleted);
  }

  Future<void> restoreEntry(String entryId) async {
    final entry = _box.get(entryId);
    if (entry == null || !entry.isDeleted) return;

    final restored = Entry(
      id: entry.id,
      moodValue: entry.moodValue,
      moodWord: entry.moodWord,
      intention: entry.intention,
      createdAt: entry.createdAt,
      reflectionAnswerIds: entry.reflectionAnswerIds,
      isDeleted: false,
      deletedAt: null,
      updatedAt: DateTime.now(),
    );
    await _box.put(entryId, restored);
  }

  Future<void> _permanentDeleteOldEntries() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final entriesToDelete = _box.values.where((entry) {
      return entry.isDeleted &&
          entry.deletedAt != null &&
          entry.deletedAt!.isBefore(cutoffDate);
    }).toList();

    for (final entry in entriesToDelete) {
      // Delete associated reflection answers
      await ReflectionService.instance.deleteAnswersForEntry(entry.id);
      // Delete the entry itself
      await _box.delete(entry.id);
    }
  }

  Future<void> _backfillLongestStreak() async {
    // Only backfill if longest streak hasn't been set yet
    final existing = _settings.get(_longestStreakKey);
    if (existing != null) return;

    // Calculate longest streak from all entries
    final entries = await getAllEntries();
    if (entries.isEmpty) return;

    final daysWithEntries = <DateTime>{};
    for (final entry in entries) {
      daysWithEntries.add(_dateOnly(entry.createdAt));
    }

    // Find longest consecutive streak in history
    final sortedDays = daysWithEntries.toList()..sort();
    var longestStreak = 0;
    var currentStreak = 1;

    for (var i = 1; i < sortedDays.length; i++) {
      final diff = sortedDays[i].difference(sortedDays[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
      } else {
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
        currentStreak = 1;
      }
    }

    // Check final streak
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    await _settings.put(_longestStreakKey, longestStreak);
  }

  /// Wipe all app data — used by triple-tap reset to return to launcher
  Future<void> wipeAllData() async {
    // Clear data boxes via Hive.openBox (boxes may already be open — openBox returns existing instance)
    final entriesBox = await Hive.openBox<Entry>('entries');
    await entriesBox.clear();

    final answersBox = await Hive.openBox<ReflectionAnswer>(
      'reflectionAnswers',
    );
    await answersBox.clear();

    final questionsBox = await Hive.openBox<ReflectionQuestion>(
      'reflectionQuestions',
    );
    await questionsBox.clear();

    final directionsBox = await Hive.openBox<Direction>('directions');
    await directionsBox.clear();

    final connectionsBox = await Hive.openBox<DirectionConnection>(
      'direction_connections',
    );
    await connectionsBox.clear();

    final summariesBox = await Hive.openBox<WeeklySummary>('weekly_summaries');
    await summariesBox.clear();

    // Clear settings LAST (this resets launcher_completed, onboarding_completed, etc.)
    final settingsBox = await Hive.openBox('settings');
    await settingsBox.clear();
  }
}
