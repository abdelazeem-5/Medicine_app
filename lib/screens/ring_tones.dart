import 'package:flutter/material.dart';

class RingTonesPage extends StatefulWidget {
  const RingTonesPage({super.key});

  @override
  State<RingTonesPage> createState() => _RingTonesPageState();
}

class _RingTonesPageState extends State<RingTonesPage> {
  String selectedTone = "Default";

  // 🧪 قائمة نغمات تجريبية
  final List<String> tones = [
    "Default",
    "Beep",
    "Alarm",
    "Soft Tone",
    "Classic Ring",
  ];

  void _selectTone(String tone) {
    setState(() {
      selectedTone = tone;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Selected: $tone"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveTone() {
    Navigator.pop(context, selectedTone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ring Tones"),
        centerTitle: true,
      ),

      body: Column(
        children: [

          const SizedBox(height: 10),

          // 🔔 List of tones
          Expanded(
            child: ListView.builder(
              itemCount: tones.length,
              itemBuilder: (context, index) {
                final tone = tones[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),

                  child: ListTile(
                    leading: const Icon(Icons.music_note),
                    title: Text(tone),

                    trailing: selectedTone == tone
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,

                    onTap: () => _selectTone(tone),
                  ),
                );
              },
            ),
          ),

          // 💾 Save Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTone,
                child: const Text("Save"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ring_tones.dart