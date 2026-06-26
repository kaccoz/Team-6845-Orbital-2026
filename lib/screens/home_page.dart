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
import 'package:crumb/screens/goalsetup_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HabitService habitService = HabitService();

  final List<String> weekdaysList = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

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
    bool includeInStreak = false;
    final TextEditingController habitController = TextEditingController();
    String repeatType = 'daily';
    List<int> selectedDays = [];
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.backgroundColor,
              title: const Text(
                "Add Habit",
                style: TextStyle(
                  color: AppColors.primaryBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: habitController,
                    decoration: const InputDecoration(labelText: "Habit"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: repeatType,
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text("Everyday")),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text("Specific Days"),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        repeatType = value!;
                      });
                    },
                  ),
                  if (repeatType == 'weekly') ...[
                    Wrap(
                      spacing: 6,
                      children: List.generate(weekdaysList.length, (index) {
                        final int dayValue = index + 1;
                        return FilterChip(
                          label: Text(weekdaysList[index]),
                          selected: selectedDays.contains(dayValue),
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedDays.add(dayValue);
                              } else {
                                selectedDays.remove(dayValue);
                              }
                            });
                          },
                        );
                      }),
                    ),
                  ],

                  const SizedBox(height: 10),

                  SwitchListTile(
                    title: const Text(
                      "Include in streak",
                      style: TextStyle(color: AppColors.primaryBrown),
                    ),
                    activeColor: AppColors.primaryBrown,
                    value: includeInStreak,
                    onChanged: (value) {
                      setDialogState(() {
                        includeInStreak = value;
                      });
                    },
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
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: AppColors.primaryBrown),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBrown,
                  ),
                  onPressed: () {
                    habitService.addHabit(
                      habitController.text.trim(),
                      repeatType,
                      selectedDays,
                      includeInStreak,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Add",
                    style: TextStyle(color: Colors.white),
                  ),
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
          title: const Text(
            "Delete Habit",
            style: TextStyle(
              color: AppColors.warningRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text("Are you sure you want to delete this habit?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: AppColors.primaryBrown),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warningRed,
              ),
              onPressed: () {
                habitService.deleteHabit(habitId);
                Navigator.pop(context);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
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

    String repeatType = data['repeatType'] ?? 'daily';
    List<int> selectedDays = List<int>.from(data['daysOfWeek'] ?? []);
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.backgroundColor,
              title: const Text(
                "Edit Habit",
                style: TextStyle(
                  color: AppColors.primaryBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: habitController,
                    decoration: const InputDecoration(labelText: "Habit"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: repeatType,
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text("Everyday")),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text("Specific Days"),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        repeatType = value!;
                      });
                    },
                  ),
                  if (repeatType == 'weekly')
                    Wrap(
                      spacing: 6,
                      children: List.generate(weekdaysList.length, (index) {
                        final int dayValue = index + 1;
                        return FilterChip(
                          label: Text(weekdaysList[index]),
                          selected: selectedDays.contains(dayValue),
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedDays.add(dayValue);
                              } else {
                                selectedDays.remove(dayValue);
                              }
                            });
                          },
                        );
                      }),
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
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: AppColors.primaryBrown),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBrown,
                  ),
                  onPressed: () {
                    habitService.updateHabit(
                      habitId,
                      habitController.text.trim(),
                      repeatType,
                      selectedDays,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Update",
                    style: TextStyle(color: Colors.white),
                  ),
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
              backgroundColor: AppColors.backgroundColor,
              title: Text(
                data['title'],
                style: const TextStyle(
                  color: AppColors.primaryBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text(
                      "Include in streak",
                      style: TextStyle(color: AppColors.primaryBrown),
                    ),
                    activeColor: AppColors.primaryBrown,
                    value: includeInStreak,
                    onChanged: (value) async {
                      if (!value) {
                        final uid = FirebaseAuth.instance.currentUser!.uid;

                        final snapshot = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('habits')
                            .where('includeInStreak', isEqualTo: true)
                            .get();

                        if (snapshot.docs.length <= 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "At least one habit must remain in your streak",
                                style: TextStyle(fontSize: 13),
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                      }

                      setState(() => includeInStreak = value);
                      habitService.toggleStreak(habitId, value);
                    },
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBrown,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            showEditHabitDialog(context, habitId, data);
                          },
                          child: const Text(
                            "Edit",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warningRed,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            confirmDeleteHabit(context, habitId);
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: AppColors.primaryBrown),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGoalCompletedDialog(BuildContext context, int goalDays) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'lastCompletedGoal': goalDays,
    }, SetOptions(merge: true));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: const Text(
            "Goal Completed 🎉",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBrown,
            ),
          ),
          content: Text(
            "You completed your $goalDays-day streak!\n\nReady to set a new goal?",
            style: const TextStyle(color: AppColors.primaryBrown),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Later"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GoalSetupPage(),
                  ),
                );
              },
              child: const Text("Set New Goal"),
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
                    final streakDays = habitService.calculateCurrentStreak(
                      List<String>.from(dates),
                    );
                    final userData = userSnap.data?.data();
                    final lastCompletedGoal = userData?['lastCompletedGoal'];

                    if (streakDays >= goalDays &&
                        lastCompletedGoal != goalDays) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showGoalCompletedDialog(context, goalDays);
                      });
                    }
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
                            child: const Text(
                              "+ Add",
                              style: TextStyle(
                                color: AppColors.primaryBrown,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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

                          final now = DateTime.now();
                          final int todayWeekday = now.weekday;

                          final visibleHabits = habits.where((habit) {
                            final data = habit.data();
                            final repeatType = data['repeatType'] ?? 'daily';
                            final List daysOfWeek = data['daysOfWeek'] ?? [];
                            return repeatType == 'daily' ||
                                (repeatType == 'weekly' &&
                                    daysOfWeek.contains(todayWeekday));
                          }).toList();

                          final otherHabits = habits.where((habit) {
                            final data = habit.data();
                            final repeatType = data['repeatType'] ?? 'daily';
                            final List daysOfWeek = data['daysOfWeek'] ?? [];
                            return repeatType == 'weekly' &&
                                !daysOfWeek.contains(todayWeekday);
                          }).toList();

                          final combinedHabits = [
                            ...visibleHabits,
                            ...otherHabits,
                          ];

                          return ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: combinedHabits.length,
                            itemBuilder: (context, index) {
                              final habit = combinedHabits[index];
                              final data = habit.data();

                              final today = habitService.getTodayString();
                              final List completedDates =
                                  data['completedDates'] ?? [];
                              final isDoneToday = completedDates.contains(
                                today,
                              );

                              final bool isOtherHabit =
                                  index >= visibleHabits.length;

                              return Card(
                                color: isOtherHabit
                                    ? AppColors.backgroundColor.withOpacity(0.6)
                                    : AppColors.backgroundColor,
                                child: ListTile(
                                  title: Text(
                                    data['title'],
                                    style: TextStyle(
                                      color: isOtherHabit
                                          ? AppColors.primaryBrown.withOpacity(
                                              0.6,
                                            )
                                          : AppColors.primaryBrown,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  leading: Checkbox(
                                    value: isDoneToday,
                                    activeColor: AppColors.primaryBrown,
                                    checkColor: Colors.white,
                                    onChanged: isOtherHabit
                                        ? null
                                        : (value) async {
                                            if (value == true) {
                                              await habitService
                                                  .markHabitDoneToday(habit.id);
                                            } else {
                                              await habitService
                                                  .unmarkHabitToday(habit.id);
                                            }
                                          },
                                  ),

                                  onTap: () =>
                                      showHabitOptions(context, habit.id, data),
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
