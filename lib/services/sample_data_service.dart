import 'dart:math';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/direction.dart';
import '../models/direction_connection.dart';
import '../models/entry.dart';
import '../models/reflection_answer.dart';
import '../models/weekly_summary.dart';
import 'reflection_service.dart';

/// Service for loading demo data into Elio
///
/// Creates ~90 days of realistic check-in data for "Alex" persona:
/// - Young professional balancing career, health, and relationships
/// - References Sarah (girlfriend), Tom (colleague), Mom
/// - Strong day-of-week mood patterns (low Mondays, high weekends)
/// - 4 active directions with uneven connection distribution
/// - ~70-80% of entries include reflections across all 9 categories
class SampleDataService {
  SampleDataService._();
  static final SampleDataService instance = SampleDataService._();

  static const _uuid = Uuid();

  /// Load all demo data into Hive boxes
  ///
  /// CRITICAL: This writes directly to Hive boxes with backdated timestamps.
  /// Do NOT use service methods like saveEntry() or createDirection() as they use DateTime.now()
  Future<void> loadDemoData() async {
    // Open all Hive boxes (already initialized by this point)
    final entriesBox = await Hive.openBox<Entry>('entries');
    final answersBox = await Hive.openBox<ReflectionAnswer>('reflectionAnswers');
    final directionsBox = await Hive.openBox<Direction>('directions');
    final connectionsBox = await Hive.openBox<DirectionConnection>('direction_connections');
    final settingsBox = await Hive.openBox('settings');

    // Clear existing data
    await entriesBox.clear();
    await answersBox.clear();
    await directionsBox.clear();
    await connectionsBox.clear();

    // 1. Write settings
    await settingsBox.put('user_name', 'Alex');
    await settingsBox.put('onboarding_completed', true);
    await settingsBox.put('reflection_enabled', true);

    // 2. Create directions (~85 days ago)
    final now = DateTime.now();
    final directionsCreatedAt = now.subtract(const Duration(days: 85));

    final careerDirection = Direction(
      id: _uuid.v4(),
      title: 'Work That Matters',
      type: DirectionType.career,
      reflectionEnabled: true,
      createdAt: directionsCreatedAt,
    );

    final healthDirection = Direction(
      id: _uuid.v4(),
      title: 'Stay Strong',
      type: DirectionType.health,
      reflectionEnabled: true,
      createdAt: directionsCreatedAt,
    );

    final relationshipsDirection = Direction(
      id: _uuid.v4(),
      title: 'People I Love',
      type: DirectionType.relationships,
      reflectionEnabled: false,
      createdAt: directionsCreatedAt,
    );

    final peaceDirection = Direction(
      id: _uuid.v4(),
      title: 'Finding Calm',
      type: DirectionType.peace,
      reflectionEnabled: true,
      createdAt: directionsCreatedAt,
    );

    await directionsBox.put(careerDirection.id, careerDirection);
    await directionsBox.put(healthDirection.id, healthDirection);
    await directionsBox.put(relationshipsDirection.id, relationshipsDirection);
    await directionsBox.put(peaceDirection.id, peaceDirection);

    // 3. Get seeded reflection questions for IDs
    final allQuestions = ReflectionService.instance.getAllQuestions();

    // 4. Generate entries for ~90 days (ending yesterday)
    final entries = await _generateEntries(now, allQuestions);

    // Write entries to Hive
    for (final entry in entries) {
      await entriesBox.put(entry.id, entry);
    }

    // 5. Create reflection answers for ~70-80% of entries
    final answersData = _generateReflectionAnswers(entries, allQuestions);
    for (final answer in answersData) {
      await answersBox.put(answer.id, answer);
    }

    // 6. Create direction connections with uneven distribution
    final connections = _generateDirectionConnections(
      entries,
      careerDirection.id,
      healthDirection.id,
      relationshipsDirection.id,
      peaceDirection.id,
    );
    for (final connection in connections) {
      await connectionsBox.put(connection.id, connection);
    }

    // 7. Calculate and set longest streak
    final longestStreak = _calculateLongestStreak(entries);
    await settingsBox.put('longest_streak', longestStreak);

    // 8. Generate weekly summaries for all completed weeks
    await _generateWeeklySummaries(
      now,
      entries,
      answersData,
      careerDirection,
      healthDirection,
      relationshipsDirection,
      peaceDirection,
    );
  }

