import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:medicine_app/services/snooze_service.dart';


class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'medicine_channel';

  // 🔥 INIT
  static Future<void> init() async {
    if (kIsWeb) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidInit);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        final actionId = response.actionId;
        final int id = response.id ?? -1;

        print("📩 Action: $actionId | ID: $id");

        if (id == -1) return;

        if (actionId == 'taken') {
          print("✅ Taken clicked");
          await SnoozeService.resetCount(id);
        }

        if (actionId == 'skip') {
          print("❌ Skipped");
          await SnoozeService.resetCount(id);
        }

        if (actionId == 'snooze') {
          final current = await SnoozeService.getCurrentCount(id);
          final max = await SnoozeService.getMaxCount();

          if (current >= max) {
            print("🚫 Snooze limit reached ($max)");
            return;
          }

          print("⏳ Snoozing... (${current + 1}/$max)");

          await SnoozeService.snoozeNotification(
            notifications: _notifications,
            id: id,
            title: "Snoozed Reminder ⏰",
            body: "Take your medicine",
          );
        }

        if (actionId == null) {
          print("📱 Notification tapped");
        }
      },
    );

    // ✅ Notification Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      'Medicine Reminder',
      description: 'Reminders for taking medicine on time',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(channel);
  }

  // 🔥 PERMISSION
  static Future<void> requestPermission() async {
    if (kIsWeb) return;

    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();

    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
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

  // 🎵 ringtone + actions
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
      enableVibration: true,
      enableLights: true,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,

      // ✅🔥 التعديل هنا
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'taken',
          'Taken ✅',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'skip',
          'Skip ❌',
          showsUserInterface: true, // 🔥 FIX
        ),
        AndroidNotificationAction(
          'snooze',
          'Snooze ⏳',
          showsUserInterface: true, // 🔥 FIX
        ),
      ],
    );
  }

  // 🔔 SCHEDULE DAILY
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String ringtone = 'alarm',
  }) async {
    if (kIsWeb) return;

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

    print("⏰ Daily Scheduling → $scheduledDate");

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: _buildAndroidDetails(ringtone),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // 📅 SCHEDULE WEEKLY
  static Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int weekday,
    String ringtone = 'alarm',
  }) async {
    if (kIsWeb) return;

    final now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != weekday ||
        scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print("📅 Weekly Scheduling → $scheduledDate");

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: _buildAndroidDetails(ringtone),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
}