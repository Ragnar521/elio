import 'dart:math';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/direction.dart';
import '../models/direction_connection.dart';
import '../models/entry.dart';
import '../models/reflection_answer.dart';
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
}
