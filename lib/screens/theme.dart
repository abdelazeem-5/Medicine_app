import 'package:flutter/material.dart';

class ThemeScreen extends StatelessWidget {
  final Function(ThemeMode) onChange;

  const ThemeScreen({super.key, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Theme")),
      body: Column(
        children: [
          ListTile(
            title: const Text("Light Mode"),
            onTap: () => onChange(ThemeMode.light),
          ),
          ListTile(
            title: const Text("Dark Mode"),
            onTap: () => onChange(ThemeMode.dark),
          ),
          ListTile(
            title: const Text("System Default"),
            onTap: () => onChange(ThemeMode.system),
          ),
        ],
      ),
    );
  }
}