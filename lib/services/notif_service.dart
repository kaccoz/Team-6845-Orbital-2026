import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {},
    );
  }

  Future<void> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> scheduleProgressiveReminders() async {
    await cancelAll();

    final hours = [7, 10, 13, 17, 20, 23];
    final titles = ["Good morning!", "Morning Nudge", "Afternoon Check", "Evening Reminder", "Night Reminder", "Final Chance"];
    final bodies = [
      "Ready to start the day?",
      "Time to log your habits!",
      "Don't forget to check in on your habits!",
      "Remember to keep your streak alive!",
      "Don't break your streak! You can do it!",
      "This is your last reminder for today!",
    ];

    for (int i = 0; i < hours.length; i++) {
      await _notificationsPlugin.zonedSchedule(
        id: i,
        title: titles[i],
        body: bodies[i],
        scheduledDate: _nextInstanceOf(hours[i]),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders_id', 
            'Daily Reminders', 
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
      );
    }
  }

  tz.TZDateTime _nextInstanceOf(int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> scheduleInstant10SecTest() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(const Duration(seconds: 10));

    await _notificationsPlugin.zonedSchedule(
      id: 999,
      title: '10-Second Test! 🎉',
      body: 'If you see this, your timezone and scheduling pipeline are 100% correct.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_id',
          'Test Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}