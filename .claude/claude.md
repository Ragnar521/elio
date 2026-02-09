# Elio - App Context & Architecture

**Last Updated:** February 9, 2026
**Version:** 1.1.0
**Platform:** Flutter (iOS & Android)

---

## 📱 What is Elio?

Elio is a **mood tracking and journaling app** that helps users check in with their emotions, set daily intentions, reflect on their experiences, and connect entries to life areas they care about (Directions). The app emphasizes simplicity, no-guilt design, and meaningful self-reflection.

### Core Philosophy
- **Simple & Fast**: Quick daily check-ins (< 2 minutes)
- **No Guilt**: Optional features, positive language, "skip" buttons
- **Mindful Design**: Warm, calm color palette and smooth animations
- **Privacy-First**: All data stored locally on device (Hive database)
- **Compass, Not Checklist**: Directions help awareness without pressure

---

## 🎯 Core User Flow

```
┌─────────────┐
│ Onboarding  │ (First launch only)
└─────┬───────┘
      │
┌─────▼────────────────────────────────────────────────────────────┐
│ Main App (Bottom Navigation - 5 Tabs)                            │
├──────────┬──────────┬────────────┬──────────┬────────────────────┤
│   Home   │ Insights │ Directions │ History  │     Settings       │
└─────┬────┴──────────┴────────────┴──────────┴────────────────────┘
      │
┌─────▼───────┐
│ Mood Entry  │ Select mood on slider (0.0 to 1.0)
└─────┬───────┘
      │
┌─────▼────────┐
│  Intention   │ Set daily intention (text input)
└─────┬────────┘
      │
┌─────▼──────────────┐
│ Reflection (opt.)  │ Answer 1-3 questions (if enabled)
└─────┬──────────────┘
      │
┌─────▼──────────┐
│ Confirmation   │ Save entry, show streak
└─────┬──────────┘
      │
┌─────▼────────┐
│ Back to Home │
└──────────────┘
```

---

## 🏗️ Technical Architecture

### State Management
- **Pattern:** StatefulWidget + Service Layer (no Provider/Bloc)
- **Why:** Simplicity, matches existing codebase, sufficient for app scale
- **Services:** Singleton pattern with `instance` getter

### Storage
- **Database:** Hive (NoSQL, local-first)
- **Location:** Device storage only (no cloud sync)
- **Boxes:**
  - `entries` - Mood entries
  - `reflectionQuestions` - Question library
  - `reflectionAnswers` - User answers
  - `directions` - Life directions (max 5 active)
  - `direction_connections` - Entry-to-direction links
  - `settings` - App settings (key-value pairs)

