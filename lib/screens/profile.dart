import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final nameController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  File? _selectedImageFile;       
  Uint8List? _selectedImageBytes; 

  @override
  void initState() {
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;
    nameController.text = user?.displayName ?? "";
    _loadImage();
  }

  Future<void> _loadImage() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final key = 'profile_image_$uid';
    final saved = prefs.getString(key);
    if (saved == null) return;

    if (kIsWeb) {
      try {
        final bytes = base64Decode(saved);
        setState(() => _selectedImageBytes = bytes);
      } catch (_) {}
    } else {
      final file = File(saved);
      if (file.existsSync()) {
        setState(() => _selectedImageFile = file);
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (picked == null) return;

    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      final encoded = base64Encode(bytes);

      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
      final key = 'profile_image_$uid';
      await prefs.setString(key, encoded);

      setState(() => _selectedImageBytes = bytes);
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final savedImage =
          await File(picked.path).copy('${appDir.path}/${picked.name}');

      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
      final key = 'profile_image_$uid';
      await prefs.setString(key, savedImage.path);
      setState(() => _selectedImageFile = savedImage);

    }
  }

  ImageProvider? get _imageProvider {
    if (kIsWeb && _selectedImageBytes != null) {
      return MemoryImage(_selectedImageBytes!);
    }
    if (!kIsWeb && _selectedImageFile != null) {
      return FileImage(_selectedImageFile!);
    }
    return null;
  }

  bool get _hasImage =>
      (kIsWeb && _selectedImageBytes != null) ||
      (!kIsWeb && _selectedImageFile != null);

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (nameController.text.isNotEmpty) {
        await user!.updateDisplayName(nameController.text.trim());
      }

      if (passwordController.text.isNotEmpty) {
        await user!.updatePassword(passwordController.text.trim());
      }

      await user!.reload();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully ✅")),
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'requires-recent-login') {
        message = 'Please log in again to change password';
      } else {
        message = e.message ?? "Update failed";
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: const Color(0xFF2C7DA0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            const SizedBox(height: 20),

            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor:
                    const Color(0xFF2C7DA0).withOpacity(0.1),
                backgroundImage: _imageProvider,
                child: !_hasImage
                    ? const Icon(Icons.camera_alt,
                        size: 40, color: Color(0xFF2C7DA0))
                    : null,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Tap to change photo",
              style: TextStyle(color: Theme.of(context).hintColor),
            ),

            const SizedBox(height: 16),

            Text(
              user?.email ?? "No Email",
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).hintColor,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: "New Password",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C7DA0),
                ),
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes",
                        style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}