import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicine_app/services/firebase_service.dart';
import 'package:medicine_app/services/notification_service.dart';
import 'package:medicine_app/services/snooze_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  bool isEnabled = true;
  bool _isSaving = false;

  int snoozeDuration = 10;
  int snoozeCount = 3;

  @override
  void initState() {
    super.initState();
    _loadSnooze();
  }

  Future<void> _loadSnooze() async {
    snoozeDuration = await SnoozeService.getDuration();
    snoozeCount = await SnoozeService.getMaxCount();
    setState(() {});
  }

  Future<List<QueryDocumentSnapshot>> _getAllMedicines() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('medicines').get();
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

            await NotificationService.scheduleDailyNotification(
              id: notificationId,
              title: 'Medicine Reminder 💊',
              body: "${med['name']} - ${med['dosage']}",
              hour: time.hour,
              minute: time.minute,
              ringtone: med['ringtone'] ?? 'alarm',
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: const Color(0xFF2C7DA0),
        foregroundColor: Colors.white,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          const Text(
            "Notifications",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications),
                const SizedBox(width: 10),

                const Expanded(
                  child: Text("Enable Notifications"),
                ),

                Switch(
                  value: isEnabled,
                  onChanged: _isSaving ? null : _saveSettings,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "Snooze Duration",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          DropdownButton<int>(
            value: snoozeDuration,
            items: [5, 10, 15, 30]
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text("$e minutes"),
                    ))
                .toList(),
            onChanged: (v) async {
              await SnoozeService.setDuration(v!);
              setState(() => snoozeDuration = v);
            },
          ),

          const SizedBox(height: 20),

          const Text(
            "Max Snooze Count",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          DropdownButton<int>(
            value: snoozeCount,
            items: [1, 2, 3, 4, 5]
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text("$e times"),
                    ))
                .toList(),
            onChanged: (v) async {
              await SnoozeService.setMaxCount(v!);
              setState(() => snoozeCount = v);
            },
          ),

          const SizedBox(height: 30),

          if (_isSaving)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}