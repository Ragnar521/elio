import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const _dailyReminderId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    timezone_data.initializeTimeZones();
    await _setLocalTimezone();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(initializationSettings);
  }

  Future<void> _setLocalTimezone() async {
    if (kIsWeb) return;

    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));
    } catch (_) {
      // Keep the timezone package fallback rather than blocking app startup.
    }
  }

  Future<bool> requestPermissions() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    final iosResult = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    final macResult = await macos?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (iosResult != null) return iosResult;
    if (macResult != null) return macResult;
    return false;
  }

  Future<bool> enableDailyReminder({int hour = 20, int minute = 0}) async {
    final granted = await requestPermissions();
    if (!granted) {
      await cancelDailyReminder();
      return false;
    }

    await scheduleDailyReminder(hour: hour, minute: minute);
    return true;
  }

  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    await _plugin.cancel(_dailyReminderId);

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'A quiet check-in?',
      'Take a minute to notice how today felt.',
      _nextInstanceOfTime(hour: hour, minute: minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_check_in',
          'Daily Check-in',
          channelDescription: 'Gentle daily reminders to check in with Elio',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

  timezone.TZDateTime _nextInstanceOfTime({
    required int hour,
    required int minute,
  }) {
    final now = timezone.TZDateTime.now(timezone.local);
    var scheduled = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
