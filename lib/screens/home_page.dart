import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crumb/screens/profile_page.dart';
import 'package:crumb/services/habit_service.dart';
import 'package:crumb/screens/habits_page.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final HabitService habitService = HabitService();
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: "Duration",
                      suffixText: "min",
                    ),
                  ),
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (habitController.text.trim().isEmpty) {
                      setDialogState(() {
                        errorMessage = "Please enter a habit.";
                      });
                      return;
                    }
                    if (durationController.text.trim().isEmpty) {
                      setDialogState(() {
                        errorMessage = "Please enter duration in minutes.";
                      });
                      return;
                    }
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
              onPressed: () {
                Navigator.pop(context);
              },
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Habit"),
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
                decoration: const InputDecoration(
                  labelText: "Duration",
                  suffixText: "min",
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Duration: ${data['duration']}"),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Include in streak"),
                      Switch(
                        value: includeInStreak,
                        onChanged: (value) {
                          setState(() {
                            includeInStreak = value;
                          });
                          habitService.toggleStreak(habitId, value);
                        },
                      ),
                    ],
                  ),
                ],
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
    return Scaffold(
      backgroundColor: const Color(0xFFEAE8D7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B6B4A),
        foregroundColor: Colors.white,
        title: const Text("Crumb"),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: habitService.habits.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final habits = snapshot.data!.docs;
          if (habits.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 80,
                    color: Color(0xFF8B6B4A),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Welcome to Crumb!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B6B4A),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Try adding a habit!",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              final data = habit.data();
              final today = habitService.getTodayString();
              final List completedDates = data['completedDates'] ?? [];

              final isDoneToday = completedDates.contains(today);
              return Card(
                child: ListTile(
                  onTap: () {
                    showHabitOptions(context, habit.id, data);
                  },
                  title: Text(data['title']),
                  subtitle: Text(data['duration']),
                  leading: Checkbox(
                    value: isDoneToday,
                    onChanged: (value) async {
                      if (value == true) {
                        await habitService.markHabitDoneToday(habit.id);
                      } else {
                        await habitService.unmarkHabitToday(habit.id);
                      }
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        color: const Color(0xFF6F5643),
                        onPressed: () {
                          showEditHabitDialog(context, habit.id, data);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: const Color(0xFF6F5643),
                        onPressed: () {
                          confirmDeleteHabit(context, habit.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B6B4A),
        onPressed: () {
          showAddHabitDialog(context);
        },
        child: const Icon(Icons.add),
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
