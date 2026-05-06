import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Stream<QuerySnapshot> getMedicines() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _db
        .collection('medicines')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteMedicine(String id) async {
    await _db.collection('medicines').doc(id).delete();
  }

  Future<void> updateMedicineStatus(String id, bool taken) async {
    await _db.collection('medicines').doc(id).update({
      'taken': taken,
    });
  }

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

  Future<void> markAsTakenByNotification(int notificationId) async {
    final snapshot = await _db
        .collection('medicines')
        .where('notificationId', isEqualTo: notificationId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'taken': true});
    }
  }
}