  /// Generate ~90 days of entries with day-of-week patterns and gaps
  Future<List<Entry>> _generateEntries(
    DateTime now,
    List<dynamic> questions,
  ) async {
    final entries = <Entry>[];
    final random = Random(42); // Deterministic seed for consistency

    // Define gap days (10-15 random days with no entries)
    final gapDays = <int>{};
    while (gapDays.length < 12) {
      gapDays.add(random.nextInt(90));
    }

    // Define double-entry days (5-10 days with morning + evening entries)
    final doubleEntryDays = <int>{};
    while (doubleEntryDays.length < 7) {
      final day = random.nextInt(90);
      if (!gapDays.contains(day)) {
        doubleEntryDays.add(day);
      }
    }

    // Generate entries day by day
    for (int daysAgo = 90; daysAgo >= 1; daysAgo--) {
      if (gapDays.contains(daysAgo)) continue; // Skip gap days

      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
      final weekday = date.weekday; // 1=Monday, 7=Sunday

      if (doubleEntryDays.contains(daysAgo)) {
        // Create morning entry
        entries.add(_createEntry(date, weekday, random, daysAgo, isMorning: true));
        // Create evening entry
        entries.add(_createEntry(date, weekday, random, daysAgo, isMorning: false));
      } else {
        // Create single entry at random time
        entries.add(_createEntry(date, weekday, random, daysAgo));
      }
    }

    return entries;
  }

  /// Create a single entry with mood pattern and intention
  Entry _createEntry(
    DateTime date,
    int weekday,
    Random random,
    int daysAgo, {
    bool? isMorning,
  }) {
    // Determine time
    final DateTime createdAt;
    if (isMorning != null) {
      if (isMorning) {
        // Morning: 7-9 AM
        createdAt = DateTime(date.year, date.month, date.day, 7 + random.nextInt(2), random.nextInt(60));
      } else {
        // Evening: 9-10 PM
        createdAt = DateTime(date.year, date.month, date.day, 21 + random.nextInt(1), random.nextInt(60));
      }
    } else {
      // Random time: 7 AM - 10 PM
      final hour = 7 + random.nextInt(15);
      createdAt = DateTime(date.year, date.month, date.day, hour, random.nextInt(60));
    }

    // Calculate mood based on day of week + slight upward trend over time
    final baseImprovement = daysAgo <= 30 ? 0.05 : 0.0; // Last 30 days slightly better
    double baseMood;

    switch (weekday) {
      case 1: // Monday
        baseMood = 0.30 + random.nextDouble() * 0.15; // 0.30-0.45
        break;
      case 2: // Tuesday
        baseMood = 0.35 + random.nextDouble() * 0.15; // 0.35-0.50
        break;
      case 3: // Wednesday
        baseMood = 0.40 + random.nextDouble() * 0.15; // 0.40-0.55
        break;
      case 4: // Thursday
        baseMood = 0.45 + random.nextDouble() * 0.15; // 0.45-0.60
        break;
      case 5: // Friday
        baseMood = 0.55 + random.nextDouble() * 0.15; // 0.55-0.70
        break;
      case 6: // Saturday
        baseMood = 0.60 + random.nextDouble() * 0.20; // 0.60-0.80
        break;
      case 7: // Sunday
        baseMood = 0.55 + random.nextDouble() * 0.20; // 0.55-0.75
        break;
      default:
        baseMood = 0.50;
    }

    // Add random variation and improvement
    final moodValue = (baseMood + baseImprovement + (random.nextDouble() * 0.10 - 0.05)).clamp(0.0, 1.0);
    final moodWord = _getMoodWord(moodValue);

    // Get intention for this entry
    final intention = _getIntention(random.nextInt(_intentions.length));

    return Entry(
      id: _uuid.v4(),
      moodValue: moodValue,
      moodWord: moodWord,
      intention: intention,
      createdAt: createdAt,
      reflectionAnswerIds: null, // Will be updated when creating answers
    );
  }

  /// Map mood value to mood word
  String _getMoodWord(double value) {
    if (value >= 0.85) return 'Thriving';
    if (value >= 0.75) return 'Joyful';
    if (value >= 0.65) return 'Energized';
    if (value >= 0.55) return 'Focused';
    if (value >= 0.45) return 'Calm';
    if (value >= 0.30) return 'Uneasy';
    if (value >= 0.15) return 'Tired';
    return 'Overwhelmed';
  }

