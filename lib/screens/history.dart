import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicine_app/services/firebase_service.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // 🔥 format time
  String _formatTime(String timeStr, BuildContext context) {
    try {
      final dateTime = DateTime.parse(timeStr);
      final time = TimeOfDay.fromDateTime(dateTime);
      return time.format(context);
    } catch (e) {
      return timeStr;
    }
  }

  // 🔥 format date (2026-04-21)
  String _formatDate(String timeStr) {
    try {
      final date = DateTime.parse(timeStr);
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return timeStr;
    }
  }

  // 🔥 Today / Yesterday
  String _getDayLabel(String timeStr) {
    try {
      final date = DateTime.parse(timeStr);
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      final target = DateTime(date.year, date.month, date.day);

      if (target == today) return "Today";
      if (target == yesterday) return "Yesterday";

      return "";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("History"),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C7DA0),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService().getMedicines(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          final takenDocs =
              docs.where((doc) => doc['taken'] == true).toList();

          if (takenDocs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No history yet", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 5),
                  Text(
                    "Take your medicines to see history",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: takenDocs.length,
            itemBuilder: (context, index) {
              final data = takenDocs[index];

              final date = _formatDate(data['time']);
              final time = _formatTime(data['time'], context);
              final label = _getDayLabel(data['time']);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [

                      // icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.check, color: Colors.green),
                      ),

                      const SizedBox(width: 15),

                      // content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              data['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // 🔥 التاريخ
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // 🔥 الوقت + Today
                            Text(
                              label.isNotEmpty
                                  ? "$time • $label"
                                  : time,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // delete
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          FirebaseService().deleteMedicine(data.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}