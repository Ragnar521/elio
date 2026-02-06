import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/entry.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const _entriesBoxName = 'entries';
  static const _settingsBoxName = 'settings';
  static const _uuid = Uuid();
  static const _userNameKey = 'user_name';
  static const _onboardingCompletedKey = 'onboarding_completed';
  static const _notificationsEnabledKey = 'notifications_enabled';

  Box<Entry>? _entriesBox;
  Box<dynamic>? _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(EntryAdapter().typeId)) {
      Hive.registerAdapter(EntryAdapter());
    }
    _entriesBox = await Hive.openBox<Entry>(_entriesBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
  }

  Future<Entry> saveEntry({
    required double moodValue,
    required String moodWord,
    required String intention,
  }) async {
    final entry = Entry(
      id: _uuid.v4(),
      moodValue: moodValue,
      moodWord: moodWord,
      intention: intention,
      createdAt: DateTime.now(),
    );
    await _box.put(entry.id, entry);
    return entry;
  }

  Future<List<Entry>> getAllEntries() async {
    final entries = _box.values.toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<List<Entry>> getEntriesForDate(DateTime date) async {
    final target = _dateOnly(date);
    final entries = _box.values.where((entry) {
      return _dateOnly(entry.createdAt) == target;
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
}
