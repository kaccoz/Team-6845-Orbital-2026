import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HabitService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  CollectionReference<Map<String, dynamic>> get habits {
    final uid = auth.currentUser!.uid;
    return firestore.collection('users').doc(uid).collection('habits');
  }
  String getTodayString() {
  final today = DateTime.now();
  return "${today.year.toString().padLeft(4, '0')}-"
    "${today.month.toString().padLeft(2, '0')}-"
    "${today.day.toString().padLeft(2, '0')}";
}

  Future<void> addHabit(String title, String duration) async {
    await habits.add({
      'title': title,
      'duration': duration,
      'completedDates': [],
      'includeInStreak': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateHabit(
    String habitId,
    String title,
    String duration,
  ) async {
    await habits.doc(habitId).update({'title': title, 'duration': duration});
  }

  Future<void> markHabitDoneToday(String habitId) async {
  final today = getTodayString();

  final doc = await habits.doc(habitId).get();
  final data = doc.data()!;
  
  List completedDates = List.from(data['completedDates'] ?? []);

  if (!completedDates.contains(today)) {
    completedDates.add(today);
  }

  await habits.doc(habitId).update({
    'completedDates': completedDates,
  });

  await updateStreak();
}

  Future<void> deleteHabit(String habitId) async {
  await habits.doc(habitId).delete();

  await updateStreak();
}

Future<void> unmarkHabitToday(String habitId) async {
  final today = getTodayString();

  final doc = await habits.doc(habitId).get();
  final data = doc.data()!;

  List completedDates = List.from(data['completedDates'] ?? []);

  completedDates.remove(today);

  await habits.doc(habitId).update({
    'completedDates': completedDates,
  });

  await updateStreak();
}

  Future<void> toggleStreak(String habitId, bool value) async {
    await habits.doc(habitId).update({'includeInStreak': value});
    await updateStreak();
  }


  Future<bool> checkTodayStreak() async {
  final snapshot = await habits.get();
  final docs = snapshot.docs;

  final today = getTodayString();

  final streakHabits = docs.where((doc) {
    final data = doc.data();
    return data['includeInStreak'] == true;
  }).toList();

  if (streakHabits.isEmpty) return false;

  final incomplete = streakHabits.where((doc) {
    final data = doc.data();

    final List completedDates = data['completedDates'] ?? [];

    return !completedDates.contains(today);
  });

  return incomplete.isEmpty;
}

Future<void> updateStreak() async {
  final uid = auth.currentUser!.uid;
  final today = getTodayString();

  final snapshot = await habits.get();
  final docs = snapshot.docs;

  final streakHabits = docs.where((doc) {
    final data = doc.data();
    return (data['includeInStreak'] ?? false) == true;
  }).toList();

  final ref = firestore
      .collection('users')
      .doc(uid)
      .collection('streaks')
      .doc('main');

  if (streakHabits.isEmpty) {
    await ref.set({'dates': []});
    return;
  }

  final allComplete = streakHabits.every((doc) {
    final data = doc.data();
    final List completedDates = List.from(data['completedDates'] ?? []);
    return completedDates.contains(today);
  });

  final docSnap = await ref.get();
  List dates = [];

  if (docSnap.exists) {
    dates = List.from(docSnap.data()?['dates'] ?? []);
  }

  if (allComplete) {
    if (!dates.contains(today)) {
      dates.add(today);
    }
  } else {
    dates.remove(today);
  }

  await ref.set({'dates': dates});
}

  Stream<QuerySnapshot<Map<String, dynamic>>> getStreakStream() {
    final uid = auth.currentUser!.uid;
    return firestore
        .collection('users')
        .doc(uid)
        .collection('streaks')
        .snapshots();
  }

   Stream<QuerySnapshot<Map<String, dynamic>>> getHabits() {
    final uid = auth.currentUser!.uid;

    return firestore
        .collection('users')
        .doc(uid)
        .collection('habits')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
}
