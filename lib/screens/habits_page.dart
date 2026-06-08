import 'package:flutter/material.dart';
import 'package:crumb/services/habit_service.dart';
import 'package:streak_calendar/streak_calendar.dart';

final HabitService habitService = HabitService();

class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE8D7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B6B4A),
        foregroundColor: Colors.white,
        title: const Text("Habits"),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: habitService.getStreakStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs;

          List raw = [];

          if (data.isNotEmpty) {
            raw = data.first.data()['dates'] ?? [];
          }

          final datesForStreaks = raw.map((e) => DateTime.parse(e)).toList();

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
    );
  }
}