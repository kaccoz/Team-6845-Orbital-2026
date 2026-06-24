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

                return Column(
                  children: [
                    CleanCalendar(
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
                    ),

                    const SizedBox(height: 30),

                    _buildGraceDaysWidget(doc),

                    const SizedBox(height: 0),

                    _buildStatsSection(),
                  ],
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

  Widget _buildGraceDaysWidget(Map<String, dynamic>? doc) {
    final graceDays = doc?['graceDays'] ?? 0;

    String message = graceDays == 0
        ? "No grace days yet"
        : "You have $graceDays safety net 💛";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Grace Days Earned",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryBrown),
              ),
              Text(
                graceDays.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBrown,
                ),
              ),
            ],
          ),

          const SizedBox(height: 0),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: habitService.getDailyStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final stats = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Your Stats Today", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBrown)),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildStatCard("${stats['completed']}", "out of your ${stats['total']} tasks have been marked completed today!"),
                  const SizedBox(width: 15),
                  _buildStatCard("${stats['duration']}", "that's the number of minutes you devoted to completed tasks today!"),
                ],
              ),
              const SizedBox(height: 20),
              const Center(child: Text("consistency is the quiet engine of success.", style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.primaryBrown))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String number, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            CircleAvatar(backgroundColor: AppColors.primaryBrown, child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
