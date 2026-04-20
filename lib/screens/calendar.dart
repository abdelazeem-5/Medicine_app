import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicine_app/services/firebase_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<QueryDocumentSnapshot> _getMedicinesForDay(
      List<QueryDocumentSnapshot> docs, DateTime day) {

    return docs.where((doc) {
      final timestamp = doc['createdAt'] as Timestamp;
      final date = timestamp.toDate();

      return date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // 🔥 نفس لون التطبيق
      appBar: AppBar(
        title: const Text("Calendar"),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C7DA0), // ✅ اللون الأزرق
        foregroundColor: Colors.white, // ✅ النص أبيض
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService().getMedicines(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          final selectedDocs = _selectedDay == null
              ? []
              : _getMedicinesForDay(docs, _selectedDay!);

          return Column(
            children: [

              // 📅 Calendar
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,

                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },

                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
              ),

              const SizedBox(height: 20),

              // 💊 Medicines
              Expanded(
                child: _selectedDay == null
                    ? const Center(child: Text("Select a day"))
                    : selectedDocs.isEmpty
                        ? const Center(child: Text("No medicines"))
                        : ListView.builder(
                            itemCount: selectedDocs.length,
                            itemBuilder: (context, index) {
                              final data = selectedDocs[index];

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.medication),
                                  title: Text(data['name']),
                                  subtitle: Text(
                                      "${data['dosage']} • ${data['time']}"),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}