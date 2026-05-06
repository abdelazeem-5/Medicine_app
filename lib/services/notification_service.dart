import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:medicine_app/services/snooze_service.dart';
import 'package:medicine_app/services/firebase_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'medicine_channel_3';

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
          await FirebaseService().markAsTakenByNotification(id);
          await SnoozeService.resetCount(id);
        }

        if (actionId == 'snooze') {
          await SnoozeService.snoozeNotification(
            notifications: _notifications,
            id: id,
            title: "Snoozed Reminder ⏰",
            body: "Take your medicine",
          );
        }
      },
    );

    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final channels = [
      AndroidNotificationChannel(
        'medicine_alarm',
        'Medicine Alarm',
        description: 'Alarm ringtone notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarm'),
      ),
      AndroidNotificationChannel(
        'medicine_bell',
        'Medicine Bell',
        description: 'Bell ringtone notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('bell'),
      ),
      AndroidNotificationChannel(
        'medicine_soft',
        'Medicine Soft',
        description: 'Soft ringtone notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('soft'),
      ),
      AndroidNotificationChannel(
        'medicine_tone',
        'Medicine Tone',
        description: 'Tone ringtone notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('tone'),
      ),
      AndroidNotificationChannel(
        'medicine_tonee',
        'Medicine Tonee',
        description: 'Tonee ringtone notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('tonee'),
      ),
    ];

    for (final channel in channels) {
      await android?.createNotificationChannel(channel);
    }
  }

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

  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  static AndroidNotificationDetails _buildAndroidDetails(String ringtone) {
    final soundMap = {
      'alarm': 'alarm',
      'bell': 'bell',
      'soft': 'soft',
      'tone': 'tone',
      'tonee': 'tonee',
    };

    final soundFile = soundMap[ringtone] ?? 'alarm';

    return AndroidNotificationDetails(
      'medicine_$ringtone',
      'Medicine Reminder $ringtone',

      importance: Importance.max,
      priority: Priority.high,

      sound: RawResourceAndroidNotificationSound(soundFile),

      playSound: true,
      enableVibration: true,
      enableLights: true,

      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,

      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'taken',
          'Taken ✅',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'snooze',
          'Snooze ⏳',
          showsUserInterface: true,
        ),
      ],
    );
  }

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