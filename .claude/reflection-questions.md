# Elio — Reflection Questions

## Context
Elio is a mood tracking app. The core flow exists: Mood Entry → Intention → Confirmation. Now we're adding daily reflection questions between Intention and Confirmation. This is not a separate module — it's part of the core flow, toggled on/off in Settings.

## Flow Position

```
Mood → Intention → [Reflection Questions] → Confirmation
```

## How It Works

### Question Selection Logic

1. **Favorites first (⭐)** — User can mark 0-2 questions as favorites. These always show first, in order.
2. **Rotating pool** — Remaining questions rotate daily from user's selected pool.

### Daily Check-in UX

- Show 1 question by default
- After answering, show "+ Another question" button
- User can answer up to 3 questions per check-in
- After 3rd question, only "Continue" button shows
- "Skip for today" always available (no guilt messaging)

## Screen Layout

```
┌─────────────────────────────────────┐
│                                     │
│   What are you grateful for today?  │
│                                     │
│   ┌─────────────────────────────┐   │
│   │                             │   │
│   │ [Text input area]           │   │
│   │                             │   │
│   └─────────────────────────────┘   │
│                                     │
│   [Continue]    [+ Another question]│
│                                     │
│          Skip for today             │
│                                     │
└─────────────────────────────────────┘
```

### After answering (before 3rd question):

```
┌─────────────────────────────────────┐
│                                     │
│   ✓ Grateful for: Had a great...    │  ← collapsed previous answer
│                                     │
│   What gave you energy today?       │  ← new question
│                                     │
│   ┌─────────────────────────────┐   │
│   │                             │   │
│   │ [Text input area]           │   │
│   │                             │   │
│   └─────────────────────────────┘   │
│                                     │
│   [Continue]    [+ Another question]│
│                                     │
└─────────────────────────────────────┘
```

### After 3rd question:

```
┌─────────────────────────────────────┐
│                                     │
│   ✓ Grateful for: Had a great...    │
│   ✓ Energy from: Morning workout    │
│   ✓ Proud of: Finished the draft    │
│                                     │
│           [Continue]                │
│                                     │
└─────────────────────────────────────┘
```

## Data Models

```dart
// Reflection Question
ReflectionQuestion {
  id: String (UUID)
  text: String
  category: String (gratitude, pride, learning, energy, tomorrow, connection, selfcare, reflection, presence)
  isCustom: bool (false for library questions, true for user-created)
  isFavorite: bool (user can mark as favorite)
  isSelected: bool (in user's active pool)
  createdAt: DateTime
}

// Reflection Answer (linked to Entry)
ReflectionAnswer {
  id: String (UUID)
  entryId: String (links to the mood Entry)
  questionId: String
  questionText: String (snapshot of question text at time of answer)
  answer: String
  createdAt: DateTime
}
```

## Default Questions (Elio Essentials)

Pre-populate these 5 questions for new users. All selected, none favorited:

```dart
[
  { text: "What are you grateful for today?", category: "gratitude" },
  { text: "What's one thing you're proud of today?", category: "pride" },
  { text: "What gave you energy today?", category: "energy" },
  { text: "What did you learn today?", category: "learning" },
  { text: "What are you looking forward to?", category: "tomorrow" },
]
```

## Full Question Library

Seed the database with these questions (isSelected: false by default, except Elio Essentials):

**Gratitude**
- What are you grateful for today?
- What good thing happened today?
- Who helped you today?

**Pride & Wins**
- What's one thing you're proud of today?
- What went well today?
- What small win did you have today?

**Learning & Growth**
- What did you learn today?
- What surprised you today?
- What insight did you gain today?

**Energy & Awareness**
- What gave you energy today?
- What drained your energy today?
- When did you feel your best today?

**Tomorrow & Forward**
- What are you looking forward to?
- What would you do differently tomorrow?
- What's your intention for tomorrow?

**Connection**
- Who made you smile today?
- Who would you like to thank today?
- Did you have a meaningful conversation today?

**Self-care**
- Did you do something for yourself today?
- How did you take care of yourself today?
- Did you allow yourself to rest today?

**Reflection**
- What would you do differently today?
- What frustrated you today?
- What lesson are you taking from today?

**Presence**
- What moment do you want to remember?
- When were you fully present today?
- What made today unique?

## Settings Screen for Reflection