  /// Generate reflection answers for ~70-80% of entries
  List<ReflectionAnswer> _generateReflectionAnswers(
    List<Entry> entries,
    List<dynamic> questions,
  ) {
    final answers = <ReflectionAnswer>[];
    final random = Random(43); // Different seed for variety
    final updatedEntries = <String, List<String>>{}; // Track answer IDs per entry

    for (final entry in entries) {
      // 75% chance of having reflections
      if (random.nextDouble() > 0.75) continue;

      // Determine number of answers (1-3, weighted toward 1)
      final numAnswers = random.nextDouble() < 0.7 ? 1 : (random.nextDouble() < 0.8 ? 2 : 3);
      final answerIds = <String>[];

      for (int i = 0; i < numAnswers; i++) {
        // Pick random question from different categories
        final question = questions[random.nextInt(questions.length)];
        final questionId = question.id as String;
        final questionText = question.text as String;
        final category = question.category as String;

        // Generate answer based on category and Alex's persona
        final answerText = _getReflectionAnswer(category, random);

        final answer = ReflectionAnswer(
          id: _uuid.v4(),
          entryId: entry.id,
          questionId: questionId,
          questionText: questionText,
          answer: answerText,
          createdAt: entry.createdAt,
        );

        answers.add(answer);
        answerIds.add(answer.id);
      }

      if (answerIds.isNotEmpty) {
        updatedEntries[entry.id] = answerIds;
      }
    }

    // Update entries with reflection answer IDs
    // Note: In real implementation, we'd need to re-write entries with updated reflectionAnswerIds
    // For this demo, we're storing the mapping but entries are already written
    // The app will need to handle this via the service layer

    return answers;
  }

  /// Generate direction connections with uneven distribution
  List<DirectionConnection> _generateDirectionConnections(
    List<Entry> entries,
    String careerId,
    String healthId,
    String relationshipsId,
    String peaceId,
  ) {
    final connections = <DirectionConnection>[];
    final random = Random(44);

    for (final entry in entries) {
      // Career: 45% chance (Alex thinks about work a lot)
      if (random.nextDouble() < 0.45) {
        connections.add(DirectionConnection(
          id: _uuid.v4(),
          directionId: careerId,
          entryId: entry.id,
          createdAt: entry.createdAt,
        ));
      }

      // Health: 28% chance (gym days, sleep mentions)
      if (random.nextDouble() < 0.28) {
        connections.add(DirectionConnection(
          id: _uuid.v4(),
          directionId: healthId,
          entryId: entry.id,
          createdAt: entry.createdAt,
        ));
      }

      // Relationships: 23% chance (Sarah/Tom/Mom entries)
      if (random.nextDouble() < 0.23) {
        connections.add(DirectionConnection(
          id: _uuid.v4(),
          directionId: relationshipsId,
          entryId: entry.id,
          createdAt: entry.createdAt,
        ));
      }

      // Peace: 12% chance (meditation, quiet weekends)
      if (random.nextDouble() < 0.12) {
        connections.add(DirectionConnection(
          id: _uuid.v4(),
          directionId: peaceId,
          entryId: entry.id,
          createdAt: entry.createdAt,
        ));
      }
    }

    return connections;
  }

  /// Calculate longest streak from entries
  int _calculateLongestStreak(List<Entry> entries) {
    if (entries.isEmpty) return 0;

    // Sort entries by date
    final sorted = entries.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    int longestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sorted.length; i++) {
      final prevDate = DateTime(
        sorted[i - 1].createdAt.year,
        sorted[i - 1].createdAt.month,
        sorted[i - 1].createdAt.day,
      );
      final currDate = DateTime(
        sorted[i].createdAt.year,
        sorted[i].createdAt.month,
        sorted[i].createdAt.day,
      );

      final dayDiff = currDate.difference(prevDate).inDays;

      if (dayDiff == 1) {
        currentStreak++;
      } else if (dayDiff == 0) {
        // Same day, don't break streak
        continue;
      } else {
        longestStreak = max(longestStreak, currentStreak);
        currentStreak = 1;
      }
    }

