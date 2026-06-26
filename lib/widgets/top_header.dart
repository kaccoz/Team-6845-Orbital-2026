// lib/widgets/top_header.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crumb/services/habit_service.dart';

class TopHeader extends StatelessWidget {
  final String title;
  final String uid;

  const TopHeader({super.key, required this.title, required this.uid});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E220F),
                ),
              ),

              const Align(
                alignment: Alignment.centerLeft,
                child: Icon(Icons.menu, size: 32, color: Color(0xFF3E220F)),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('streaks')
                      .doc('main')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data();
                    final List dates = data?['dates'] ?? [];

                    final streakDays = HabitService().calculateCurrentStreak(
                      List<String>.from(dates),
                    );

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E332E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥'),
                          const SizedBox(width: 4),
                          Text(
                            '$streakDays',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
