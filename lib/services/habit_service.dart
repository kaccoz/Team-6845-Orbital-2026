import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HabitService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get habits {
    final uid = auth.currentUser!.uid;
    return firestore.collection('users').doc(uid).collection('habits');
  }

  Future<void> addHabit(String title, String duration) async {
    await habits.add({
      'title': title,
      'duration': duration,
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateHabit(String habitId, String title, String duration) async {
    await habits.doc(habitId).update({
      'title': title,
      'duration': duration,
    });
  }

  Future<void> toggleHabit(String habitId, bool completed) async {
    await habits.doc(habitId).update({
      'completed': completed,
    });
  }

  Future<void> deleteHabit(String habitId) async {
    await habits.doc(habitId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getHabits() {
    return habits.orderBy('createdAt', descending: false).snapshots();
  }
}