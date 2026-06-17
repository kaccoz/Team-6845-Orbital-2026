import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crumb/screens/profile_page.dart';
import 'package:crumb/services/habit_service.dart';
import 'package:crumb/screens/habits_page.dart';
import 'package:dashed_progress_bar/dashed_progress_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crumb/widgets/top_header.dart';
import 'package:crumb/screens/connect_buddy_page.dart';
import 'package:crumb/widgets/app_colors.dart'; 

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
              backgroundColor: AppColors.backgroundColor,
              title: const Text("Add Habit", style: TextStyle(color: AppColors.primaryBrown, fontWeight: FontWeight.bold)),
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: "Duration",
                      suffixText: "min",
                    ),
                  ),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: const TextStyle(color: AppColors.warningRed),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: AppColors.primaryBrown)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBrown),
                  onPressed: () {
                    habitService.addHabit(
                      habitController.text.trim(),
                      "${durationController.text.trim()} min",
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Add", style: TextStyle(color: Colors.white)),
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
          backgroundColor: AppColors.backgroundColor,
          title: const Text("Delete Habit", style: TextStyle(color: AppColors.warningRed, fontWeight: FontWeight.bold)),
          content: const Text("Are you sure you want to delete this habit?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: AppColors.primaryBrown)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningRed),
              onPressed: () {
                habitService.deleteHabit(habitId);
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
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
              backgroundColor: AppColors.backgroundColor,
              title: const Text("Edit Habit", style: TextStyle(color: AppColors.primaryBrown, fontWeight: FontWeight.bold)),
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                        style: const TextStyle(color: AppColors.warningRed),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: AppColors.primaryBrown)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBrown),
                  onPressed: () {
                    habitService.updateHabit(
                      habitId,
                      habitController.text.trim(),
                      "${durationController.text.trim()} min",
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Update", style: TextStyle(color: Colors.white)),
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
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: Text(data['title'], style: const TextStyle(color: AppColors.primaryBrown, fontWeight: FontWeight.bold)),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SwitchListTile(
                title: const Text("Include in streak", style: TextStyle(color: AppColors.primaryBrown)),
                activeColor: AppColors.primaryBrown,
                value: includeInStreak,
                onChanged: (value) {
                  setState(() => includeInStreak = value);
                  habitService.toggleStreak(habitId, value);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: AppColors.primaryBrown)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            TopHeader(title: "Home", uid: uid),
            const SizedBox(height: 20),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, userSnap) {
                final goalDays = userSnap.data?.data()?['goalDays'] ?? 7;

                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
                      padding: const EdgeInsets.only(top: 20),
                      child: SizedBox(
                        height: 200,
                        child: DashedCircularProgressBar.aspectRatio(
                          aspectRatio: 1,
                          progress: streakDays.toDouble(),
                          maxProgress: goalDays.toDouble(),
                          foregroundColor: AppColors.lightBrown,
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
                                color: AppColors.lightBrown,
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
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Text(
                "Nice!! Keep showing up, your future self is watching.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryBrown,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // This Expanded forces the container asset to fill remaining space
            // and allows inside elements to handle scrolling independently
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
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
                          backgroundColor: AppColors.backgroundColor,
                          foregroundColor: AppColors.cardColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => showAddHabitDialog(context),
                        child: const Text("+ Add", style: TextStyle(color: AppColors.primaryBrown, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Nesting an Expanded around ListView.builder lets it scroll internally
                Expanded(
                  child: StreamBuilder(
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

                      if (habits.isEmpty) {
                        return const Center(
                          child: Text(
                            "No habits added yet!",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: habits.length,
                        itemBuilder: (context, index) {
                          final habit = habits[index];
                          final data = habit.data();

                          final today = habitService.getTodayString();
                          final List completedDates =
                              data['completedDates'] ?? [];

                          final isDoneToday = completedDates.contains(
                            today,
                          );

                          return Card(
                            color: AppColors.backgroundColor,
                            child: ListTile(
                              title: Text(data['title'], style: const TextStyle(color: AppColors.primaryBrown, fontWeight: FontWeight.bold)),
                              subtitle: Text(data['duration']),
                              leading: Checkbox(
                                value: isDoneToday,
                                activeColor: AppColors.primaryBrown,
                                checkColor: Colors.white,
                                onChanged: (value) async {
                                  if (value == true) {
                                    await habitService.markHabitDoneToday(
                                      habit.id,
                                    );
                                  } else {
                                    await habitService.unmarkHabitToday(
                                      habit.id,
                                    );
                                  }
                                },
                              ),
                              trailing: PopupMenuButton<String>(
                                iconColor: AppColors.primaryBrown,
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    showEditHabitDialog(
                                      context,
                                      habit.id,
                                      data,
                                    );
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
                                context,
                                habit.id,
                                data,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
  bottomNavigationBar: BottomNavigationBar(
    backgroundColor: AppColors.lightBrown,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white70,
    type: BottomNavigationBarType.fixed,
    currentIndex: 0,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      BottomNavigationBarItem(
        icon: Icon(Icons.check_circle),
        label: "Habits",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.people_alt_rounded),
        label: "Buddy",
      ),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
    ],
    onTap: (index) {
      if (index == 0) return;

      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HabitsPage()),
        );
      }

      if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ConnectBuddyPage()),
        );
      }

      if (index == 3) {
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