### Navigation
- **System:** Flutter Navigator 2.0 (MaterialPageRoute)
- **Pattern:** Push/pop for screens, bottom navigation for main tabs
- **No routing package:** Keeps it simple

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point, service initialization
├── models/                      # Data models with Hive adapters
│   ├── entry.dart              # Mood entry (typeId: 0)
│   ├── reflection_question.dart # Question (typeId: 1)
│   ├── reflection_answer.dart  # Answer (typeId: 2)
│   ├── direction.dart          # Direction + DirectionType enum (typeId: 4, 5)
│   ├── direction_connection.dart # Entry-Direction link (typeId: 6)
│   └── direction_stats.dart    # Direction analytics (no Hive)
├── services/                    # Business logic & data layer
│   ├── storage_service.dart    # Entry storage, settings, streaks
│   ├── reflection_service.dart # Question management, rotation
│   ├── insights_service.dart   # Analytics calculations + direction insights
│   ├── direction_service.dart  # Direction CRUD, connections, stats
│   └── notification_service.dart # Local notifications (future)
├── screens/                     # UI screens
│   ├── home_shell.dart         # Bottom navigation wrapper (5 tabs)
│   ├── mood_entry_screen.dart  # Mood slider
│   ├── intention_screen.dart   # Intention input
│   ├── reflection_screen.dart  # Reflection questions (1-3)
│   ├── confirmation_screen.dart # Save confirmation
│   ├── directions_screen.dart  # Directions main tab
│   ├── create_direction_screen.dart # Create new direction
│   ├── direction_detail_screen.dart # Direction stats & settings
│   ├── connect_entries_screen.dart  # Link entries to direction
│   ├── history_screen.dart     # Entry timeline
│   ├── entry_detail_screen.dart # Full entry view
│   ├── insights_screen.dart    # Analytics & patterns
│   ├── settings_screen.dart    # App settings
│   ├── reflection_settings_screen.dart # Manage questions
│   ├── question_library_screen.dart # Browse questions
│   ├── custom_question_screen.dart  # Create custom question
│   └── onboarding/             # First-time setup
│       ├── onboarding_flow.dart
│       ├── welcome_screen.dart
│       ├── name_screen.dart
│       ├── first_checkin_screen.dart
│       └── onboarding_complete_screen.dart
├── widgets/                     # Reusable components
│   ├── entry_card.dart         # Entry in history list
│   ├── answered_question_chip.dart # Collapsed answer
│   ├── direction_card.dart     # Direction with stats (NEW)
│   ├── mood_wave.dart          # Interactive wave with tap-to-view
│   ├── stat_card.dart          # Stat display with comparison
│   ├── insight_card.dart       # Multiple insights display
│   ├── day_pattern_chart.dart  # Tappable day-of-week chart
│   └── day_entries_sheet.dart  # Bottom sheet for day entries
└── theme/                       # Design system
    ├── elio_theme.dart         # ThemeData for light/dark
    ├── elio_colors.dart        # Color palette
    └── elio_text_theme.dart    # Typography
