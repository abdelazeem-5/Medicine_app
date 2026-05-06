import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class SnoozeService {
  static const String _durationKey = 'snooze_duration';
  static const String _maxCountKey = 'snooze_max_count';

  static const int _defaultMinutes = 10;
  static const int _defaultMaxCount = 3;

  static Future<int> getDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_durationKey) ?? _defaultMinutes;
  }

  static Future<void> setDuration(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_durationKey, minutes);
  }


  static Future<int> getMaxCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxCountKey) ?? _defaultMaxCount;
  }

  static Future<void> setMaxCount(int count) async {
    if (count < 1) count = 1;
    if (count > 5) count = 5;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxCountKey, count);
  }


  static Future<int> getCurrentCount(int id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('snooze_count_$id') ?? 0;
  }

  static Future<void> incrementCount(int id) async {
    final prefs = await SharedPreferences.getInstance();

    int current = prefs.getInt('snooze_count_$id') ?? 0;

    await prefs.setInt(
      'snooze_count_$id',
      current + 1,
    );
  }

  static Future<void> resetCount(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('snooze_count_$id');
  }


  static Future<void> snoozeNotification({
    required FlutterLocalNotificationsPlugin notifications,
    required int id,
    required String title,
    required String body,
  }) async {
    final minutes = await getDuration();
    final maxCount = await getMaxCount();
    final currentCount = await getCurrentCount(id);

    if (currentCount >= maxCount) {
      print("🚫 Snooze limit reached ($maxCount)");
      return;
    }

    final tz.TZDateTime newTime =
        tz.TZDateTime.now(tz.local).add(
      Duration(minutes: minutes),
    );

    print(
      "⏳ Snoozing → after $minutes min (${currentCount + 1}/$maxCount)",
    );

    final androidDetails = AndroidNotificationDetails(
      'medicine_alarm',
      'Medicine Alarm',

      importance: Importance.max,
      priority: Priority.high,

      sound: RawResourceAndroidNotificationSound('alarm'),

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

    await notifications.zonedSchedule(
      id,
      title,
      body,
      newTime,
      NotificationDetails(
        android: androidDetails,
      ),
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    await incrementCount(id);

    print("✅ Snooze scheduled successfully");
  }
}