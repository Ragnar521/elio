# Technology Stack

**Analysis Date:** 2026-02-26

## Languages

**Primary:**
- Dart 3.10.8 - Application code, Flutter framework language

**Secondary:**
- Kotlin - Android platform integration (`android/app/build.gradle.kts`)
- Swift/Objective-C - iOS platform integration (via CocoaPods)

## Runtime

**Environment:**
- Flutter 3.38.9 (stable channel)
- Dart SDK 3.10.8

**Package Manager:**
- pub (Flutter/Dart package manager)
- Lockfile: `pubspec.lock` present (tracks exact dependency versions)

**Platform-Specific:**
- Gradle (Android builds) - Gradle 8.x with Kotlin DSL
- CocoaPods (iOS dependencies) - `Podfile.lock` present

## Frameworks

**Core:**
- Flutter SDK 3.38.9 - Cross-platform UI framework
- Material Design - UI components (`uses-material-design: true`)
- Cupertino (iOS-style widgets) - Via cupertino_icons ^1.0.8

**Testing:**
- flutter_test (SDK) - Official Flutter testing framework
- flutter_lints ^6.0.0 - Recommended linting rules

**Build/Dev:**
- flutter_launcher_icons ^0.14.2 - Generates app icons for iOS and Android
- Kotlin 17 (Android) - JVM target for Android builds
- Xcode build tools (iOS) - Managed via Flutter toolchain

## Key Dependencies

**Critical:**
- hive ^2.2.3 - NoSQL local database, all app data storage
- hive_flutter ^1.1.0 - Flutter integration for Hive, provides path initialization
- uuid ^4.5.1 - Generates unique IDs for entries, questions, answers, directions
- flutter_local_notifications ^17.2.4 - Local notification system (reminder feature)

**Infrastructure:**
- path_provider ^2.1.5 (transitive) - Access to device storage directories for Hive
- timezone ^0.9.4 (transitive) - Timezone support for notifications
- ffi ^2.1.5 (transitive) - Native code interop for Hive storage

**Platform Integration:**
- flutter_local_notifications_platform_interface ^7.2.0 - Cross-platform notifications API
- dbus ^0.7.12 (Linux notifications support)
- Various path_provider platform implementations (Android, iOS, Linux, Windows, macOS)

**Tooling:**
- image ^4.7.2 (transitive) - Icon generation processing
- archive ^4.0.7 (transitive) - Icon packaging

## Configuration

**Environment:**
- No external environment variables required
- All data stored locally via Hive (device filesystem)
- Settings managed in Hive box: `settings` (key-value pairs)

**Build:**
- `pubspec.yaml` - Dependency management, Flutter configuration, app metadata
- `analysis_options.yaml` - Static analysis configuration, includes flutter_lints
- `android/app/build.gradle.kts` - Android build configuration (Kotlin DSL)
- `android/gradle.properties` - Gradle settings
- `android/local.properties` - Local Android SDK path
- `ios/Podfile` - iOS native dependencies
- `ios/Runner/Info.plist` - iOS app configuration
- No custom build_runner configuration (Hive adapters written manually)

**Version:**
- App version: 1.0.0+1 (defined in `pubspec.yaml`)
- Version name: 1.0.0
- Build number: 1

## Platform Requirements

**Development:**
- Flutter SDK 3.10.8 or higher
- Dart SDK 3.10.8 or higher
- Android Studio / Xcode (for platform builds)
- iOS: Xcode with iOS 13.0+ SDK support
- Android: API level configured via flutter.minSdkVersion (typically 21+)

**Production:**
- iOS: iPhone/iPad running iOS 13.0+
- Android: Devices running API level 21+ (Android 5.0 Lollipop)
- Local device storage required for Hive database

**Platform Targets:**
- iOS (primary) - via `ios/` directory
- Android (primary) - via `android/` directory
- macOS (supported) - via `macos/` directory (has Podfile)

---

*Stack analysis: 2026-02-26*