```

---

## 🎨 Design System

### Color Palette

**Dark Mode (Primary):**
```dart
Background:   #1C1C1E  (Warm Charcoal)
Surface:      #313134  (Soft Graphite)
Primary Text: #F9DFC1  (Soft Cream)
Accent:       #FF6436  (Warm Orange)
Focus:        #E5562E  (Pressed state)
```

**Light Mode (Not primary focus):**
```dart
Background:   #FAFAFA  (Off White)
Surface:      #FFFFFF  (Pure White)
Primary Text: #1C1C1E  (Dark Gray)
Accent:       #FF6436  (Warm Orange)
```

### Typography
- **Font:** System default (San Francisco on iOS, Roboto on Android)
- **Sizes:**
  - Headline Large: 32px, weight 700
  - Headline Medium: 28px, weight 600
  - Headline Small: 24px, weight 600
  - Body Large: 18px, weight 400
  - Body Medium: 16px, weight 400
  - Body Small: 14px, weight 400
  - Label: 12px, weight 600, uppercase

### Border Radius
- **Cards:** 18px
- **Buttons:** 18px
- **Input fields:** 18px
- **Chips:** 14px
- **Small elements:** 8px

### Spacing
- **Small:** 8px
- **Medium:** 16px
- **Large:** 24px
- **XLarge:** 32px

---

## 📊 Data Models

### Entry
```dart
Entry {
  id: String (UUID)
  moodValue: double (0.0 to 1.0)
  moodWord: String ("Calm", "Energized", etc.)
  intention: String (max 100 chars)
  createdAt: DateTime
  reflectionAnswerIds: List<String>? (optional)
}
```

**Mood Value Scale:**
- 0.0 - 0.33: Low mood (e.g., "Tired", "Overwhelmed")
- 0.33 - 0.66: Mid mood (e.g., "Calm", "Balanced")
- 0.66 - 1.0: High mood (e.g., "Energized", "Joyful")

### ReflectionQuestion
```dart
ReflectionQuestion {
  id: String (UUID)
  text: String (the question)
  category: String (gratitude, pride, learning, etc.)
  isCustom: bool (false for library, true for user-created)
  isFavorite: bool (max 2 favorites allowed)
  isSelected: bool (in user's active pool)
  createdAt: DateTime
}
```

**Categories (9 total):**
- gratitude
- pride
- learning
- energy
- tomorrow
- connection
- selfcare
- reflection
- presence

### ReflectionAnswer
```dart
ReflectionAnswer {
  id: String (UUID)
  entryId: String (links to Entry)
  questionId: String (links to ReflectionQuestion)
  questionText: String (snapshot at time of answer)
  answer: String (max 200 chars)
  createdAt: DateTime
}
```

### Direction (NEW - v1.1.0)
```dart
Direction {
  id: String (UUID)
  title: String (max 50 chars, user-defined)
  type: DirectionType (enum: career, health, relationships, growth, peace, creativity)
  reflectionEnabled: bool (show direction questions during check-in)
  isArchived: bool (soft delete, default: false)
  createdAt: DateTime
}

DirectionType {
  career       // 💼
  health       // 💪
  relationships // 👥
  growth       // 🌱
  peace        // 🧘
  creativity   // 🎨
}
```

**Key Features:**
- Max 5 active directions per user (enforced)
- Each type has example prompts and reflection questions
- Archive functionality preserves connections

### DirectionConnection (NEW - v1.1.0)
```dart
DirectionConnection {
  id: String (UUID)
  directionId: String (links to Direction)
  entryId: String (links to Entry)
  createdAt: DateTime
}
```

**Purpose:** Many-to-many relationship - one entry can connect to multiple directions

### DirectionStats (NEW - v1.1.0)
```dart
DirectionStats {
  totalConnections: int
  monthlyConnections: int
  monthlyTarget: int (always 10)
  avgMoodWhenConnected: double
  overallAvgMood: double
  recentEntries: List<Entry> (last 5)

  // Computed properties:
  moodDifference: double (avgWhenConnected - overallAvg)
  monthlyProgress: double (0.0 - 1.0, for progress bar)
  hasPositiveCorrelation: bool (difference >= 0.1)
  hasNegativeCorrelation: bool (difference <= -0.1)
}
```

---

## ⚙️ Key Services

### StorageService
**Location:** `lib/services/storage_service.dart`

**Purpose:** Manages entries and app settings

**Key Methods:**
```dart
init()                          # Initialize Hive, register adapters, backfill streak
saveEntry(...)                  # Save mood entry + auto-update longest streak
getAllEntries()                 # Get all entries, sorted by date
getEntriesForDate(date)        # Entries for specific day
getEntriesForPeriod(start, end) # Entries within date range (NEW)
getCurrentStreak()              # Calculate check-in streak
getLongestStreak()              # Get all-time longest streak (NEW)
updateLongestStreak(current)    # Update if current > longest (NEW)
_backfillLongestStreak()        # Calculate from existing entries on first run (NEW)
userName                        # Getter/setter for user name
onboardingCompleted            # Getter/setter
reflectionEnabled              # Getter/setter (default: true)
notificationsEnabled           # Getter/setter
```

**Settings Keys:**
- `user_name`
- `onboarding_completed`
- `notifications_enabled`
- `reflection_enabled`
- `longest_streak` (NEW - tracks all-time best)

### ReflectionService
**Location:** `lib/services/reflection_service.dart`

**Purpose:** Manages reflection questions and answers

**Key Methods:**
```dart
init()                          # Initialize Hive, seed questions
getNextQuestion(answeredIds)    # Get next question (favorites first, then rotate)
saveAnswer(...)                 # Save reflection answer
getAllQuestions()               # All 27 library questions
getSelectedQuestions()          # User's active question pool
getFavoriteQuestions()          # Max 2 favorites
getQuestionsByCategory()        # Grouped by category
toggleFavorite(questionId)      # Star/unstar (max 2)
toggleSelected(questionId)      # Add/remove from pool
addCustomQuestion(...)          # Create user question
deleteQuestion(questionId)      # Delete custom question only
getAnswersByIds(ids)           # Fetch answers for entry detail
```

**Question Rotation Logic:**
1. Favorites first (0-2 questions)
2. Remaining questions rotate daily
3. Rotation based on day of year (deterministic)
4. Formula: `dayOfYear % rotatingQuestions.length`

**Seeding:**
- Happens automatically on first launch
- 27 questions total
- 5 "Elio Essentials" pre-selected
- All others available in library

### DirectionService (NEW - v1.1.0)
**Location:** `lib/services/direction_service.dart`

**Purpose:** Manages life directions and entry connections

**Key Methods:**
```dart
// Initialization
init()                          # Initialize Hive, register adapters

// CRUD
getActiveDirections()           # Get all non-archived directions (max 5)
getAllDirections()              # Including archived
getDirection(id)                # Get by ID
canAddDirection()               # Check if < 5 active
createDirection(...)            # Create new direction
updateDirection(direction)      # Update existing
archiveDirection(id)            # Soft delete
restoreDirection(id)            # Unarchive (if < 5 active)
deleteDirection(id)             # Permanent delete + connections

// Connections
connectEntry(directionId, entryId)      # Link entry to direction
disconnectEntry(directionId, entryId)   # Unlink
isEntryConnected(directionId, entryId)  # Check connection
getConnectedEntries(directionId)        # All entries for direction
getDirectionsForEntry(entryId)          # All directions for entry
getUnconnectedEntries(directionId)      # Recent entries not yet connected

// Statistics
getConnectionCount(directionId)         # Total connections
getMonthlyConnectionCount(directionId)  # Connections this month
getAverageMoodWhenConnected(directionId) # Avg mood for this direction
getOverallAverageMood()                 # Avg mood for all entries
getStats(directionId)                   # Complete DirectionStats object

// Reflection Integration
getDirectionsWithReflection()           # Directions with reflectionEnabled=true
getDailyDirectionQuestion()             # Random question from enabled directions
getDirectionForQuestion(question)       # Find direction by question text

// Insights Integration
getFrequentDirectionsThisWeek()         # Directions with 5+ connections in 7 days
getWeeklyConnectionCount(directionId)   # Connections in past 7 days
getDormantDirections()                  # No connections in 7+ days
getDirectionsWithMoodCorrelation()      # Sorted by mood difference (±0.1 threshold)
```

### InsightsService
**Location:** `lib/services/insights_service.dart`

**Purpose:** Calculate analytics and patterns + direction insights

**Key Methods:**
```dart
buildSnapshot(...)                      # Synchronous method (legacy compatibility)
getInsightsForPeriod(...)              # Full insights with all new features
_calculateReflectionStats(entries)     # Count reflection days & rate
_calculateDayOfWeekPattern(entries)    # Average mood per weekday
_findBestWorstDays(pattern)            # Identify best/worst days (15% threshold)
_calculateLongestStreakInPeriod(...)   # Find longest consecutive streak
_generateInsights(...)                 # Generate 2-3 priority-based insights
_generatePatternInsight(...)           # Create actionable day pattern suggestion
```

**Data Model: InsightsData**
- **Period info:** start, end, days in period, entries
- **Stats:** check-in count, days with entries, current streak, most felt mood
- **Mood metrics:** average, std deviation, trend (up/down), stable/volatile
- **Reflection tracking:** reflection days, reflection rate
- **Streak tracking:** longest all-time, longest in period
- **Comparison:** previous period avg, check-ins, mood change %, check-in change
- **Day patterns:** day-of-week averages, best day, worst day
- **Insights:** 2-3 generated InsightItems with emoji icons (priorities 1-18)
- **Pattern insight:** actionable suggestion based on day patterns

**Direction Insights (Priorities 15-18, Week View Only):**
- Priority 15: Frequent directions (5+ connections this week)
- Priority 16: Positive mood correlations (≥0.15 higher when connected)
- Priority 17: Negative mood correlations (≤-0.1 lower when connected)
- Priority 18: Dormant directions (no connections in 7+ days)

---

## 🎯 Feature Details

### 1. Mood Entry
- Vertical slider (0.0 to 1.0)
- Dynamic mood word based on value
- Color gradient (low mood → high mood)
- Smooth animations
- Continue button appears when mood selected

### 2. Intention Setting
- Text input (max 100 characters)
- Mood-adaptive prompt:
  - Low: "What's one small thing that could help?"
  - Mid: "What do you want to focus on?"
  - High: "What will you carry this energy into?"
- 3 contextual suggestions (tap to auto-fill)
- Continue when text entered

### 3. Reflection Questions
**Enabled by default**, can be disabled in Settings

**Flow:**
1. Show 1 question
2. User types answer (max 200 chars, 3 lines)
3. Options:
   - "+ Another question" (max 3 total)
   - "Continue" (saves current + previous)
   - "Skip for today" (no answers saved)
4. Previous answers collapsed with checkmark
5. After 3rd question, only "Continue" shows

**Question Selection:**
- Favorites always first (max 2)
- Then daily rotation from selected pool
- Same question all day (based on dayOfYear)
- Won't show already-answered questions

**Settings:**
- Toggle on/off
- Manage question pool
- Star up to 2 favorites
- Add from library (27 questions)
- Create custom questions
- Remove from pool

### 4. Confirmation
- Animated glow effect
- Random affirmation:
  - "You checked in."
  - "Noted."
  - "Clarity captured."
  - "You showed up."
- Shows: mood, intention (truncated), reflection chips
- Displays current streak
- Auto-saves entry
- Tap anywhere or "Done" to exit

### 5. History
- Timeline of all entries
- Grouped by date (Today, Yesterday, weekday, date)
- Entry cards show:
  - Mood color indicator
  - Mood word
  - Time (12:45 PM)
  - Intention (truncated)
- Pull to refresh
- Empty state message
- Tap entry → Entry Detail Screen

### 6. Entry Detail
**New screen** showing full entry:
- Date & time
- Mood section with:
  - Color dot
  - Mood word
  - Intensity bar (LinearProgressIndicator)
- Full intention (not truncated)
- Reflections section (if any):
  - Each Q&A in separate card
  - Question icon
  - Question text (muted)
  - Answer text (full)

### 7. Insights (Redesigned - Feb 2026)
**Complete redesign with advanced analytics and interactions**

**Period Navigation:**
- Week/Month toggle
- Arrow navigation (‹ ›) with visual feedback
- Swipe gestures (left/right)
- Animated transitions (300ms fade + slide)
- Period label showing date range

**Interactive Mood Wave:**
- Tap any dot to see tooltip
- Tooltip shows: date, time, mood, intention preview
- "View Entry →" button navigates to full entry detail

**Comparison Line:**
- Shows current period average mood
- Displays percentage change vs previous period
- Color-coded: green (positive), neutral (negative)

**Multiple Insights (2-3):**
- Priority-based generation (14 rules)
- Each with emoji icon (🔥📈✨💪📝⚖️🌊☀️🌱👣)
- Focus on streaks, trends, reflections, mood patterns
- Non-judgmental, supportive language

**4 Stat Cards (Equal Width):**
- **Week View:**
  1. Check-ins: "5 of 7 days ↑2"
  2. Streak: "3 days, best: 8"
  3. Reflections: "80%, 4 of 5"
  4. Most felt: "Calm"

- **Month View:**
  1. Check-ins: "22 of 28 days ↑5"
  2. Streak: "3 current, best: 12"
  3. Reflections: "75%, 17 of 22"
  4. Most felt: "Calm, 8 times"

**Day Pattern Chart (Interactive):**
- Horizontal bars for Mon-Sun
- Shows average mood per weekday
- Emojis on best (😊) and worst (😔) days
- **Tappable:** Tap any day → bottom sheet with filtered entries
- Visual indicator (chevron) shows tappability

**Day Entries Bottom Sheet:**
- Shows all entries for selected weekday
- Header: "Mondays • 0.45 avg"
- Entry count: "3 entries found"
- Scrollable entry cards (date, time, mood, intention)
- Tap entry → navigate to EntryDetailScreen
- Draggable to dismiss

**Pattern Insight:**
- Actionable suggestion based on day patterns
- Examples: "Mondays are your toughest day. Consider a gentler start to the week."
- Only shows when meaningful pattern exists (15% difference)

**Animations:**
- Period transitions: 300ms fade + slide
- Direction-aware (slides from correct side)
- Bottom sheet: smooth drag + spring animation
- Stat cards: consistent height for visual harmony

### 8. Directions (NEW - v1.1.0, 3rd Tab)
**Main tab showing life compass**

**Empty State:**
- Large compass emoji 🧭
- "What matters to you?" heading
- Explanation text
- "Add Your First Direction" button

**Directions List:**
- Header: "Your life compass. Connect your daily check-ins to see patterns."
- Direction cards showing:
  - Type emoji + custom title
  - Total connections count
  - Monthly progress bar (target: 10)
  - Average mood (if ≥3 connections)
  - Reflection questions status (On/Off)
- "Add direction (X of 5)" card at bottom (if < 5)
- Tap card → Direction Detail Screen

**Direction Detail Screen:**
- Overview card: Total connections, monthly progress
- Mood correlation card:
  - "When connected" avg vs "Overall avg"
  - Difference indicator (green ↑ higher / orange ↓ lower)
  - Only shows if data available
- "Connect an Entry" button
- Recent connections list (last 5)
  - Tap entry → Entry Detail Screen
- Settings: Reflection questions toggle
- Archive button (bottom)

**Create Direction Screen:**
- Type picker grid (3x2):
  - 💼 Career, 💪 Health, 👥 Relationships
  - 🌱 Growth, 🧘 Peace, 🎨 Creativity
- Custom title input (max 50 chars)
- Example prompts for selected type
- Reflection toggle
- Create button

**Connect Entries Screen:**
- Segmented control: Unconnected / Connected
- Multi-select checkboxes
- Shows: mood emoji, intention, date/time
- "Connect (N)" button in app bar (when selections made)

**Key Features:**
- Max 5 active directions (enforced)
- Archive instead of delete (preserves connections)
- Mood correlation analysis (±0.1 threshold)
- Monthly target: 10 connections
- Direction-specific reflection questions (optional)

### 9. Settings (5th Tab)
- User name display
- Daily Reflection toggle
  - When ON: "Manage reflection questions" button
- Future: notifications, theme, export, etc.

### 10. Onboarding

### 9. Onboarding
**First launch only:**
1. Welcome screen
2. Name input
3. First check-in (mood + intention)
4. Completion screen
5. → Main app

**Debug feature:**
- Triple-tap Home icon to reset onboarding

---

## 🔧 Development Notes

### Running the App
```bash
flutter pub get
flutter run
```

### After Code Changes
```bash
# If changing Hive models
flutter packages pub run build_runner build

# Clean build (recommended after major changes)
flutter clean
flutter pub get
flutter run
```

### Important Patterns

**1. Service Initialization (main.dart)**
```dart
await StorageService.instance.init();
await ReflectionService.instance.init();  # Seeds questions
await NotificationService.instance.init();
```

**2. Hive TypeIds**
- 0: Entry
- 1: ReflectionQuestion
- 2: ReflectionAnswer
- 4: DirectionType (enum)
- 5: Direction
- 6: DirectionConnection

**Note:** TypeId 3 is reserved for future use. Manual Hive adapters are used (no build_runner).

**3. Navigation Examples**
```dart
// Push new screen
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => NewScreen()),
);

