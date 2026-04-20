import 'package:flutter/foundation.dart'; // 🔥 مهم للـ Web
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'medicine_channel';

  // 🔥 INIT
  static Future<void> init() async {
    if (kIsWeb) return; // ❌ تجاهل على الويب

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidInit);

    await _notifications.initialize(settings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      'Medicine Reminder',
      description: 'Reminders',
      importance: Importance.max,
      playSound: true,
    );

    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(channel);
  }

  // 🔥 PERMISSION
  static Future<void> requestPermission() async {
    if (kIsWeb) return; // ❌ تجاهل على الويب

    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  // 🔥 CANCEL
  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  // 🎵 ringtone mapping
  static AndroidNotificationDetails _buildAndroidDetails(String ringtone) {
    final soundMap = {
      'alarm': 'alarm',
      'bell': 'bell',
      'soft': 'soft',
    };

    final soundFile = soundMap[ringtone] ?? 'alarm';

    return AndroidNotificationDetails(
      channelId,
      'Medicine Reminder',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(soundFile),
      playSound: true,
    );
  }

  // 🔔 SCHEDULE
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String ringtone = 'alarm',
  }) async {
    if (kIsWeb) {
      print("⚠️ Notifications disabled on Web");
      return;
    }

    final now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print("Scheduling notification at: $scheduledDate with ringtone: $ringtone");

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: _buildAndroidDetails(ringtone),
      ),
      androidAllowWhileIdle: true,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}