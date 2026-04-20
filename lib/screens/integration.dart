import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicine_app/services/firebase_service.dart';

class IntegrationPage extends StatefulWidget {
  const IntegrationPage({super.key});

  @override
  State<IntegrationPage> createState() => _IntegrationPageState();
}

class _IntegrationPageState extends State<IntegrationPage> {

  bool isConnected = false;

  int steps = 5230;
  int calories = 320;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadIntegration();
  }

  // 🔥 تحميل الحالة
  Future<void> _loadIntegration() async {
    final userId = FirebaseService().currentUser?.uid;
    if (userId == null) return;

    final doc = await _db.collection('integration').doc(userId).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        isConnected = data['connected'] ?? false;
      });
    }
  }

  // 🔥 حفظ الحالة
  Future<void> _toggleConnection() async {
    final userId = FirebaseService().currentUser?.uid;
    if (userId == null) return;

    setState(() {
      isConnected = !isConnected;
    });

    await _db.collection('integration').doc(userId).set({
      'connected': isConnected,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isConnected
              ? "Connected to Google Fit ✅"
              : "Disconnected ❌",
        ),
        backgroundColor: isConnected ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Integration"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔗 Connection
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text("Google Fit"),
                subtitle: Text(
                  isConnected ? "Connected" : "Not Connected",
                ),
                trailing: Switch(
                  value: isConnected,
                  onChanged: (value) {
                    _toggleConnection();
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 📊 Data
            if (isConnected) ...[

              _buildDataCard(
                "Steps Today",
                steps.toString(),
                Icons.directions_walk,
                Colors.blue,
              ),

              const SizedBox(height: 15),

              _buildDataCard(
                "Calories Burned",
                calories.toString(),
                Icons.local_fire_department,
                Colors.orange,
              ),
            ]
            else
              const Expanded(
                child: Center(
                  child: Text(
                    "Connect to Google Fit to see data",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}