// Replace current screen
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => NewScreen()),
);

// Pop to first route
Navigator.of(context).popUntil((route) => route.isFirst);
```

**4. Accessing Services**
```dart
// Storage
final userName = StorageService.instance.userName;
final entries = await StorageService.instance.getAllEntries();

// Reflection
final question = ReflectionService.instance.getNextQuestion([]);
await ReflectionService.instance.saveAnswer(...);
```

**5. Theming**
```dart
// Use theme colors
Theme.of(context).textTheme.headlineSmall
ElioColors.darkAccent
ElioColors.darkPrimaryText.withOpacity(0.6)
```

---

## 🐛 Known Issues & Fixes

### Issue: "ReflectionService not initialized"
**Cause:** Hot reload disrupts service initialization
**Fix:** Full app restart (stop + run, not hot reload)

### Issue: Deprecation warnings (withOpacity)
**Status:** Known, cosmetic only
**Fix:** Not critical, exists throughout codebase

### Issue: Test file error (MyApp class)
**Status:** Ignored, template test file
**Fix:** Not blocking development

---

## 📝 Code Style & Conventions

### File Naming
- `snake_case.dart` for all files
- Screens: `*_screen.dart`
- Services: `*_service.dart`
- Models: model name (e.g., `entry.dart`)

### Class Naming
- `PascalCase` for classes
- `camelCase` for variables/methods
- `_privateMethod` for private methods

### Widget Structure
```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key, required this.param});

  final String param;

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

