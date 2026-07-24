import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  final GeofenceService _geofenceService = GeofenceService.instance.setup(
    interval: 5000,
    accuracy: 100,
    loiteringDelayMs: 60000,
    statusChangeDelayMs: 10000,
    useActivityRecognition: false,
    allowMockLocations: true,
  );

  bool _isGeofenceListenerAdded = false;

  Future<void> init() async {
    tz.initializeTimeZones();

    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final dynamic tzInfoDynamic = timeZoneInfo;
      final timeZoneName = tzInfoDynamic is String
          ? tzInfoDynamic
          : tzInfoDynamic.name ??
              tzInfoDynamic.timeZoneName ??
              tzInfoDynamic.location ??
              tzInfoDynamic.identifier ??
              tzInfoDynamic.toString();

      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Singapore'));
    }

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
    await androidImplementation?.requestExactAlarmsPermission();
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
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

  Future<void> syncHabitGeofences(List<QueryDocumentSnapshot<Map<String, dynamic>>> habitDocs) async {
    List<Geofence> geofences = [];

    for (var doc in habitDocs) {
      final data = doc.data();
      if (data['isLocationBased'] == true &&
          data['latitude'] != null &&
          data['longitude'] != null) {
        geofences.add(
          Geofence(
            id: data['title'] ?? 'Habit Reminder',
            latitude: (data['latitude'] as num).toDouble(),
            longitude: (data['longitude'] as num).toDouble(),
            radius: [GeofenceRadius(id: 'radius_${doc.id}', length: 100)],
          ),
        );
      }
    }

    if (geofences.isNotEmpty) {
      if (!_isGeofenceListenerAdded) {
        _geofenceService.addGeofenceStatusChangeListener((geofence, geofenceRadius, geofenceStatus, location) async {
          if (geofenceStatus == GeofenceStatus.ENTER) {
            await _showInstantLocationNotification(
              title: "You've arrived! 📍",
              body: "Time to complete your habit: ${geofence.id}!",
            );
          }
        });
        _isGeofenceListenerAdded = true;
      }
      await _geofenceService.start(geofences);
    }
  }

  Future<void> _showInstantLocationNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'location_channel_id',
      'Location Reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notificationsPlugin.show(
      id: 888,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
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