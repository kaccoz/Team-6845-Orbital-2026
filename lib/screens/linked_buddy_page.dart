import 'dart:convert';
import 'package:crumb/widgets/top_header.dart';
import 'package:crumb/widgets/app_colors.dart';
import 'package:crumb/services/habit_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BuddiesPage extends StatelessWidget {
  final String currentUserName;
  final String? currentUserPfpBase64;
  final int? currentUserStreak;
  final String buddyId;
  final String buddyName;
  final String? buddyPfpBase64;
  final int? buddyStreak;
  final VoidCallback onUnlink;
  final HabitService habitService = HabitService();

  BuddiesPage({
    super.key,
    required this.currentUserName,
    this.currentUserPfpBase64,
    this.currentUserStreak,
    required this.buddyId,
    required this.buddyName,
    this.buddyPfpBase64,
    this.buddyStreak,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final String buddyId = "REPLACE_WITH_ACTUAL_BUDDY_ID";

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            TopHeader(title: "Buddy Tracking", uid: uid),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  children: [
                    _buildAvatarHeader(),
                    const SizedBox(height: 32),
                    _buildProtectionCard(),
                    const SizedBox(height: 32),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recent Activity',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBrown),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: habitService.getCombinedRecentActivity(uid, buddyId),
                      builder: (context, snapshot) {  
                        if (snapshot.hasError) {
                          debugPrint("STREAM ERROR: ${snapshot.error}");
                        }
                        if (snapshot.hasData) {
                          debugPrint("STREAM DATA COUNT: ${snapshot.data!.length}");
                          for (var item in snapshot.data!) {
                            debugPrint("FOUND ITEM: ${item['title']} for user ${item['uid']}");
                          }
                        }

                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        
                        final activities = snapshot.data!;
                        if (activities.isEmpty) return _buildEmptyActivityFeed();
                        
                        return _buildDynamicActivityFeed(activities, uid);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivityFeed() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(color: AppColors.primaryBrown, borderRadius: BorderRadius.circular(24)),
      child: const Column(
        children: [
          Icon(Icons.history_toggle_off, color: AppColors.cardColor, size: 40),
          SizedBox(height: 12),
          Text("No recent updates", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDynamicActivityFeed(List<Map<String, dynamic>> activities, String myUid) {
    return Container(
      decoration: BoxDecoration(color: AppColors.primaryBrown, borderRadius: BorderRadius.circular(24)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) => const Divider(color: AppColors.backgroundColor, height: 1, thickness: 0.5, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final item = activities[index];
          final name = (item['uid'] == myUid) ? "You" : buddyName;
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const CircleAvatar(backgroundColor: AppColors.backgroundColor, child: Icon(Icons.person, color: AppColors.primaryBrown)),
            title: Text("$name completed ${item['title']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  Widget _buildAvatarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAvatarFrame(username: currentUserName, pfpBase64: currentUserPfpBase64, streak: currentUserStreak),
        const Icon(Icons.link, color: AppColors.cardColor, size: 40),
        _buildAvatarFrame(username: buddyName, pfpBase64: buddyPfpBase64, streak: buddyStreak),
      ],
    );
  }

  Widget _buildAvatarFrame({required String username, required String? pfpBase64, required int? streak}) {
    ImageProvider? avatarImage;
    if (pfpBase64 != null && pfpBase64.isNotEmpty) {
      try { avatarImage = MemoryImage(base64Decode(pfpBase64)); } catch (_) { avatarImage = null; }
    }
    return Column(
      children: [
        CircleAvatar(radius: 56, backgroundColor: AppColors.primaryBrown,
          child: CircleAvatar(radius: 51, backgroundColor: AppColors.backgroundColor, backgroundImage: avatarImage,
            child: avatarImage == null ? const Icon(Icons.person, size: 55, color: AppColors.primaryBrown) : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBrown)),
        const SizedBox(height: 2),
        Text(streak != null ? "$streak day streak" : "day streak", style: const TextStyle(fontSize: 13, color: AppColors.primaryBrown, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildProtectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(color: AppColors.primaryBrown, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Text("Protect each other’s streaks!", textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text("If one of you misses a day,\nboth streaks reset.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.backgroundColor, height: 1.3)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onUnlink,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cardColor, foregroundColor: AppColors.primaryBrown, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text("Unlink Buddy", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}