### Error Handling
```dart
try {
  await operation();
} catch (e) {
  debugPrint('Error: $e');
  // Handle gracefully, don't crash
}
```

---

## 🚀 Future Enhancements (Not Yet Implemented)

### High Priority
- [ ] Edit existing entries
- [ ] Delete entries
- [ ] Export data (JSON/CSV)
- [ ] Reflection insights/analytics
- [ ] Search entries

### Medium Priority
- [ ] Tags for entries
- [ ] Photo attachments
- [ ] Voice notes
- [ ] Reminder notifications
- [ ] Dark/light mode toggle

### Low Priority
- [ ] Cloud backup
- [ ] Multi-device sync
- [ ] Themes/customization
- [ ] Sharing entries
- [ ] Goal tracking

---

## 📚 Dependencies

### Core
```yaml
flutter_sdk: ^3.10.8
cupertino_icons: ^1.0.8
```

### Storage
```yaml
hive: ^2.2.3
hive_flutter: ^1.1.0
uuid: ^4.5.1
```

### Notifications
```yaml
flutter_local_notifications: ^17.1.2
```

### Dev
```yaml
flutter_lints: ^6.0.0
flutter_launcher_icons: ^0.14.2
```

---

## 🤝 Working with This Codebase

### For New Developers
1. Read this document first
2. Review `reflection-questions.md` for reflection feature details
3. Run the app and complete onboarding
4. Explore each screen in the flow
5. Check `lib/theme/` for design system
6. Look at existing screens as patterns

