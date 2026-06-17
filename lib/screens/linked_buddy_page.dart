import 'dart:convert';
import 'package:flutter/material.dart';


class BuddiesPage extends StatelessWidget {
  final String currentUserName;
  final String? currentUserPfpBase64;
  final int? currentUserStreak;

  final String buddyName;
  final String? buddyPfpBase64;
  final int? buddyStreak;

  final List<Map<String, String>> recentActivity;

  static const Color backgroundColor = Color(0xFFECEAE0);
  static const Color primaryBrown = Color(0xFF6F5643);
  static const Color cardColor = Color(0xFFCBB28A);
  static const Color warningRed = Color(0xFFB45B52);

  const BuddiesPage({
    super.key,
    required this.currentUserName,
    this.currentUserPfpBase64,
    this.currentUserStreak,
    required this.buddyName,
    this.buddyPfpBase64,
    this.buddyStreak,
    required this.recentActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryBrown),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: primaryBrown, size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Buddies',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryBrown,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Avatars and usernames section
              _buildAvatarHeader(),
              const SizedBox(height: 32),

              // Reminder section
              _buildProtectionCard(),
              const SizedBox(height: 32),

              // Activity header
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryBrown,
                ),
              ),
              const SizedBox(height: 12),

              // Activity box
              _buildActivityFeed(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAvatarFrame(
          username: currentUserName,
          pfpBase64: currentUserPfpBase64,
          streak: currentUserStreak,
        ),
        
        // Linking Indicator
        const Icon(
          Icons.link,
          color: cardColor,
          size: 40,
        ),
        
        // Buddy Profile Block
        _buildAvatarFrame(
          username: buddyName,
          pfpBase64: buddyPfpBase64,
          streak: buddyStreak,
        ),
      ],
    );
  }

  Widget _buildAvatarFrame({
    required String username, 
    required String? pfpBase64, 
    required int? streak,
  }) {
    ImageProvider? avatarImage;
    if (pfpBase64 != null && pfpBase64.isNotEmpty) {
      try {
        avatarImage = MemoryImage(base64Decode(pfpBase64));
      } catch (_) {
        avatarImage = null; 
      }
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 56,
          backgroundColor: primaryBrown,
          child: CircleAvatar(
            radius: 51,
            backgroundColor: backgroundColor, 
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? const Icon(Icons.person, size: 55, color: primaryBrown)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          username,
          style: const TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: primaryBrown,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          streak != null ? "$streak day streak" : "day streak",
          style: const TextStyle(
            fontSize: 13, 
            color: primaryBrown, 
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProtectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: primaryBrown, 
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            "Protect each other’s streaks!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19, 
              fontWeight: FontWeight.bold, 
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "If one of you misses a day,\nboth streaks reset.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, 
              color: backgroundColor, 
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Disconnect anchor logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cardColor, 
              foregroundColor: primaryBrown,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "Unlink Buddy", 
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed() {
    if (recentActivity.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        decoration: BoxDecoration(
          color: primaryBrown,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, color: cardColor, size: 40),
            SizedBox(height: 12),
            Text(
              "No recent updates",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: primaryBrown,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentActivity.length,
        itemBuilder: (context, index) {
          final item = recentActivity[index];
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const CircleAvatar(
                  backgroundColor: backgroundColor,
                  child: Icon(Icons.person, color: primaryBrown),
                ),
                title: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    children: [
                      TextSpan(text: "${item['name']} completed "),
                      TextSpan(
                        text: item['task'] ?? '', 
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    item['time'] ?? '',
                    style: const TextStyle(color: cardColor, fontSize: 12),
                  ),
                ),
              ),
              if (index < recentActivity.length - 1)
                const Divider(
                  color: backgroundColor, 
                  height: 1, 
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        },
      ),
    );
  }
}