```
┌─────────────────────────────────────┐
│ ← Settings                          │
├─────────────────────────────────────┤
│                                     │
│ Daily Reflection              [ON]  │  ← toggle
│                                     │
│ ─────────────────────────────────── │
│                                     │
│ FAVORITES (shown first)             │
│                                     │
│ Tap ⭐ on any question to pin it    │
│ (max 2 favorites)                   │
│                                     │
│ ─────────────────────────────────── │
│                                     │
│ YOUR QUESTIONS                      │
│                                     │
│ ⭐ What are you grateful for...  [−]│
│ ○ What's one thing you're pro... [−]│
│ ○ What gave you energy today?    [−]│
│ ○ What did you learn today?      [−]│
│ ○ What are you looking forwar... [−]│
│                                     │
│ ─────────────────────────────────── │
│                                     │
│ [+ Add from library]                │
│ [+ Write custom question]           │
│                                     │
└─────────────────────────────────────┘
```

### Add from Library Screen

```
┌─────────────────────────────────────┐
│ ← Question Library                  │
├─────────────────────────────────────┤
│                                     │
│ GRATITUDE                           │
│ ┌─────────────────────────────────┐ │
│ │ [✓] What are you grateful...    │ │
│ │ [ ] What good thing happened... │ │
│ │ [ ] Who helped you today?       │ │
│ └─────────────────────────────────┘ │
│                                     │
│ PRIDE & WINS                        │
│ ┌─────────────────────────────────┐ │
│ │ [✓] What's one thing you're...  │ │
│ │ [ ] What went well today?       │ │
│ │ [ ] What small win did you...   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ... more categories ...             │
│                                     │
│          [Done]                     │
│                                     │
└─────────────────────────────────────┘
```

### Write Custom Question Screen

```
┌─────────────────────────────────────┐
│ ← Add Custom Question               │
├─────────────────────────────────────┤
│                                     │
│ Your question                       │
│ ┌─────────────────────────────────┐ │
│ │ Did I work on my side project   │ │
│ │ today?                          │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Category                            │
│ ┌─────────────────────────────────┐ │
│ │ Learning & Growth           ▼  │ │
│ └─────────────────────────────────┘ │
│                                     │
│          [Add Question]             │
│                                     │
└─────────────────────────────────────┘
```

## Integration with Core Flow

### In Intention Screen
After user submits intention, check if Reflection is enabled:
- If enabled → navigate to Reflection Screen
- If disabled → navigate to Confirmation Screen

### In Reflection Screen
After completion (Continue pressed) → navigate to Confirmation Screen with:
- moodValue
- moodWord
- intention
- reflectionAnswers[] (array of answers from this session)

### In Confirmation Screen
- Save Entry with linked ReflectionAnswers
- Show summary including reflection answers (collapsed/brief)

## Rotation Logic

```dart
// Pseudocode for selecting today's question
getNextQuestion(List<ReflectionQuestion> pool, List<String> alreadyAnsweredToday) {
  // 1. Get favorites first (sorted by some order)
  favorites = pool.where(q => q.isFavorite && !alreadyAnsweredToday.contains(q.id))
  if (favorites.isNotEmpty) return favorites.first
  
  // 2. Get rotating questions
  rotating = pool.where(q => !q.isFavorite && q.isSelected && !alreadyAnsweredToday.contains(q.id))
  
  // 3. Pick based on day (deterministic rotation)
  dayOfYear = DateTime.now().dayOfYear
  index = dayOfYear % rotating.length
  return rotating[index]
}
```

## Design Rules

