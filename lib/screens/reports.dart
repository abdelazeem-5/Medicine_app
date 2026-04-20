import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicine_app/services/firebase_service.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  DateTime parseTime(dynamic timeData) {
    try {
      return DateTime.parse(timeData);
    } catch (e) {
      final now = DateTime.now();

      final parts = timeData.split(" ");
      final timeParts = parts[0].split(":");

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      if (parts[1] == "PM" && hour != 12) hour += 12;
      if (parts[1] == "AM" && hour == 12) hour = 0;

      return DateTime(now.year, now.month, now.day, hour, minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
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

          int total = docs.length;
          int taken = 0;
          int missed = 0;
          int pending = 0;

          DateTime now = DateTime.now();

          for (var doc in docs) {
            DateTime time = parseTime(doc['time']); // ✅ FIX

            if (doc['taken'] == true) {
              taken++;
            } else if (time.isBefore(now)) {
              missed++;
            } else {
              pending++;
            }
          }

          double adherence = total == 0 ? 0 : taken / total;

          // 🔥 لون حسب الأداء
          Color progressColor;
          if (adherence >= 0.7) {
            progressColor = Colors.green;
          } else if (adherence >= 0.4) {
            progressColor = Colors.orange;
          } else {
            progressColor = Colors.red;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                // 📊 Adherence Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          "Adherence Rate",
                          style: TextStyle(fontSize: 18),
                        ),

                        const SizedBox(height: 20),

                        CircularProgressIndicator(
                          value: adherence,
                          strokeWidth: 8,
                          color: progressColor, // 🔥 متغير
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "${(adherence * 100).toStringAsFixed(1)}%", // 🔥 أدق
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 📈 Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Total",
                        total.toString(),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        "Taken",
                        taken.toString(),
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        "Missed",
                        missed.toString(),
                        Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Pending",
                        pending.toString(),
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 📊 Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Overall Progress",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),

                    LinearProgressIndicator(
                      value: adherence,
                      minHeight: 10,
                      color: progressColor, // 🔥 نفس اللون
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}