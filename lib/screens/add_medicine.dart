import 'package:flutter/material.dart';
import 'package:medicine_app/services/firebase_service.dart';
import 'package:medicine_app/services/notification_service.dart';

class AddMedicinePage extends StatefulWidget {
  final String? medicineId;
  final String? initialName;
  final String? initialDosage;
  final DateTime? initialTime;
  final int? notificationId;
  final String? initialRingtone;

  const AddMedicinePage({
    super.key,
    this.medicineId,
    this.initialName,
    this.initialDosage,
    this.initialTime,
    this.notificationId,
    this.initialRingtone,
  });

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  TimeOfDay? selectedTime;
  bool _isSaving = false;

  String selectedRingtone = 'alarm';
  String frequency = "Daily";

  final List<String> allDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  List<String> selectedDays = [];

  @override
  void initState() {
    super.initState();

    if (widget.initialName != null) {
      nameController.text = widget.initialName!;
      dosageController.text = widget.initialDosage ?? "";

      if (widget.initialTime != null) {
        selectedTime = TimeOfDay.fromDateTime(widget.initialTime!);
      }

      selectedRingtone = widget.initialRingtone ?? 'alarm';
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() => selectedTime = time);
    }
  }

  Future<void> _saveMedicine() async {
    if (_isSaving) return;

    if (_formKey.currentState!.validate() && selectedTime != null) {
      setState(() => _isSaving = true);

      try {
        final now = DateTime.now();

        DateTime scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          selectedTime!.hour,
          selectedTime!.minute,
        );

        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        final int notificationId =
            widget.notificationId ??
            DateTime.now().millisecondsSinceEpoch ~/ 1000;

        await NotificationService.cancelNotification(notificationId);

        if (widget.medicineId == null) {
          await FirebaseService().addMedicine(
            name: nameController.text.trim(),
            dosage: dosageController.text.trim(),
            time: scheduledTime.toIso8601String(),
            notificationId: notificationId,
            ringtone: selectedRingtone,
          );
        } else {
          await FirebaseService().updateMedicine(
            id: widget.medicineId!,
            name: nameController.text.trim(),
            dosage: dosageController.text.trim(),
            time: scheduledTime.toIso8601String(),
            notificationId: notificationId,
            ringtone: selectedRingtone,
          );
        }

        await NotificationService.scheduleDailyNotification(
          id: notificationId,
          title: "Medicine Reminder 💊",
          body:
              "${nameController.text.trim()} - ${dosageController.text.trim()}",
          hour: selectedTime!.hour,
          minute: selectedTime!.minute,
          ringtone: selectedRingtone,
        );

        if (!mounted) return;
        Navigator.pop(context);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }

      setState(() => _isSaving = false);
    }
  }

  Widget _buildDaysSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allDays.map((day) {
        final isSelected = selectedDays.contains(day);

        return ChoiceChip(
          label: Text(day),
          selected: isSelected,
          selectedColor: const Color(0xFF2C7DA0),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
          onSelected: (_) {
            setState(() {
              isSelected
                  ? selectedDays.remove(day)
                  : selectedDays.add(day);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.medicineId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: Text(isEdit ? "Edit Medicine" : "Add Medicine"),
        backgroundColor: const Color(0xFF2C7DA0),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              _buildCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Medicine Name",
                      ),
                      validator: (v) => v!.isEmpty ? "Enter name" : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                        labelText: "Quantity",
                      ),
                      validator: (v) => v!.isEmpty ? "Enter Quantity" : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildCard(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text("Reminder Time"),
                  subtitle: Text(
                    selectedTime == null
                        ? "Select time"
                        : selectedTime!.format(context),
                  ),
                  onTap: _pickTime,
                ),
              ),

              const SizedBox(height: 20),

              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Frequency"),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: frequency,
                      items: const [
                        DropdownMenuItem(value: "Daily", child: Text("Daily")),
                        DropdownMenuItem(
                            value: "Specific Days",
                            child: Text("Specific Days")),
                      ],
                      onChanged: (v) => setState(() => frequency = v!),
                    ),

                    const SizedBox(height: 15),

                    if (frequency == "Specific Days") _buildDaysSelector(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildCard(
                child: DropdownButtonFormField<String>(
                  value: selectedRingtone,
                  decoration: const InputDecoration(labelText: "Ringtone"),
                  items: const [
                    DropdownMenuItem(value: 'alarm', child: Text("Alarm")),
                    DropdownMenuItem(value: 'bell', child: Text("Bell")),
                    DropdownMenuItem(value: 'soft', child: Text("Soft")),
                  ],
                  onChanged: (v) => setState(() => selectedRingtone = v!),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C7DA0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _saveMedicine,
                child: Text(
                  isEdit ? "Update Medicine" : "Save Medicine",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}