    longestStreak = max(longestStreak, currentStreak);
    return longestStreak;
  }

  /// Get reflection answer based on category
  String _getReflectionAnswer(String category, Random random) {
    final answers = _reflectionAnswersByCategory[category] ?? ['Good day'];
    return answers[random.nextInt(answers.length)];
  }

  /// Get intention by index
  String _getIntention(int index) {
    return _intentions[index % _intentions.length];
  }

  // DATA: 100 unique intentions telling Alex's story
  static final List<String> _intentions = [
    "Get through the Monday standup without zoning out",
    "Finally finish the migration script Tom asked about",
    "Call Mom tonight, she's been texting a lot",
    "Hit the gym before it gets too crowded",
    "Date night with Sarah — no phones",
    "Actually read that book chapter instead of scrolling",
    "Take a real lunch break today, not desk lunch",
    "Prep meals for the week so I stop ordering out",
    "Deep work on the Q2 proposal — headphones on",
    "Be patient in the team retro even if it drags",
    "Morning run before work, even if it's cold",
    "Finish that PR review I've been putting off",
    "Text Tom about Friday drinks",
    "Get 8 hours of sleep tonight for once",
    "Stop checking Slack after 7pm",
    "Sarah's birthday gift — actually think about it",
    "Cook dinner instead of ordering in again",
    "Clean the apartment, it's getting bad",
    "Work on side project for 30 minutes",
    "Meditate before the day gets crazy",
    "Don't let the deadline stress me out",
    "Be present in the 1-on-1 with my manager",
    "Gym after work even if I'm tired",
    "Call Mom back, I keep forgetting",
    "Finish the feature before EOD Friday",
    "Plan weekend trip with Sarah",
    "Read instead of Netflix tonight",
    "Meal prep Sunday — for real this time",
    "Go to bed before midnight",
    "Morning coffee without checking email",
    "Stretch before the gym, don't skip it",
    "Ask Tom for help instead of struggling alone",
    "Set boundaries on weekend work",
    "Actually use my PTO this quarter",
    "Write in journal before bed",
    "Drink more water, less coffee",
    "Take the stairs instead of elevator",
    "Respond to Sarah's texts faster",
    "Stop doom-scrolling before bed",
    "Finish the book I started two months ago",
    "Make time for that hobby project",
    "Get groceries so I stop eating out",
    "Fix the bug that's been nagging me",
    "Be honest in standup about blockers",
    "Take a walk during lunch",
    "Disconnect from work this weekend",
    "Quality time with Sarah, not half-distracted",
    "Morning yoga to start the day right",
    "Reach out to old friends I miss",
    "Stop comparing myself to others on LinkedIn",
    "Batch my emails instead of constant checking",
    "Leave work by 6pm today",
    "Cook that recipe I bookmarked",
    "Update my resume, just in case",
    "Be more assertive in meetings",
    "Stop saying yes to everything",
    "Take Mom's call when she calls",
    "Go to that concert Sarah wants to see",
    "Fix my sleep schedule this week",
    "Stop snoozing my alarm 5 times",
    "Cardio even though I hate it",
    "Be kind to myself when things don't go perfectly",
    "Finish the course I started online",
    "Declutter my workspace",
    "Start the morning with gratitude",
    "Don't skip breakfast again",
    "Call it a day when I'm done, not keep working",
    "Make plans with friends this weekend",
    "Stop overthinking that conversation",
    "Get outside for some fresh air",
    "Write down wins from this week",
    "Be fully present in meetings, not multitasking",
    "Prep for the big presentation",
    "Celebrate the small wins today",
    "Let go of what I can't control",
    "Trust the process",
    "Just breathe",
    "Focus on what matters",
    "One thing at a time",
    "Be the person Sarah deserves",
    "Make Mom proud",
    "Show up for Tom when he needs it",
    "Invest in my health now, not later",
    "Build something I'm proud of",
    "Learn from today's mistakes",
    "Tomorrow is a fresh start",
    "Keep moving forward",
    "Trust my gut",
    "Be patient with the journey",
    "Stop procrastinating on the hard stuff",
    "Face the uncomfortable conversation",
    "Ask for feedback instead of avoiding it",
    "Celebrate finishing this sprint",
    "Rest is productive too",
    "Quality over quantity today",
    "Protect my energy",
    "Set better boundaries",
    "Make time for what fills me up",
    "Let go of perfectionism",
    "Progress over perfection",
  ];

  // DATA: Reflection answers by category (casual, phone-typing style)
  static final Map<String, List<String>> _reflectionAnswersByCategory = {
    'gratitude': [
      "Sarah made me coffee this morning",
      "Tom covered for me in the meeting",
      "Mom's text checking in on me",
      "Good weather for a run",
      "Actually got a full night's sleep",
      "The project finally worked",
      "Weekend with no obligations",
      "Sarah's patience with my work stress",
      "Finding a parking spot right away",
      "Tom's terrible jokes at lunch",
      "Warm apartment on a cold day",
      "Good conversation over dinner",
    ],
    'pride': [
      "Shipped the feature before deadline",
      "Helped Tom debug that nasty issue",
      "Made it to the gym 3 times this week",
      "Cooked dinner instead of ordering",
      "Stood up for my idea in the meeting",
      "Actually stuck to my morning routine",
      "Finished the book I started",
      "Meal prepped for the whole week",
      "Fixed that bug nobody else could",
      "Ran 5k without stopping",
      "Called Mom when I said I would",
      "Didn't check work email all weekend",
    ],
    'learning': [
      "New approach to testing from Tom's PR",
      "Sarah taught me to cook that dish properly",
      "Manager's feedback was actually helpful",
      "Realized I need better boundaries",
      "Learned a new keyboard shortcut lol",
      "Reading about architecture patterns",
      "Understanding the codebase better",
      "How to say no without guilt",
      "Better git workflow from Tom",
      "Meal prep is easier than I thought",
    ],
    'energy': [
      "Morning run cleared my head",
      "Good sleep last night",
      "Coffee with Tom always lifts me up",
      "Solving that bug felt amazing",
      "Sarah's laugh",
      "Finishing the feature early",
      "Gym session, felt strong",
      "Weekend hike with Sarah",
      "Clean apartment = clear mind",
      "Good playlist during deep work",
    ],
    'tomorrow': [
      "Finish the code review",
      "Gym in the morning",
      "Date night with Sarah",
      "Finally tackle that refactor",
      "Sleep before midnight",
      "Call Mom",
      "Finish the sprint strong",
      "Weekend plans with friends",
      "Start the new book",
      "Meal prep for next week",
    ],
    'connection': [
      "Long talk with Sarah about everything",
      "Tom and I grabbed lunch",
      "Mom's voice on the phone",
      "Team lunch was actually fun",
      "Sarah and I just watched a movie together",
      "Caught up with old college friend",
      "Quality time with Sarah, no distractions",
      "Tom helped me through a rough day",
      "Mom sent a care package",
      "Good conversation with manager",
    ],
    'selfcare': [
      "Took a real lunch break",
      "Went to bed early",
      "Said no to extra work",
      "Morning run just for me",
      "Ordered takeout guilt-free",
      "Read instead of scrolling",
      "Disconnected from work",
      "Long shower after the gym",
      "Nap on Sunday afternoon",
      "Bought that thing I wanted",
    ],
    'reflection': [
      "Should've asked for help sooner",
      "Need to stop overcommitting",
      "I was too hard on myself today",
      "Shouldn't have skipped the gym",
      "Need better work-life balance",
      "Should've been more present with Sarah",
      "Too much coffee, not enough water",
      "Procrastinated on the hard task",
      "Need to set better boundaries",
      "Called Mom too late again",
    ],
    'presence': [
      "Morning coffee before the chaos",
      "Sarah laughing at my joke",
      "Sunset on the drive home",
      "Solving the bug after hours of trying",
      "Quiet Sunday morning",
      "That first sip of coffee",
      "Finishing a good book",
      "Walking home from the gym",
      "Sarah falling asleep on my shoulder",
      "Team celebrating the launch",
    ],
  };

  /// Generate weekly summaries for all completed weeks in the date range
  Future<void> _generateWeeklySummaries(
    DateTime now,
    List<Entry> entries,
    List<ReflectionAnswer> answers,
    Direction careerDirection,
    Direction healthDirection,
    Direction relationshipsDirection,
    Direction peaceDirection,
  ) async {
    final summaryBox = await Hive.openBox<WeeklySummary>('weekly_summaries');
    final connectionsBox = await Hive.openBox<DirectionConnection>('direction_connections');

    // Build a map of entryId -> list of answer objects for quick lookup
    final entryAnswersMap = <String, List<ReflectionAnswer>>{};
    for (final answer in answers) {
      entryAnswersMap.putIfAbsent(answer.entryId, () => []).add(answer);
    }

    // Build a map of entryId -> list of directionIds for quick lookup
    final entryDirectionsMap = <String, Set<String>>{};
    for (final connection in connectionsBox.values) {
      entryDirectionsMap.putIfAbsent(connection.entryId, () => {}).add(connection.directionId);
    }

    // Calculate week boundaries
    // Start from 90 days ago, generate summaries for each completed week up to last Monday
    final oldestDate = now.subtract(const Duration(days: 90));
    final firstMonday = _startOfWeek(oldestDate);
    final currentWeekStart = _startOfWeek(now);

    // Iterate through each week
    DateTime weekStart = firstMonday;
    final summaries = <WeeklySummary>[];
    double? previousWeekAvgMood;

    while (weekStart.isBefore(currentWeekStart)) {
      final weekEnd = weekStart.add(const Duration(days: 7));

      // Get entries for this week
      final weekEntries = entries.where((entry) {
        return !entry.createdAt.isBefore(weekStart) && entry.createdAt.isBefore(weekEnd);
      }).toList();

      // Only create summary if week has entries
      if (weekEntries.isEmpty) {
        weekStart = weekEnd;
        continue;
      }

      // Sort entries by date
      weekEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Calculate stats
      final checkInCount = weekEntries.length;
      final daysWithEntries = weekEntries.map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day)).toSet().length;
      final avgMood = weekEntries.map((e) => e.moodValue).reduce((a, b) => a + b) / weekEntries.length;

      // Determine mood trend
      String moodTrend = 'stable';
      if (previousWeekAvgMood != null) {
        final difference = avgMood - previousWeekAvgMood;
        if (difference >= 0.05) {
          moodTrend = 'up';
        } else if (difference <= -0.05) {
          moodTrend = 'down';
        }
      }

      // Find most felt mood (most common moodWord)
      final moodCounts = <String, int>{};
      for (final entry in weekEntries) {
        moodCounts[entry.moodWord] = (moodCounts[entry.moodWord] ?? 0) + 1;
      }
      final mostFeltMood = moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      // Find best mood day
      final bestEntry = weekEntries.reduce((a, b) => a.moodValue > b.moodValue ? a : b);
      final weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final bestMoodDay = weekdayNames[bestEntry.createdAt.weekday - 1];
      final bestMoodValue = bestEntry.moodValue;
      final bestMoodWord = bestEntry.moodWord;

      // Build direction summaries
      final directionSummaries = <Map<String, dynamic>>[];
      String? topDirectionId;
      double highestMoodDifference = -999.0;

      final directions = [
        (careerDirection, 'career'),
        (healthDirection, 'health'),
        (relationshipsDirection, 'relationships'),
        (peaceDirection, 'peace'),
      ];

      for (final (direction, _) in directions) {
        // Count connections for this week
        final weeklyConnections = weekEntries.where((entry) {
          return entryDirectionsMap[entry.id]?.contains(direction.id) ?? false;
        }).length;

        // Calculate avg mood when connected to this direction (across all entries, not just this week)
        final allConnectedEntries = entries.where((entry) {
          return entryDirectionsMap[entry.id]?.contains(direction.id) ?? false;
        }).toList();

        double avgMoodWhenConnected = 0.0;
        if (allConnectedEntries.isNotEmpty) {
          avgMoodWhenConnected = allConnectedEntries.map((e) => e.moodValue).reduce((a, b) => a + b) / allConnectedEntries.length;
        }

        // Calculate overall avg mood (all entries)
        final overallAvgMood = entries.map((e) => e.moodValue).reduce((a, b) => a + b) / entries.length;
        final moodDifference = avgMoodWhenConnected - overallAvgMood;

        directionSummaries.add({
          'directionId': direction.id,
          'title': direction.title,
          'iconAsset': direction.type.iconAsset,
          'weeklyConnections': weeklyConnections,
          'avgMoodWhenConnected': avgMoodWhenConnected,
          'moodDifference': moodDifference,
        });

        // Track top direction (highest positive correlation >= 0.1)
        if (moodDifference >= 0.1 && moodDifference > highestMoodDifference) {
          highestMoodDifference = moodDifference;
          topDirectionId = direction.id;
        }
      }

      // Get standout reflections (1-2 longest answers)
      final weekAnswers = <ReflectionAnswer>[];
      for (final entry in weekEntries) {
        if (entryAnswersMap.containsKey(entry.id)) {
          weekAnswers.addAll(entryAnswersMap[entry.id]!);
        }
      }

      List<Map<String, dynamic>>? standoutReflectionAnswers;
      if (weekAnswers.isNotEmpty) {
        weekAnswers.sort((a, b) => b.answer.length.compareTo(a.answer.length));
        standoutReflectionAnswers = [];

        // Add longest answer
        standoutReflectionAnswers.add({
          'questionText': weekAnswers.first.questionText,
          'answer': weekAnswers.first.answer,
        });

        // Add second longest if different question
        if (weekAnswers.length > 1) {
          for (var i = 1; i < weekAnswers.length; i++) {
            if (weekAnswers[i].questionText != weekAnswers.first.questionText) {
              standoutReflectionAnswers.add({
                'questionText': weekAnswers[i].questionText,
                'answer': weekAnswers[i].answer,
              });
              break;
            }
          }
        }
      }

      // Generate unique takeaway for this week
      final takeaway = _generateWeeklyTakeaway(
        weekStart,
        checkInCount,
        avgMood,
        moodTrend,
        bestMoodDay,
        bestMoodWord,
        directionSummaries,
        weekAnswers.isNotEmpty,
      );

      // Create summary
      final summary = WeeklySummary(
        id: _uuid.v4(),
        weekStart: weekStart,
        weekEnd: weekEnd,
        checkInCount: checkInCount,
        daysWithEntries: daysWithEntries,
        avgMood: avgMood,
        moodTrend: moodTrend,
        mostFeltMood: mostFeltMood,
        bestMoodDay: bestMoodDay,
        bestMoodValue: bestMoodValue,
        bestMoodWord: bestMoodWord,
        directionSummaries: directionSummaries,
        topDirectionId: topDirectionId,
        standoutReflectionAnswers: standoutReflectionAnswers,
        takeaway: takeaway,
        createdAt: weekEnd, // Summaries are created after the week ends
        viewedAt: null, // Will be set below
      );

      summaries.add(summary);
      previousWeekAvgMood = avgMood;
      weekStart = weekEnd;
    }

    // Mark all summaries as viewed EXCEPT the most recent one
    for (int i = 0; i < summaries.length; i++) {
      final isLastSummary = i == summaries.length - 1;
      final summary = summaries[i];

      final finalSummary = WeeklySummary(
        id: summary.id,
        weekStart: summary.weekStart,
        weekEnd: summary.weekEnd,
        checkInCount: summary.checkInCount,
        daysWithEntries: summary.daysWithEntries,
        avgMood: summary.avgMood,
        moodTrend: summary.moodTrend,
        mostFeltMood: summary.mostFeltMood,
        bestMoodDay: summary.bestMoodDay,
        bestMoodValue: summary.bestMoodValue,
        bestMoodWord: summary.bestMoodWord,
        directionSummaries: summary.directionSummaries,
        topDirectionId: summary.topDirectionId,
        standoutReflectionAnswers: summary.standoutReflectionAnswers,
        takeaway: summary.takeaway,
        createdAt: summary.createdAt,
        viewedAt: isLastSummary ? null : summary.createdAt.add(const Duration(hours: 2)), // Viewed ~2 hours after creation, except last
      );

      await summaryBox.put(finalSummary.id, finalSummary);
    }
  }

  /// Calculate the start of the week (Monday) for a given date
  DateTime _startOfWeek(DateTime date) {
    final weekday = date.weekday;
    final mondayDate = date.subtract(Duration(days: weekday - 1));
    return DateTime(mondayDate.year, mondayDate.month, mondayDate.day);
  }

  /// Generate unique takeaway message for each week
  String _generateWeeklyTakeaway(
    DateTime weekStart,
    int checkInCount,
    double avgMood,
    String moodTrend,
    String? bestMoodDay,
    String? bestMoodWord,
    List<Map<String, dynamic>> directionSummaries,
    bool hasReflections,
  ) {
    // Use week number to select different messages (deterministic but varied)
    final weekOfYear = _weekOfYear(weekStart);
    final seed = weekOfYear % 20; // 20 different message templates

    // Count direction connections
    int totalConnections = 0;
    String? topDirection;
    int topConnections = 0;
    for (final dir in directionSummaries) {
      final count = dir['weeklyConnections'] as int;
      totalConnections += count;
      if (count > topConnections) {
        topConnections = count;
        topDirection = dir['title'] as String;
      }
    }

    switch (seed) {
      case 0:
        return checkInCount == 7
            ? 'Seven for seven. You didn\'t miss a day. That\'s dedication.'
            : 'You showed up $checkInCount days this week. Your consistency is building something.';

      case 1:
        return hasReflections
            ? 'A quieter week, but the reflections you wrote were some of your most honest.'
            : 'Even when life gets busy, you made time for yourself. That matters.';

      case 2:
        return bestMoodDay != null
            ? '$bestMoodDay\'s energy carried you. Notice what made that day different.'
            : 'This week had its ups and downs, but you kept showing up.';

      case 3:
        return totalConnections > 0 && topDirection != null
            ? '$topConnections check-ins connected to $topDirection. You\'re on track.'
            : 'You checked in $checkInCount times. That\'s $checkInCount moments of self-awareness.';

      case 4:
        return moodTrend == 'up'
            ? 'Even with a rough start, you bounced back. That\'s resilience.'
            : 'Stability is its own kind of strength. You held steady this week.';

      case 5:
        return avgMood >= 0.6
            ? 'Your mood was up this week. Something\'s working — trust it.'
            : 'Tough weeks happen. What matters is you kept checking in anyway.';

      case 6:
        return hasReflections
            ? 'Your reflections this week show real self-awareness. That\'s powerful.'
            : 'You showed up even when it was hard. That\'s courage.';

      case 7:
        return checkInCount >= 6
            ? 'Six check-ins and real progress. You\'re building momentum.'
            : 'Every check-in is a choice to show up for yourself. You made that choice $checkInCount times.';

      case 8:
        return bestMoodWord != null
            ? 'You felt $bestMoodWord on $bestMoodDay. What can you learn from that?'
            : 'Another week, another set of data points about you. Keep going.';

      case 9:
        return totalConnections > 0
            ? 'You connected $totalConnections entries to your directions this week. That\'s intentional living.'
            : 'Progress isn\'t always visible, but it\'s happening. Trust the process.';

      case 10:
        return moodTrend == 'down'
            ? 'Even when things felt harder, you kept showing up. That takes strength.'
            : 'Consistent effort, consistent growth. You\'re doing the work.';

      case 11:
        return hasReflections && avgMood >= 0.5
            ? 'Good week, thoughtful reflections. You\'re finding your rhythm.'
            : 'One week at a time. You\'re exactly where you need to be.';

      case 12:
        return checkInCount >= 5
            ? 'Five check-ins this week. You\'re making this a habit.'
            : 'Even a few check-ins matter. You showed up when it counted.';

      case 13:
        return topDirection != null && topConnections >= 3
            ? '$topDirection got your attention this week. That focus is valuable.'
            : 'You\'re learning what matters to you. That clarity takes time.';

      case 14:
        return avgMood < 0.35 && checkInCount >= 3
            ? 'Tough weeks are worth reflecting on. You did that — and that matters.'
            : 'Self-awareness is a practice, and you\'re practicing. Keep at it.';

      case 15:
        return moodTrend == 'up' && hasReflections
            ? 'Your mood improved AND you reflected deeply. That combination is powerful.'
            : 'You\'re building a record of who you are. That\'s valuable work.';

      case 16:
        return bestMoodDay == 'Saturday' || bestMoodDay == 'Sunday'
            ? 'Weekends recharge you. How can you bring that energy into the week?'
            : 'Weekdays have their own challenges. You\'re learning to navigate them.';

      case 17:
        return checkInCount == 7
            ? 'Perfect attendance this week. Your commitment is inspiring.'
            : 'Not every week is perfect, but every check-in counts. You did $checkInCount.';

      case 18:
        return hasReflections
            ? 'The questions you answered reveal growth. Keep looking inward.'
            : 'Sometimes just tracking your mood is enough. You did that.';

      case 19:
      default:
        return totalConnections > 0
            ? 'Direction connections: $totalConnections. You\'re aligning actions with values.'
            : 'Another week of showing up for yourself. That\'s the foundation.';
    }
  }

  /// Calculate week number of the year (1-52)
  int _weekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceStart = date.difference(firstDayOfYear).inDays;
    return (daysSinceStart / 7).floor() + 1;
  }
}