- Background: Warm Charcoal (#1C1C1E)
- Input field: Soft Graphite (#313134)
- Text: Soft Cream (#F9DFC1)
- Accent: Warm Orange (#FF6436)
- Previous answers: collapsed, checkmark, truncated text
- Animations: smooth fade transitions between questions
- "Skip for today": secondary text style, no negative connotation

## File Structure

```
lib/
├── models/
│   ├── reflection_question.dart
│   └── reflection_answer.dart
├── services/
│   └── reflection_service.dart
├── screens/
│   ├── reflection_screen.dart
│   ├── reflection_settings_screen.dart
│   ├── question_library_screen.dart
│   └── custom_question_screen.dart
└── widgets/
    ├── question_card.dart
    └── answered_question_chip.dart
```

## What Success Looks Like

1. User completes mood + intention
2. Sees one reflection question
3. Types brief answer
4. Can add more questions or continue
5. Skipping feels okay, not guilty
6. Answers are saved with the entry
7. Settings allow full customization
8. Favorites always appear first
9. Other questions rotate daily

---

# ✅ IMPLEMENTATION COMPLETED

## Implementation Summary

The Reflection Questions feature has been fully implemented and integrated into Elio's core mood tracking flow.

### Architecture

**State Management:** StatefulWidget + Service Layer (no Provider)
- Matches existing codebase pattern
- `ReflectionService` singleton for question management
- `StorageService` extended for reflection settings

**Storage:** Hive NoSQL Database
- `ReflectionQuestion` (typeId: 1) - Question library
- `ReflectionAnswer` (typeId: 2) - User answers linked to entries
- `Entry` updated with `reflectionAnswerIds` field

### Files Created

#### Models (3 files)
- `lib/models/reflection_question.dart` - Question model with Hive adapter
- `lib/models/reflection_answer.dart` - Answer model with Hive adapter
- `lib/models/entry.dart` - Updated to include reflectionAnswerIds

#### Services (2 files)
- `lib/services/reflection_service.dart` - Question management, rotation logic, answer saving
- `lib/services/storage_service.dart` - Added reflectionEnabled setting (default: true)

#### Screens (5 files)
- `lib/screens/reflection_screen.dart` - Main reflection flow (1-3 questions per check-in)
- `lib/screens/settings_screen.dart` - App settings hub (4th tab in navigation)
- `lib/screens/reflection_settings_screen.dart` - Manage questions and favorites
- `lib/screens/question_library_screen.dart` - Browse and select from 27 questions
- `lib/screens/custom_question_screen.dart` - Create custom questions
- `lib/screens/entry_detail_screen.dart` - View full entry with all reflection answers

#### Widgets (1 file)
- `lib/widgets/answered_question_chip.dart` - Collapsed answer display

### Integration Points

**Flow Integration:**
```
Mood Entry → Intention → [Reflection] → Confirmation → History
                             ↑
                   (if enabled in Settings)
```

**Navigation:**
- `lib/main.dart` - Initialize ReflectionService on app startup
- `lib/screens/intention_screen.dart` - Conditional routing to ReflectionScreen
- `lib/screens/confirmation_screen.dart` - Save and display reflection answers
- `lib/screens/home_shell.dart` - Settings added as 4th tab
- `lib/screens/history_screen.dart` - EntryCard tappable, opens detail screen
- `lib/widgets/entry_card.dart` - Made tappable with onTap callback

### Question Library

**27 Total Questions** across 9 categories:
- Gratitude (3)
- Pride & Wins (3)
- Learning & Growth (3)
- Energy & Awareness (3)
- Tomorrow & Forward (3)
- Connection (3)
- Self-care (3)
- Reflection (3)
- Presence (3)

**Elio Essentials (5 pre-selected):**
1. What are you grateful for today? (gratitude)
2. What's one thing you're proud of today? (pride)
3. What gave you energy today? (energy)
4. What did you learn today? (learning)
5. What are you looking forward to? (tomorrow)

### Key Features Implemented

1. **Question Rotation**
   - Favorites (max 2) always shown first
   - Remaining questions rotate daily based on day of year
   - Deterministic rotation ensures consistency

2. **Reflection Flow**
   - Start with 1 question
   - Answer up to 3 questions per check-in
   - "+ Another question" button (hidden after 3rd)
   - "Skip for today" option (no guilt)
   - Previous answers shown collapsed with checkmarks
   - Auto-save on Continue (even if not clicking "+ Another question")

3. **Settings Management**
   - Settings as dedicated tab (4th in bottom navigation)
   - Toggle reflection on/off
   - Manage question selection
   - Star up to 2 favorites
   - Add from library or create custom questions
   - Remove questions from pool

4. **Entry Detail View**
   - Tap any entry in History
   - See full mood, intention, and all reflection answers
   - Beautiful card-based layout
   - Question icons and formatted text

### Bug Fixes Applied

1. **ReflectionService initialization error**
   - Added error handling in ReflectionScreen
   - Fixed save flow in ConfirmationScreen (save entry first, then answers)

2. **Unsaved answer bug**
   - Fixed: Clicking "Continue" now saves current answer in text field
   - Continue button enabled when text exists OR answers exist

3. **Bottom navigation visibility**
   - Added bottomNavigationBarTheme to ElioTheme
   - Selected: Warm Orange (#FF6436)
   - Unselected: Soft Cream 50% opacity
   - Modern, compact design (22-24px icons)
   - Added shadow effect above navigation bar

### Design Consistency

All screens follow Elio's design system:
- **Background:** Warm Charcoal (#1C1C1E)
- **Surface:** Soft Graphite (#313134)
- **Text:** Soft Cream (#F9DFC1)
- **Accent:** Warm Orange (#FF6436)
- Rounded corners (18px border radius)
- Smooth animations and haptic feedback
- Clean typography and spacing

### Testing Notes

- All code compiles without errors
- Only deprecation warnings (withOpacity) which exist throughout codebase
- Requires full app restart (not hot reload) after clean build
- Question seeding happens automatically on first launch

### Future Enhancements (Not Implemented)

- Edit/delete existing reflection answers
- Search/filter questions in library
- Export reflection data
- Reflection insights/analytics
- Question scheduling (specific days/times)
- Rich text formatting for answers
