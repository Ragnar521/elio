# External Integrations

**Analysis Date:** 2026-02-26

## APIs & External Services

**None:**
- No external APIs or cloud services integrated
- Fully offline, local-first architecture
- No network requests in codebase

## Data Storage

**Databases:**
- Hive (NoSQL, local-only)
  - Connection: Local filesystem via `path_provider`
  - Client: `hive_flutter ^1.1.0` (official Hive Flutter adapter)
  - Location: `lib/services/storage_service.dart`, `lib/services/reflection_service.dart`, `lib/services/direction_service.dart`
  - Boxes:
    - `entries` - Mood entries (Entry model, typeId: 0)
    - `settings` - App settings as key-value pairs
    - `reflectionQuestions` - Question library (ReflectionQuestion, typeId: 1)
    - `reflectionAnswers` - User answers (ReflectionAnswer, typeId: 2)
    - `directions` - Life directions (Direction, typeId: 5)
    - `direction_connections` - Entry-to-direction links (DirectionConnection, typeId: 6)
    - `direction_check_ins` - Per-entry direction presence/progress/blocker records (DirectionCheckIn, typeId: 8)

**File Storage:**
- Local filesystem only
- App icon asset: `images/appicon.png`
- No user file uploads or cloud storage

**Caching:**
- None (Hive provides persistent local storage)

## Authentication & Identity

**Auth Provider:**
- None
  - Implementation: No authentication system, single-user local app
  - User identification: User name stored locally in settings (`user_name` key)

## Monitoring & Observability

**Error Tracking:**
- None (no Sentry, Crashlytics, or similar services)

**Logs:**
- Debug logs via Flutter's `debugPrint` (development only)
- No production logging infrastructure

## CI/CD & Deployment

**Hosting:**
- Not applicable (native mobile app)
- Distributed via:
  - iOS: App Store (future)
  - Android: Google Play Store (future)

**CI Pipeline:**
- None detected (no GitHub Actions, CircleCI, or similar configs)
- No automated testing or deployment workflows

## Environment Configuration

**Required env vars:**
- None (no `.env` files, no external service credentials)

**Secrets location:**
- Not applicable (no secrets required)

**Settings storage:**
- Hive `settings` box stores local configuration:
  - `user_name`
  - `onboarding_completed`
  - `notifications_enabled`
  - `reflection_enabled`
  - `longest_streak`

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## Local Notifications

**Service:**
- flutter_local_notifications ^17.2.4
  - Platform: Local device notifications (not push notifications)
  - Implementation: `lib/services/notification_service.dart`
  - Permissions: iOS/macOS request alert, badge, sound permissions
  - Android icon: `@mipmap/ic_launcher`
  - Status: Initialized but not actively used (future reminder feature)

**Platform Support:**
- iOS: DarwinInitializationSettings
- Android: AndroidInitializationSettings
- macOS: DarwinInitializationSettings
- Linux: flutter_local_notifications_linux ^4.0.1

## Third-Party SDKs

**UUID Generation:**
- uuid ^4.5.1
  - Purpose: Generate unique IDs for all database records
  - Usage: `StorageService`, `ReflectionService`, `DirectionService`
  - Pattern: UUIDv4 via `Uuid().v4()`

## Data Privacy

**Privacy Model:**
- 100% local storage (no data leaves device)
- No analytics or telemetry
- No user tracking
- No network connectivity required
- Privacy-first design principle documented in `.claude/CLAUDE.md`

---

*Integration audit: 2026-02-26*
