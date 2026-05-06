import 'package:share_plus/share_plus.dart';

class ShareService {

  static Future<void> shareReminder({
    required String medicineName,
    required String dosage,
    required String time,
  }) async {

    final text =
        "💊 Medicine Reminder\n\n"
        "Medicine: $medicineName\n"
        "Dosage: $dosage\n"
        "Time: $time";

    await Share.share(text);
  }
}