### For Claude Code Sessions
1. This file contains complete app context
2. Don't guess at architecture - it's documented here
3. Follow existing patterns (StatefulWidget + Services)
4. Match the design system (colors, spacing, radius)
5. Test changes with full restart, not hot reload
6. Update this file if you make major changes

### Making Changes
1. **New Feature:** Create in appropriate folder (screens/services/models)
2. **New Model:** Add Hive adapter, register in main.dart
3. **New Service:** Singleton pattern, init() method
4. **New Screen:** Follow existing screen patterns
5. **Breaking Change:** Update this documentation

---

## 📞 Support & Resources

### Documentation
- This file (claude.md) - Complete app context
- reflection-questions.md - Reflection feature spec
- Flutter docs: https://docs.flutter.dev
- Hive docs: https://docs.hivedb.dev

### Color Reference
- Background: `ElioColors.darkBackground` (#1C1C1E)
- Surface: `ElioColors.darkSurface` (#313134)
- Text: `ElioColors.darkPrimaryText` (#F9DFC1)
- Accent: `ElioColors.darkAccent` (#FF6436)

### Common Commands
```bash
flutter pub get              # Install dependencies
flutter run                  # Run app
flutter clean                # Clean build
flutter analyze              # Check for issues
flutter pub outdated         # Check dependency updates
```

---

**End of Documentation**

*Keep this file updated as the app evolves. Future you (or future Claude) will thank you!* 🙏
