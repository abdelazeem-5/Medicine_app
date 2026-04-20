import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicine_app/services/firebase_service.dart';
import 'package:medicine_app/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {

  bool isEnabled = true;
  bool _isSaving = false;

  Future<List<QueryDocumentSnapshot>> _getAllMedicines() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('medicines')
        .get();

    return snapshot.docs;
  }

  Future<void> _saveSettings(bool enabled) async {
    setState(() => _isSaving = true);

    try {
      final userId = FirebaseService().currentUser?.uid;
      if (userId == null) return;

      if (!enabled) {
        await NotificationService.cancelAllNotifications();
      } else {
        final medicines = await _getAllMedicines();

        for (final med in medicines) {
          try {
            final int? notificationId = med['notificationId'];
            final String? timeStr = med['time'];

            if (notificationId == null || timeStr == null) continue;

            final DateTime time = DateTime.parse(timeStr);

            final String ringtone =
                med.data().toString().contains('ringtone')
                    ? med['ringtone']
                    : 'alarm';

            await NotificationService.scheduleDailyNotification(
              id: notificationId,
              title: 'Medicine Reminder 💊',
              body: "${med['name']} - ${med['dosage']}",
              hour: time.hour,
              minute: time.minute,
              ringtone: ringtone,
            );
          } catch (_) {}
        }
      }

      await FirebaseFirestore.instance
          .collection('settings')
          .doc(userId)
          .set({'enabled': enabled});

      setState(() => isEnabled = enabled);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFF2C7DA0),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔥 Title
            const Text(
              "Notifications & Reminders",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Enable or disable daily medicine reminders.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // 🔥 Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [

                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: isEnabled ? Colors.green : Colors.grey,
                    ),
                  ),

                  const SizedBox(width: 15),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Medicine Reminders",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEnabled
                              ? "Notifications are ON"
                              : "Notifications are OFF",
                          style: TextStyle(
                            color: isEnabled
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Switch
                  Switch(
                    value: isEnabled,
                    onChanged: _isSaving ? null : _saveSettings,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 Loading
            if (_isSaving)
              const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 20),

            // 🔥 Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Make sure notifications are allowed in your device settings.",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}