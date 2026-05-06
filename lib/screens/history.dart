import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicine_app/services/firebase_service.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  String _formatTime(String timeStr, BuildContext context) {
    try {
      final dateTime = DateTime.parse(timeStr);
      final time = TimeOfDay.fromDateTime(dateTime);
      return time.format(context);
    } catch (e) {
      return timeStr;
    }
  }

  String _formatDate(String timeStr) {
    try {
      final date = DateTime.parse(timeStr);
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return timeStr;
    }
  }

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history,
                      size: 60,
                      color: theme.iconTheme.color?.withOpacity(0.4)),
                  const SizedBox(height: 10),
                  Text(
                    "No history yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Take your medicines to see history",
                    style: TextStyle(color: theme.hintColor),
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
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.check, color: Colors.green),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              data['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.hintColor,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              label.isNotEmpty
                                  ? "$time • $label"
                                  : time,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),

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