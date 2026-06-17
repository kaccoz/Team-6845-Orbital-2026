import 'package:flutter/material.dart';
import 'package:crumb/services/habit_service.dart';
import 'package:streak_calendar/streak_calendar.dart';
import 'package:crumb/screens/profile_page.dart';
import 'package:crumb/widgets/top_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crumb/widgets/app_colors.dart';
import 'package:crumb/screens/home_page.dart';
import 'package:crumb/screens/connect_buddy_page.dart';

final HabitService habitService = HabitService();

class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE8D7),

      body: Column(
        children: [
          TopHeader(
            title: "Habits",
            uid: FirebaseAuth.instance.currentUser!.uid,
          ),

          Expanded(
            child: StreamBuilder(
              stream: habitService.getStreakStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final doc = snapshot.data!.data();
                List raw = doc?['dates'] ?? [];
                final datesForStreaks = raw
                    .map((e) => DateTime.parse(e))
                    .toList();

                return CleanCalendar(
                  enableDenseViewForDates: true,
                  enableDenseSplashForDates: true,
                  datesForStreaks: datesForStreaks,
                  currentDateProperties: DatesProperties(
                    datesDecoration: DatesDecoration(
                      datesBorderRadius: 1000,
                      datesBackgroundColor: Colors.transparent,
                      datesBorderColor: Colors.green,
                      datesTextColor: Colors.black,
                    ),
                  ),
                  generalDatesProperties: DatesProperties(
                    datesDecoration: DatesDecoration(
                      datesBorderRadius: 1000,
                      datesBackgroundColor: Colors.transparent,
                      datesBorderColor: Colors.transparent,
                      datesTextColor: Colors.black,
                    ),
                  ),
                  streakDatesProperties: DatesProperties(
                    datesDecoration: DatesDecoration(
                      datesBorderRadius: 1000,
                      datesBackgroundColor: Colors.green,
                      datesBorderColor: Colors.green,
                      datesTextColor: Colors.white,
                    ),
                  ),
                  leadingTrailingDatesProperties: DatesProperties(
                    datesDecoration: DatesDecoration(
                      datesBorderRadius: 1000,
                      datesBackgroundColor: Colors.transparent,
                      datesBorderColor: Colors.transparent,
                      datesTextColor: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
  backgroundColor: AppColors.lightBrown,
  selectedItemColor: Colors.white,
  unselectedItemColor: Colors.white70,
  type: BottomNavigationBarType.fixed,
  currentIndex: 1,
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
    if (index == 1) return;

    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
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
