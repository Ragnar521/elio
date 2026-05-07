import 'dart:math';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/direction.dart';
import '../models/direction_check_in.dart';
import '../models/direction_connection.dart';
import '../models/entry.dart';
import '../models/reflection_answer.dart';
import '../models/weekly_summary.dart';
import 'reflection_service.dart';

/// Service for loading demo data into Elio
///
/// Creates ~90 days of realistic check-in data for "Maya" persona:
/// - Freelance designer balancing creative work, health, and relationships
/// - References Luca (partner), Nadia (best friend), Dad
/// - Day-of-week mood patterns (low Mon/Tue admin days, high Wed/Sat creative days)
/// - 5 active directions with uneven connection distribution
/// - ~70-80% of entries include reflections across all 9 categories
/// - Direction check-ins with steps, blockers, and support notes
class SampleDataService {
  SampleDataService._();
  static final SampleDataService instance = SampleDataService._();

  static const _uuid = Uuid();

  Future<void> loadDemoData() async {
    final entriesBox = await Hive.openBox<Entry>('entries');
    final answersBox = await Hive.openBox<ReflectionAnswer>(
      'reflectionAnswers',
    );
    final directionsBox = await Hive.openBox<Direction>('directions');
    final connectionsBox = await Hive.openBox<DirectionConnection>(
      'direction_connections',
    );
    final directionCheckInsBox = await Hive.openBox<DirectionCheckIn>(
      'direction_check_ins',
    );
    final settingsBox = await Hive.openBox('settings');

    final summaryBox = await Hive.openBox<WeeklySummary>('weekly_summaries');

    await entriesBox.clear();
    await answersBox.clear();
    await directionsBox.clear();
    await connectionsBox.clear();
    await directionCheckInsBox.clear();
    await summaryBox.clear();

    await settingsBox.put('user_name', 'Maya');
    await settingsBox.put('onboarding_completed', true);
    await settingsBox.put('reflection_enabled', true);

    final now = DateTime.now();
    final directionsCreatedAt = now.subtract(const Duration(days: 88));

    final creativityDirection = Direction(
      id: _uuid.v4(),
      title: 'Make Beautiful Things',
      type: DirectionType.creativity,
      reflectionEnabled: true,
      createdAt: directionsCreatedAt,
    );

    final healthDirection = Direction(
      id: _uuid.v4(),
      title: 'Move & Rest',
      type: DirectionType.health,
      reflectionEnabled: true,
      createdAt: directionsCreatedAt,
    );

    final relationshipsDirection = Direction(
      id: _uuid.v4(),
      title: 'People Who Matter',
      type: DirectionType.relationships,
      reflectionEnabled: false,
      createdAt: directionsCreatedAt,
    );

    final growthDirection = Direction(
      id: _uuid.v4(),
      title: 'Learn to Code',
      type: DirectionType.growth,
      reflectionEnabled: true,
      createdAt: directionsCreatedAt.add(const Duration(days: 12)),
    );

    final peaceDirection = Direction(
      id: _uuid.v4(),
      title: 'Quiet Mind',
      type: DirectionType.peace,
      reflectionEnabled: true,
      createdAt: directionsCreatedAt.add(const Duration(days: 5)),
    );

    await directionsBox.put(creativityDirection.id, creativityDirection);
    await directionsBox.put(healthDirection.id, healthDirection);
    await directionsBox.put(
      relationshipsDirection.id,
      relationshipsDirection,
    );
    await directionsBox.put(growthDirection.id, growthDirection);
    await directionsBox.put(peaceDirection.id, peaceDirection);

    final allQuestions = ReflectionService.instance.getAllQuestions();

    final entries = _generateEntries(now, allQuestions);

    final answersData = _generateReflectionAnswers(entries, allQuestions);
    for (final answer in answersData) {
      await answersBox.put(answer.id, answer);
    }

    // Link answer IDs back to entries
    final answerIdsByEntry = <String, List<String>>{};
    for (final answer in answersData) {
      answerIdsByEntry.putIfAbsent(answer.entryId, () => []).add(answer.id);
    }

    for (final entry in entries) {
      final answerIds = answerIdsByEntry[entry.id];
      final linked = Entry(
        id: entry.id,
        moodValue: entry.moodValue,
        moodWord: entry.moodWord,
        intention: entry.intention,
        createdAt: entry.createdAt,
        reflectionAnswerIds: answerIds,
      );
      await entriesBox.put(linked.id, linked);
    }

    final connections = _generateDirectionConnections(
      entries,
      creativityDirection.id,
      healthDirection.id,
      relationshipsDirection.id,
      growthDirection.id,
      peaceDirection.id,
    );
    for (final connection in connections) {
      await connectionsBox.put(connection.id, connection);
    }

    final checkIns = _generateDirectionCheckIns(
      entries,
      connections,
      creativityDirection.id,
      healthDirection.id,
      relationshipsDirection.id,
      growthDirection.id,
      peaceDirection.id,
    );
    for (final checkIn in checkIns) {
      await directionCheckInsBox.put(checkIn.id, checkIn);
    }

    final longestStreak = _calculateLongestStreak(entries);
    await settingsBox.put('longest_streak', longestStreak);

    await _generateWeeklySummaries(
      now,
      entries,
      answersData,
      creativityDirection,
      healthDirection,
      relationshipsDirection,
      growthDirection,
      peaceDirection,
    );
  }

