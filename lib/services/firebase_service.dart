import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= AUTH =================

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  User? get currentUser => _auth.currentUser;

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ================= DATABASE =================

  /// ✅ ADD MEDICINE
  Future<void> addMedicine({
    required String name,
    required String dosage,
    required String time,
    required int notificationId,
    required String ringtone,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    await _db.collection('medicines').add({
      'name': name,
      'dosage': dosage,
      'time': time,
      'taken': false,
      'notificationId': notificationId,
      'ringtone': ringtone,
      'userId': user.uid,
      'createdAt': Timestamp.now(),
    });
  }

  /// ✅ GET MEDICINES (Live Stream)
  Stream<QuerySnapshot> getMedicines() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _db
        .collection('medicines')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true) // 🔥 ترتيب
        .snapshots();
  }

  /// ✅ DELETE MEDICINE
  Future<void> deleteMedicine(String id) async {
    await _db.collection('medicines').doc(id).delete();
  }

  /// ✅ UPDATE STATUS (Taken / Not Taken)
  Future<void> updateMedicineStatus(String id, bool taken) async {
    await _db.collection('medicines').doc(id).update({
      'taken': taken,
    });
  }

  /// ✅ UPDATE MEDICINE (Edit Screen)
  Future<void> updateMedicine({
    required String id,
    required String name,
    required String dosage,
    required String time,
    required int notificationId,
    required String ringtone,
  }) async {
    await _db.collection('medicines').doc(id).update({
      'name': name,
      'dosage': dosage,
      'time': time,
      'notificationId': notificationId,
      'ringtone': ringtone,
    });
  }
}