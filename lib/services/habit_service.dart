import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:async/async.dart';

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

    await habits.doc(habitId).update({'completedDates': completedDates});

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

    await habits.doc(habitId).update({'completedDates': completedDates});

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

  int calculateCurrentStreak(List<String> dates) {
    dates.sort();

    int streak = 0;

    DateTime today = DateTime.now();
    DateTime current = DateTime(today.year, today.month, today.day);

    for (int i = dates.length - 1; i >= 0; i--) {
      DateTime d = DateTime.parse(dates[i]);

      if (d.year == current.year &&
          d.month == current.month &&
          d.day == current.day) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
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
        await ref.set({'dates': [], 'graceDays': 0});
        return;
      }

      final allComplete = streakHabits.every((doc) {
        final data = doc.data();
        final List completedDates = List.from(data['completedDates'] ?? []);
        return completedDates.contains(today);
      });

      final docSnap = await ref.get();

      List<String> dates = [];
    int graceDays = 0;

      if (docSnap.exists) {
      final data = docSnap.data();
        dates = List<String>.from(data?['dates'] ?? []);
      graceDays = data?['graceDays'] ?? 0;
      }
    String? lastRewardedDate = docSnap.data()?['lastRewardedDate'];

    if (allComplete) {
      if (!dates.contains(today)) {
        dates.add(today);
      }
    } else {
      if (graceDays > 0) {
        graceDays -= 1;

        if (!dates.contains(today)) {
          dates.add(today);
        }
      } else {
        dates.remove(today);
      }
    }
    final currentStreak = calculateCurrentStreak(dates);

    if (currentStreak > 0 &&
        currentStreak % 10 == 0 &&
        lastRewardedDate != today) {
      graceDays += 1;
      lastRewardedDate = today;
    }
    await ref.set({
      'dates': dates,
      'graceDays': graceDays,
      'lastRewardedDate': lastRewardedDate,
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getStreakStream() {
    final uid = auth.currentUser!.uid;
    return firestore
        .collection('users')
        .doc(uid)
        .collection('streaks')
        .doc('main')
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

  Future<int> getStreakCount(String uid) async {
    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('streaks')
        .doc('main')
        .get();
        
    if (!doc.exists) return 0;
    
    final List dates = doc.data()?['dates'] ?? [];
    return dates.length; 
  }

  Future<int> getCompletedHabitsToday() async {
    final uid = auth.currentUser!.uid;
    final today = getTodayString();
    
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('habits')
        .where('completedDates', arrayContains: today)
        .get();
        
    return snapshot.docs.length;
  }

  Future<Map<String, dynamic>> getDailyStats() async {
    final uid = auth.currentUser!.uid;
    final today = getTodayString();
    final snapshot = await firestore.collection('users').doc(uid).collection('habits').get();
    
    int totalTasks = snapshot.docs.length;
    int completedTasks = 0;
    int totalDuration = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      List completedDates = List.from(data['completedDates'] ?? []);

      if (completedDates.contains(today)) {
        completedTasks++;
        String durationStr = data['duration'] ?? "0";
        final regExp = RegExp(r'\d+');
        final match = regExp.firstMatch(durationStr);
        if (match != null) {
          totalDuration += int.parse(match.group(0)!);
        }
      }
    }

    return {
      "completed": completedTasks,
      "total": totalTasks,
      "duration": totalDuration,
    };
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCombinedRecentActivity(String myId, String buddyId) {
    final today = getTodayString();

    final myStream = firestore.collection('users').doc(myId).collection('habits')
        .where('completedDates', arrayContains: today).snapshots();
        
    final buddyStream = firestore.collection('users').doc(buddyId).collection('habits')
        .where('completedDates', arrayContains: today).snapshots();

    return StreamGroup.merge([myStream, buddyStream]);
  }
}