  List<Entry> _generateEntries(
    DateTime now,
    List<dynamic> questions,
  ) {
    final entries = <Entry>[];
    final random = Random(77);

    final gapDays = <int>{};
    while (gapDays.length < 14) {
      gapDays.add(random.nextInt(90));
    }

    final doubleEntryDays = <int>{};
    while (doubleEntryDays.length < 8) {
      final day = random.nextInt(90);
      if (!gapDays.contains(day)) {
        doubleEntryDays.add(day);
      }
    }

    for (int daysAgo = 90; daysAgo >= 1; daysAgo--) {
      if (gapDays.contains(daysAgo)) continue;

      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: daysAgo));
      final weekday = date.weekday;

      if (doubleEntryDays.contains(daysAgo)) {
        entries.add(
          _createEntry(date, weekday, random, daysAgo, isMorning: true),
        );
        entries.add(
          _createEntry(date, weekday, random, daysAgo, isMorning: false),
        );
      } else {
        entries.add(_createEntry(date, weekday, random, daysAgo));
      }
    }

    return entries;
  }

  Entry _createEntry(
    DateTime date,
    int weekday,
    Random random,
    int daysAgo, {
    bool? isMorning,
  }) {
    final DateTime createdAt;
    if (isMorning != null) {
      if (isMorning) {
        createdAt = DateTime(
          date.year,
          date.month,
          date.day,
          6 + random.nextInt(3),
          random.nextInt(60),
        );
      } else {
        createdAt = DateTime(
          date.year,
          date.month,
          date.day,
          20 + random.nextInt(2),
          random.nextInt(60),
        );
      }
    } else {
      final hour = 7 + random.nextInt(14);
      createdAt = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        random.nextInt(60),
      );
    }

    final baseImprovement = daysAgo <= 25 ? 0.06 : 0.0;
    double baseMood;

    switch (weekday) {
      case 1: // Monday — admin, invoices, emails
        baseMood = 0.28 + random.nextDouble() * 0.15;
        break;
      case 2: // Tuesday — slow creative start
        baseMood = 0.35 + random.nextDouble() * 0.15;
        break;
      case 3: // Wednesday — deep design work
        baseMood = 0.55 + random.nextDouble() * 0.20;
        break;
      case 4: // Thursday — client calls, mixed
        baseMood = 0.40 + random.nextDouble() * 0.18;
        break;
      case 5: // Friday — wrapping up, lighter
        baseMood = 0.50 + random.nextDouble() * 0.18;
        break;
      case 6: // Saturday — personal projects, social
        baseMood = 0.62 + random.nextDouble() * 0.20;
        break;
      case 7: // Sunday — rest, prep anxiety
        baseMood = 0.48 + random.nextDouble() * 0.20;
        break;
      default:
        baseMood = 0.50;
    }

    final moodValue =
        (baseMood + baseImprovement + (random.nextDouble() * 0.08 - 0.04))
            .clamp(0.0, 1.0);
    final moodWord = _getMoodWord(moodValue);

    final intention = _getIntention(random.nextInt(_intentions.length));

    return Entry(
      id: _uuid.v4(),
      moodValue: moodValue,
      moodWord: moodWord,
      intention: intention,
      createdAt: createdAt,
      reflectionAnswerIds: null,
    );
  }

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

  List<ReflectionAnswer> _generateReflectionAnswers(
    List<Entry> entries,
    List<dynamic> questions,
  ) {
    final answers = <ReflectionAnswer>[];
    final random = Random(78);

    for (final entry in entries) {
      if (random.nextDouble() > 0.75) continue;

      final numAnswers = random.nextDouble() < 0.65
          ? 1
          : (random.nextDouble() < 0.75 ? 2 : 3);

      for (int i = 0; i < numAnswers; i++) {
        final question = questions[random.nextInt(questions.length)];
        final questionId = question.id as String;
        final questionText = question.text as String;
        final category = question.category as String;

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
      }
    }

    return answers;
  }

  List<DirectionConnection> _generateDirectionConnections(
    List<Entry> entries,
    String creativityId,
    String healthId,
    String relationshipsId,
    String growthId,
    String peaceId,
  ) {
    final connections = <DirectionConnection>[];
    final random = Random(79);

    for (final entry in entries) {
      // Creativity: 50% — Maya's main thing
      if (random.nextDouble() < 0.50) {
        connections.add(
          DirectionConnection(
            id: _uuid.v4(),
            directionId: creativityId,
            entryId: entry.id,
            createdAt: entry.createdAt,
          ),
        );
      }

      // Health: 30% — yoga, running, sleep
      if (random.nextDouble() < 0.30) {
        connections.add(
          DirectionConnection(
            id: _uuid.v4(),
            directionId: healthId,
            entryId: entry.id,
            createdAt: entry.createdAt,
          ),
        );
      }

      // Relationships: 22% — Luca, Nadia, Dad
      if (random.nextDouble() < 0.22) {
        connections.add(
          DirectionConnection(
            id: _uuid.v4(),
            directionId: relationshipsId,
            entryId: entry.id,
            createdAt: entry.createdAt,
          ),
        );
      }

      // Growth: 18% — coding side project
      if (random.nextDouble() < 0.18) {
        connections.add(
          DirectionConnection(
            id: _uuid.v4(),
            directionId: growthId,
            entryId: entry.id,
            createdAt: entry.createdAt,
          ),
        );
      }

      // Peace: 15% — meditation, walks, stillness
      if (random.nextDouble() < 0.15) {
        connections.add(
          DirectionConnection(
            id: _uuid.v4(),
            directionId: peaceId,
            entryId: entry.id,
            createdAt: entry.createdAt,
          ),
        );
      }
    }

    return connections;
  }

  List<DirectionCheckIn> _generateDirectionCheckIns(
    List<Entry> entries,
    List<DirectionConnection> connections,
    String creativityId,
    String healthId,
    String relationshipsId,
    String growthId,
    String peaceId,
  ) {
    final checkIns = <DirectionCheckIn>[];
    final random = Random(80);

    final connectionsByEntry = <String, List<DirectionConnection>>{};
    for (final conn in connections) {
      connectionsByEntry.putIfAbsent(conn.entryId, () => []).add(conn);
    }

    for (final entry in entries) {
      final entryConnections = connectionsByEntry[entry.id];
      if (entryConnections == null) continue;

      for (final conn in entryConnections) {
        // ~40% of connections have a step/blocker/support
        if (random.nextDouble() > 0.40) continue;

        String? stepText;
        String? blockerText;
        String? supportText;

        if (conn.directionId == creativityId) {
          if (random.nextBool()) {
            stepText = _creativitySteps[
                random.nextInt(_creativitySteps.length)];
          }
          if (random.nextDouble() < 0.3) {
            blockerText = _creativityBlockers[
                random.nextInt(_creativityBlockers.length)];
          }
          if (random.nextDouble() < 0.25) {
            supportText = _creativitySupport[
                random.nextInt(_creativitySupport.length)];
          }
        } else if (conn.directionId == healthId) {
          if (random.nextBool()) {
            stepText =
                _healthSteps[random.nextInt(_healthSteps.length)];
          }
          if (random.nextDouble() < 0.3) {
            blockerText =
                _healthBlockers[random.nextInt(_healthBlockers.length)];
          }
        } else if (conn.directionId == growthId) {
          if (random.nextBool()) {
            stepText =
                _growthSteps[random.nextInt(_growthSteps.length)];
          }
          if (random.nextDouble() < 0.35) {
            blockerText =
                _growthBlockers[random.nextInt(_growthBlockers.length)];
          }
        } else if (conn.directionId == peaceId) {
          if (random.nextBool()) {
            stepText =
                _peaceSteps[random.nextInt(_peaceSteps.length)];
          }
        }

        if (stepText != null || blockerText != null || supportText != null) {
          checkIns.add(
            DirectionCheckIn(
              id: _uuid.v4(),
              directionId: conn.directionId,
              entryId: entry.id,
              stepText: stepText,
              blockerText: blockerText,
              supportText: supportText,
              createdAt: entry.createdAt,
            ),
          );
        }
      }
    }

    return checkIns;
  }

  int _calculateLongestStreak(List<Entry> entries) {
    if (entries.isEmpty) return 0;

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
        continue;
      } else {
        longestStreak = max(longestStreak, currentStreak);
        currentStreak = 1;
      }
    }

    longestStreak = max(longestStreak, currentStreak);
    return longestStreak;
  }

  String _getReflectionAnswer(String category, Random random) {
    final answers = _reflectionAnswersByCategory[category] ?? ['Good day'];
    return answers[random.nextInt(answers.length)];
  }

  String _getIntention(int index) {
    return _intentions[index % _intentions.length];
  }

  // --- Direction check-in content ---

  static const _creativitySteps = [
    'Finished the landing page hero section',
    'Sketched three logo concepts for the cafe client',
    'Picked a color palette for the rebrand',
    'Prototyped the onboarding flow in Figma',
    'Drew for 20 minutes, no client work, just for me',
    'Wrote the copy for the portfolio update',
    'Played with new brush textures in Procreate',
    'Recorded a timelapse of the illustration process',
    'Sent the first draft to the client',
    'Reorganized my design file library',
  ];

  static const _creativityBlockers = [
    'Client keeps changing direction, hard to commit',
    'Perfectionism — spent an hour on one icon',
    'Creative block, nothing felt right today',
    'Too many admin tasks ate into studio time',
    'Comparison spiral after scrolling Dribbble',
  ];

  static const _creativitySupport = [
    'Step away from the screen for a walk',
    'Look at old sketchbooks for inspiration',
    'Ask Nadia for honest feedback',
    'Set a timer and just start, even if it\'s bad',
    'Remember why I went freelance in the first place',
  ];

  static const _healthSteps = [
    'Morning yoga, 25 minutes',
    'Ran 3k along the river',
    'Cooked a proper meal instead of snacking',
    'Slept 8 hours for the first time in a week',
    'Drank water all day, no afternoon coffee',
    'Stretched between client calls',
    'Walked to the co-working space instead of biking',
    'Made a smoothie with actual vegetables',
    'Went to bed before midnight',
    'Did a full body stretch before sleep',
  ];

  static const _healthBlockers = [
    'Deadline crunch, skipped the run',
    'Slept terribly, couldn\'t focus all day',
    'Ate junk because I forgot to shop',
    'Back pain from hunching over the tablet',
    'Too tired after the client marathon',
  ];

  static const _growthSteps = [
    'Finished the JavaScript arrays chapter',
    'Built a tiny calculator app in Flutter',
    'Watched a 30-min tutorial on state management',
    'Wrote my first API call — it worked!',
    'Refactored the to-do app with cleaner code',
    'Read about design patterns for beginners',
    'Asked in the Discord for help with a bug',
    'Pushed code to GitHub for the first time',
    'Styled a page with CSS Grid on my own',
    'Completed 3 coding challenges on Exercism',
  ];

  static const _growthBlockers = [
    'Got stuck on a bug for 2 hours, gave up',
    'Felt stupid not understanding async/await',
    'Too tired after design work to switch to code',
    'The tutorial assumed I knew things I don\'t',
    'Imposter syndrome hit hard today',
  ];

  static const _peaceSteps = [
    '10 minutes of meditation in the morning',
    'Sat in the park with no phone for 20 minutes',
    'Journaled before bed instead of scrolling',
    'Said no to a project that didn\'t feel right',
    'Took a bath and read a novel',
    'Morning coffee on the balcony, no notifications',
    'Breathwork during the afternoon slump',
    'Left the phone in another room for an hour',
  ];

  // --- 100 intentions for Maya's story ---

  static final List<String> _intentions = [
    "Finish the cafe logo concepts before lunch",
    "Yoga before I open the laptop",
    "Call Dad tonight, it's been too long",
    "Deep work on the rebrand — no Slack until noon",
    "Cook with Luca instead of ordering in",
    "Draw something that isn't for a client",
    "Take a real break between projects",
    "Send the invoice I've been avoiding",
    "Run along the river, clear my head",
    "No screens after 9pm tonight",
    "Portfolio update — pick the best 5 pieces",
    "Text Nadia back, she's been waiting",
    "Meditate before the client call",
    "Try that new pasta recipe Luca found",
    "Sketch freely for 30 minutes, no pressure",
    "Set boundaries on weekend work requests",
    "Morning pages before anything else",
    "Clean the studio, it's a mess",
    "Read the design book I bought months ago",
    "Be honest with the client about the timeline",
    "Stretch every hour, my back is killing me",
    "Batch all the emails into one session",
    "Luca's parents are visiting — be present",
    "Start the coding tutorial I keep postponing",
    "Go to the farmers market, buy real food",
    "Say no to at least one thing today",
    "Explore that new illustration style",
    "Actually use the standing desk",
    "Plan the weekend trip with Nadia",
    "Stop comparing my work to strangers online",
    "Write down 3 things I'm grateful for",
    "Ship the first draft, it doesn't have to be perfect",
    "Walk to the cafe and work from there",
    "Do the hard design task first, not last",
    "Respond to Dad's voicemail",
    "Prep meals so I stop eating at my desk",
    "30 minutes of coding practice after dinner",
    "Put the phone in another room while designing",
    "Date night with Luca — his pick this time",
    "Wake up without an alarm, just this once",
    "Finish one thing fully instead of starting three",
    "Go to that exhibition Nadia mentioned",
    "Drink more water, less coffee today",
    "Trust the creative process, stop forcing it",
    "Take the afternoon off, I've earned it",
    "Journal about what's been bugging me",
    "Reorganize my Figma files, they're chaos",
    "Help Luca with his presentation",
    "Try a new running route",
    "Revisit that rejected logo — it might be good",
    "Morning sunlight before screen light",
    "Be kinder to myself about the slow days",
    "Ask for feedback on the branding project",
    "Learn one new CSS trick today",
    "Unsubscribe from newsletters I never read",
    "Quality time with Luca, no half-attention",
    "Make the boring admin stuff less painful",
    "Take photos on the walk, see things differently",
    "Don't check analytics obsessively",
    "Buy flowers for the studio, small joy",
    "Breathe before reacting to the client feedback",
    "Celebrate finishing this sprint properly",
    "Rest without guilt",
    "Focus on one direction, not all five",
    "Do something creative that scares me a little",
    "End the day by writing down what went well",
    "Be patient with the coding learning curve",
    "Protect the morning hours for deep work",
    "Tell Luca what I actually need this week",
    "Go outside at least once before dark",
    "Stop saying yes reflexively",
    "One small step on the portfolio site",
    "Let the messy first draft exist",
    "Sit with discomfort instead of distracting",
    "Make space between tasks, not just tasks",
    "Call Nadia, not just text",
    "Sleep is more important than finishing this",
    "Find the fun in the mundane client work",
    "Practice the presentation out loud",
    "Less perfection, more presence",
    "Move my body even if just a walk",
    "Listen to music while working, not podcasts",
    "Write the proposal I've been drafting in my head",
    "Take the scenic route today",
    "Let go of the project that isn't working",
    "Be proud of what I shipped this week",
    "Floss. Seriously, just floss.",
    "Luca needs space today — give it freely",
    "Spend 15 minutes on something just for fun",
    "Review my finances, stop avoiding it",
    "Accept the revision feedback gracefully",
    "Show up for the co-working session",
    "Paint something small on real paper",
    "Eat lunch away from the desk",
    "Ask Dad about his garden, he loves that",
    "One inbox-zero day, let's try",
    "Acknowledge what I feel before rushing past it",
    "Progress, not perfection",
    "Just start",
  ];

  static final Map<String, List<String>> _reflectionAnswersByCategory = {
    'gratitude': [
      "Luca made dinner while I was on a deadline",
      "Nadia sent me a voice note that made me laugh",
      "The morning light in the studio was perfect",
      "Dad left a sweet voicemail",
      "A client said my work made them tear up",
      "Hot coffee on a cold morning, nothing else needed",
      "Found an old sketchbook — loved seeing the progress",
      "Luca didn't ask about work, just asked how I was",
      "The farmer's market had those figs I love",
      "Nadia drove an hour to have lunch with me",
      "A stranger complimented my shoes, silly but nice",
      "Rain on the window while I was sketching",
    ],
    'pride': [
      "Shipped the brand identity ahead of schedule",
      "Ran 5k without walking once",
      "Said no to a project that would've burned me out",
      "The client picked my favorite concept",
      "Built a working button in Flutter, felt like magic",
      "Cooked a three-course dinner from scratch",
      "Stood my ground on a design decision and was right",
      "Got up early and meditated before the chaos",
      "Finished all five invoices in one sitting",
      "Wrote real code that actually did something",
      "Went a whole week without doom-scrolling",
      "Had a hard conversation with Luca and it went well",
    ],
    'learning': [
      "Figured out flexbox by building a real layout",
      "Luca showed me how to sharpen kitchen knives",
      "Client feedback taught me to present options differently",
      "Learned that my best ideas come after walks",
      "A YouTube video finally made async/await click",
      "Realized I design better with constraints",
      "Read about color theory I'd been ignoring",
      "Nadia's advice: stop editing while creating",
      "Discovered I work best in 90-minute blocks",
      "Learned to ask for help before I'm stuck",
    ],
    'energy': [
      "Morning yoga and the whole day felt smoother",
      "Deep focus session — 3 hours felt like 30 minutes",
      "Cooking with Luca, music on, no rush",
      "Running in the rain, weirdly energizing",
      "The design clicked and everything flowed",
      "Dancing in the kitchen while waiting for pasta",
      "Long call with Nadia, laughed until my stomach hurt",
      "Finishing a big project, the relief",
      "Saturday morning with nowhere to be",
      "Fresh notebook, fresh pen, ready to go",
    ],
    'tomorrow': [
      "Ship the landing page to the client",
      "Morning run before anything else",
      "Date night with Luca, no phones",
      "Start the new illustration series",
      "Bed before midnight, no excuses",
      "Call Dad during lunch break",
      "Tackle the hardest design task first",
      "Co-working session with Nadia",
      "Finish the coding chapter",
      "Prep food for the busy week ahead",
    ],
    'connection': [
      "Long walk with Luca, talked about everything",
      "Nadia and I worked side by side at the cafe",
      "Video call with Dad, he showed me his tomatoes",
      "Client meeting where I actually felt heard",
      "Luca cooked while I sketched nearby, no words needed",
      "Caught up with my old uni roommate",
      "Nadia told me I looked happier lately, meant a lot",
      "Dinner party at Luca's — I actually enjoyed it",
      "Dad sent a photo of us from when I was ten",
      "Good conversation at the co-working space with a stranger",
    ],
    'selfcare': [
      "Took a long bath with a book, no guilt",
      "Slept in on purpose and it was great",
      "Said no to weekend work, went to the park",
      "Bought myself flowers, just because",
      "Ordered the expensive tea, treated myself",
      "Left the studio early and walked home slowly",
      "Deleted social media apps for the weekend",
      "Nap on the couch with the cat noise playlist",
      "Booked a massage for next week",
      "Read fiction instead of business books",
    ],
    'reflection': [
      "I take on too much because I'm scared to say no",
      "Need to stop working when I'm tired, the work suffers",
      "I was impatient with Luca and he didn't deserve it",
      "Skipped the run again, it's becoming a pattern",
      "Comparing my year 1 to someone's year 10",
      "I procrastinate on admin because it feels beneath me",
      "Should have asked for help sooner on that project",
      "The perfectionism is the problem, not the skill",
      "I forget to eat when I'm in the zone, that's not healthy",
      "Need to separate my self-worth from client feedback",
    ],
    'presence': [
      "Luca humming while making breakfast",
      "Sunlight hitting the desk at golden hour",
      "That first sip of espresso, eyes closed",
      "Sketching with no plan, just shapes",
      "Wind through the open window during a call",
      "Nadia laughing so hard she snorted",
      "The sound of rain while painting",
      "Sitting in the park watching dogs play",
      "Finishing a drawing and just… looking at it",
      "Stars on the balcony with Luca, saying nothing",
    ],
  };

  Future<void> _generateWeeklySummaries(
    DateTime now,
    List<Entry> entries,
    List<ReflectionAnswer> answers,
    Direction creativityDirection,
    Direction healthDirection,
    Direction relationshipsDirection,
    Direction growthDirection,
    Direction peaceDirection,
  ) async {
    final summaryBox = await Hive.openBox<WeeklySummary>('weekly_summaries');
    final connectionsBox = await Hive.openBox<DirectionConnection>(
      'direction_connections',
    );

    final entryAnswersMap = <String, List<ReflectionAnswer>>{};
    for (final answer in answers) {
      entryAnswersMap.putIfAbsent(answer.entryId, () => []).add(answer);
    }

    final entryDirectionsMap = <String, Set<String>>{};
    for (final connection in connectionsBox.values) {
      entryDirectionsMap
          .putIfAbsent(connection.entryId, () => {})
          .add(connection.directionId);
    }

    final oldestDate = now.subtract(const Duration(days: 90));
    final firstMonday = _startOfWeek(oldestDate);
    final currentWeekStart = _startOfWeek(now);

    DateTime weekStart = firstMonday;
    final summaries = <WeeklySummary>[];
    double? previousWeekAvgMood;

    while (weekStart.isBefore(currentWeekStart)) {
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weekEntries = entries.where((entry) {
        return !entry.createdAt.isBefore(weekStart) &&
            entry.createdAt.isBefore(weekEnd);
      }).toList();

      if (weekEntries.isEmpty) {
        weekStart = weekEnd;
        continue;
      }

      weekEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final checkInCount = weekEntries.length;
      final daysWithEntries = weekEntries
          .map(
            (e) =>
                DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day),
          )
          .toSet()
          .length;
      final avgMood =
          weekEntries.map((e) => e.moodValue).reduce((a, b) => a + b) /
          weekEntries.length;

      String moodTrend = 'stable';
      if (previousWeekAvgMood != null) {
        final difference = avgMood - previousWeekAvgMood;
        if (difference >= 0.05) {
          moodTrend = 'up';
        } else if (difference <= -0.05) {
          moodTrend = 'down';
        }
      }

      final moodCounts = <String, int>{};
      for (final entry in weekEntries) {
        moodCounts[entry.moodWord] = (moodCounts[entry.moodWord] ?? 0) + 1;
      }
      final mostFeltMood = moodCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      final bestEntry = weekEntries.reduce(
        (a, b) => a.moodValue > b.moodValue ? a : b,
      );
      final weekdayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final bestMoodDay = weekdayNames[bestEntry.createdAt.weekday - 1];
      final bestMoodValue = bestEntry.moodValue;
      final bestMoodWord = bestEntry.moodWord;

      final directionSummaries = <Map<String, dynamic>>[];
      String? topDirectionId;
      double highestMoodDifference = -999.0;

      final directions = [
        (creativityDirection, 'creativity'),
        (healthDirection, 'health'),
        (relationshipsDirection, 'relationships'),
        (growthDirection, 'growth'),
        (peaceDirection, 'peace'),
      ];

      for (final (direction, _) in directions) {
        final weeklyConnections = weekEntries.where((entry) {
          return entryDirectionsMap[entry.id]?.contains(direction.id) ?? false;
        }).length;

        final allConnectedEntries = entries.where((entry) {
          return entryDirectionsMap[entry.id]?.contains(direction.id) ?? false;
        }).toList();

        double avgMoodWhenConnected = 0.0;
        if (allConnectedEntries.isNotEmpty) {
          avgMoodWhenConnected =
              allConnectedEntries
                  .map((e) => e.moodValue)
                  .reduce((a, b) => a + b) /
              allConnectedEntries.length;
        }

        final overallAvgMood =
            entries.map((e) => e.moodValue).reduce((a, b) => a + b) /
            entries.length;
        final moodDifference = avgMoodWhenConnected - overallAvgMood;

        directionSummaries.add({
          'directionId': direction.id,
          'title': direction.title,
          'iconAsset': direction.type.iconAsset,
          'weeklyConnections': weeklyConnections,
          'avgMoodWhenConnected': avgMoodWhenConnected,
          'moodDifference': moodDifference,
        });

        if (moodDifference >= 0.1 && moodDifference > highestMoodDifference) {
          highestMoodDifference = moodDifference;
          topDirectionId = direction.id;
        }
      }

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

        standoutReflectionAnswers.add({
          'questionText': weekAnswers.first.questionText,
          'answer': weekAnswers.first.answer,
        });

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
        createdAt: weekEnd,
        viewedAt: null,
      );

      summaries.add(summary);
      previousWeekAvgMood = avgMood;
      weekStart = weekEnd;
    }

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
        viewedAt: isLastSummary
            ? null
            : summary.createdAt.add(const Duration(hours: 2)),
      );

      await summaryBox.put(finalSummary.id, finalSummary);
    }
  }

  DateTime _startOfWeek(DateTime date) {
    final weekday = date.weekday;
    final mondayDate = date.subtract(Duration(days: weekday - 1));
    return DateTime(mondayDate.year, mondayDate.month, mondayDate.day);
  }

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
    final weekOfYear = _weekOfYear(weekStart);
    final seed = weekOfYear % 20;

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
            ? 'Seven for seven. You showed up every single day. That matters.'
            : 'You checked in $checkInCount times this week. Each one is a moment of clarity.';

      case 1:
        return hasReflections
            ? 'Your reflections this week were honest and real. That\'s where growth lives.'
            : 'Even without deep reflections, showing up is the practice.';

      case 2:
        return bestMoodDay != null
            ? '$bestMoodDay brought the best energy. What made it different?'
            : 'The week had its rhythm. You stayed with it.';

      case 3:
        return totalConnections > 0 && topDirection != null
            ? '$topDirection showed up $topConnections times. That focus is telling you something.'
            : 'You made $checkInCount check-ins. That\'s $checkInCount small acts of self-awareness.';

      case 4:
        return moodTrend == 'up'
            ? 'Your mood climbed this week. Something shifted — notice what it was.'
            : 'Steady weeks are underrated. You held your ground.';

      case 5:
        return avgMood >= 0.6
            ? 'A lighter week. Something\'s clicking — trust it.'
            : 'Heavy weeks teach you the most. You didn\'t look away.';

      case 6:
        return hasReflections
            ? 'The questions you answered reveal someone paying attention. Keep going.'
            : 'Showing up when it\'s hard is the whole point. You did that.';

      case 7:
        return checkInCount >= 6
            ? 'Nearly every day. You\'re building a real practice here.'
            : 'Every check-in is a choice. You made that choice $checkInCount times.';

      case 8:
        return bestMoodWord != null
            ? 'You felt $bestMoodWord on $bestMoodDay. What can you carry from that?'
            : 'Another week of data about who you are. Keep collecting.';

      case 9:
        return totalConnections > 0
            ? '$totalConnections direction connections. You\'re linking feelings to meaning.'
            : 'Progress is quieter than you think. It\'s happening.';

      case 10:
        return moodTrend == 'down'
            ? 'A harder week, but you kept checking in. That takes courage.'
            : 'Consistent effort, quiet growth. You\'re doing the work.';

      case 11:
        return hasReflections && avgMood >= 0.5
            ? 'Good mood, thoughtful reflections. You\'re finding your rhythm.'
            : 'One week at a time. You\'re right where you need to be.';

      case 12:
        return checkInCount >= 5
            ? 'Five check-ins this week. This is becoming a habit worth keeping.'
            : 'Even a few check-ins matter. Quality over quantity.';

      case 13:
        return topDirection != null && topConnections >= 3
            ? '$topDirection got your attention. That focus is valuable.'
            : 'You\'re learning what matters. That clarity takes time.';

      case 14:
        return avgMood < 0.35 && checkInCount >= 3
            ? 'Hard weeks deserve reflection. You gave yourself that.'
            : 'Self-awareness is a practice. You\'re practicing.';

      case 15:
        return moodTrend == 'up' && hasReflections
            ? 'Mood up and reflections deep. That combination is rare and powerful.'
            : 'You\'re building a record of your inner life. That\'s meaningful work.';

      case 16:
        return bestMoodDay == 'Saturday' || bestMoodDay == 'Sunday'
            ? 'Weekends recharge you. How can you bring that energy into Wednesday?'
            : 'Midweek was your peak. You thrive when you\'re creating.';

      case 17:
        return checkInCount == 7
            ? 'A full week of showing up. Your commitment is becoming part of who you are.'
            : 'Not every week is perfect. You still showed up $checkInCount times.';

      case 18:
        return hasReflections
            ? 'Your answers this week had real depth. Don\'t underestimate that.'
            : 'Sometimes just naming the mood is enough. You did that.';

      case 19:
      default:
        return totalConnections > 0
            ? '$totalConnections connections to your directions. You\'re living with intention.'
            : 'Another week of choosing yourself. That\'s the foundation of everything.';
    }
  }

  int _weekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceStart = date.difference(firstDayOfYear).inDays;
    return (daysSinceStart / 7).floor() + 1;
  }
}
