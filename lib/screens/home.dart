import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medicine_app/screens/add_medicine.dart';
import 'package:medicine_app/services/firebase_service.dart';
import 'package:medicine_app/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    _refreshUser();
  }

  Future<void> _refreshUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() {});
  }

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

  Future<String?> _getProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_image');
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    String userName =
        (user.displayName != null && user.displayName!.isNotEmpty)
            ? user.displayName!
            : "User";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      // ✅ Drawer
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2C7DA0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<String?>(
                    future: _getProfileImage(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return CircleAvatar(
                          radius: 30,
                          backgroundImage: FileImage(File(snapshot.data!)),
                        );
                      }
                      return const CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.person),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(userName,
                      style: const TextStyle(color: Colors.white)),
                  Text(user.email ?? "",
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text("Calendar"),
              onTap: () => Navigator.pushNamed(context, '/calendar'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text("Reports"),
              onTap: () => Navigator.pushNamed(context, '/reports'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text("History"),
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text("Notifications"),
              onTap: () => Navigator.pushNamed(context, '/notifications'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Edit Profile"),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        title: const Text("Medicine Reminder",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C7DA0),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService().getMedicines(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final now = DateTime.now();

          int takenCount =
              docs.where((doc) => doc['taken'] == true).length;

          int pendingCount = docs.where((doc) {
            DateTime time = parseTime(doc['time']);
            return doc['taken'] == false && time.isAfter(now);
          }).length;

          int missedCount = docs.where((doc) {
            DateTime time = parseTime(doc['time']);
            return doc['taken'] == false && time.isBefore(now);
          }).length;

          return SingleChildScrollView(
            child: Column(
              children: [

                const SizedBox(height: 20),

                _buildWelcomeCard(userName),

                const SizedBox(height: 20),

                // ✅ Summary بدل Stats
                _buildSummaryCard(takenCount, pendingCount, missedCount),

                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "💊 Today's Medicines",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                docs.isEmpty
                    ? Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.medication,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("No medicines yet"),
                            SizedBox(height: 5),
                            Text("Tap + to add"),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final docId = doc.id;

                          DateTime medicineTime =
                              parseTime(data['time']);

                          bool isTaken = data['taken'] == true;
                          bool isMissed =
                              !isTaken && medicineTime.isBefore(now);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isTaken
                                ? Colors.green[50]
                                : isMissed
                                    ? Colors.red[50]
                                    : Colors.white,
                            child: ListTile(
                              leading: const Icon(Icons.medication),
                              title: Text(data['name'] ?? ""),
                              subtitle: Text(
                                "${data['dosage']} • ${TimeOfDay.fromDateTime(medicineTime).format(context)}",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  IconButton(
                                    icon: Icon(
                                      isTaken
                                          ? Icons.check_circle
                                          : Icons.check_circle_outline,
                                      color: isTaken
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    onPressed: () {
                                      FirebaseService()
                                          .updateMedicineStatus(
                                              docId, !isTaken);
                                    },
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddMedicinePage(
                                            medicineId: docId,
                                            initialName: data['name'],
                                            initialDosage: data['dosage'],
                                            initialTime:
                                                parseTime(data['time']),
                                            notificationId:
                                                data['notificationId'],
                                            initialRingtone:
                                                data['ringtone'] ?? 'alarm',
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      final int? notificationId =
                                          data['notificationId'];

                                      if (notificationId != null) {
                                        await NotificationService
                                            .cancelNotification(
                                                notificationId);
                                      }

                                      await FirebaseService()
                                          .deleteMedicine(docId);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add'),
        backgroundColor: const Color(0xFF2C7DA0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWelcomeCard(String userName) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF2C7DA0), Color(0xFF3A9BC5)],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Ready to stay healthy",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,        // 👈 الاسم أكبر بكتير
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.medication, color: Colors.white, size: 40),
      ],
    ),
  );
}

  Widget _buildSummaryCard(int taken, int pending, int missed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _miniStat("Taken", taken, Colors.green),
          // _miniStat("Pending", pending, Colors.orange),
          _miniStat("Missed", missed, Colors.red),
        ],
      ),
    );
  }

  Widget _miniStat(String title, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}