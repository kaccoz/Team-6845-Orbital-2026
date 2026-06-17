import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crumb/screens/profile_page.dart';
import 'package:crumb/services/habit_service.dart';
import 'package:crumb/screens/habits_page.dart';
import 'package:dashed_progress_bar/dashed_progress_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crumb/widgets/top_header.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HabitService habitService = HabitService();

  Future<void> loadGoal() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!mounted) return;

    setState(() {
      doc.data()?['goalDays'] ?? 7;
    });
  }

  void showAddHabitDialog(BuildContext context) {
    final TextEditingController habitController = TextEditingController();
    final TextEditingController durationController = TextEditingController();
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Habit"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: habitController,
                    decoration: const InputDecoration(labelText: "Habit"),
                  ),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: const InputDecoration(
                      labelText: "Duration",
                      suffixText: "min",
                    ),
                  ),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    habitService.addHabit(
                      habitController.text.trim(),
                      "${durationController.text.trim()} min",
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void confirmDeleteHabit(BuildContext context, String habitId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Habit"),
          content: const Text("Are you sure you want to delete this habit?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                habitService.deleteHabit(habitId);
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void showEditHabitDialog(BuildContext context, String habitId, Map data) {
    final TextEditingController habitController = TextEditingController(
      text: data['title'],
    );

    final TextEditingController durationController = TextEditingController(
      text: data['duration'].replaceAll(" min", ""),
    );

    String errorMessage = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Habit"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: habitController,
                    decoration: const InputDecoration(labelText: "Habit"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: const InputDecoration(
                      labelText: "Duration",
                      suffixText: "min",
                    ),
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    habitService.updateHabit(
                      habitId,
                      habitController.text.trim(),
                      "${durationController.text.trim()} min",
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showHabitOptions(BuildContext context, String habitId, Map data) {
    bool includeInStreak = data['includeInStreak'] ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(data['title']),
              content: SwitchListTile(
                title: const Text("Include in streak"),
                value: includeInStreak,
                onChanged: (value) {
                  setState(() => includeInStreak = value);
                  habitService.toggleStreak(habitId, value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFEAE8D7),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                TopHeader(
  title: "Home",
  uid: uid,
),
                const SizedBox(height: 20),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .snapshots(),
                  builder: (context, userSnap) {
                    final goalDays = userSnap.data?.data()?['goalDays'] ?? 7;

                    return StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('streaks')
                          .doc('main')
                          .snapshots(),
                      builder: (context, streakSnap) {
                        final data = streakSnap.data?.data();
                        final List dates = data?['dates'] ?? [];
                        final streakDays = dates.length;

                        return Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: SizedBox(
                            height: 220,
                            child: DashedCircularProgressBar.aspectRatio(
                              aspectRatio: 1,
                              progress: streakDays.toDouble(),
                              maxProgress: goalDays.toDouble(),
                              foregroundColor: const Color(0xFF8B6B4A),
                              backgroundColor: const Color(0xFFE0D6C8),
                              foregroundStrokeWidth: 10,
                              backgroundStrokeWidth: 10,
                              animation: true,
                              child: Center(
                                child: Text(
                                  "$streakDays / $goalDays",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B6B4A),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Text(
                    "Nice!! Keep showing up, your future self is watching.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF3E220F),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF78583E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Today's Habit",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: 35,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEAE8D7),
                                  foregroundColor: const Color(0xFF78583E),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () => showAddHabitDialog(context),
                                child: const Text("+ Add"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder(
                          stream: habitService.habits.snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }

                            final habits = snapshot.data!.docs;

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: habits.length,
                              itemBuilder: (context, index) {
                                final habit = habits[index];
                                final data = habit.data();

                                final today = habitService.getTodayString();
                                final List completedDates =
                                    data['completedDates'] ?? [];

                                final isDoneToday =
                                    completedDates.contains(today);

                                return Card(
                                  color: const Color(0xFFEAE8D7),
                                  child: ListTile(
                                    title: Text(data['title']),
                                    subtitle: Text(data['duration']),
                                    leading: Checkbox(
                                      value: isDoneToday,
                                      activeColor: const Color(0xFF78583E),
                                      onChanged: (value) async {
                                        if (value == true) {
                                          await habitService
                                              .markHabitDoneToday(habit.id);
                                        } else {
                                          await habitService
                                              .unmarkHabitToday(habit.id);
                                        }
                                      },
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          showEditHabitDialog(
                                              context, habit.id, data);
                                        }
                                        if (value == 'delete') {
                                          confirmDeleteHabit(context, habit.id);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                    onTap: () => showHabitOptions(
                                        context, habit.id, data),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF8B6B4A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: "Habits",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HabitsPage()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
      ),
    );
  }
}