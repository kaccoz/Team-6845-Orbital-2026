import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crumb/services/auth_service.dart';
import 'package:crumb/screens/linked_buddy_page.dart'; 
import 'package:crumb/screens/home_page.dart';
import 'package:crumb/screens/habits_page.dart';
import 'package:crumb/screens/profile_page.dart';

class ConnectBuddyPage extends StatefulWidget {
  const ConnectBuddyPage({super.key});

  @override
  State<ConnectBuddyPage> createState() => _ConnectBuddyPageState();
}

class _ConnectBuddyPageState extends State<ConnectBuddyPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isCheckingBuddy = true;
  bool _isSubmittingCode = false;
  String? _currentBuddyUid;

  static const Color backgroundColor = Color(0xFFECEAE0);
  static const Color primaryBrown = Color(0xFF6F5643);
  static const Color lightBrown = Color(0xFF8B6B4A);
  static const Color cardColor = Color(0xFFCBB28A);
  static const Color warningRed = Color(0xFFB45B52);

  @override
  void initState() {
    super.initState();
    _checkBuddyStatus();
  }

  Future<void> _checkBuddyStatus() async {
    final user = authService.value.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['buddyUid'] != null) {
          setState(() {
            _currentBuddyUid = doc.data()?['buddyUid'];
          });
        }
      } catch (e) {
        debugPrint("Error checking buddy status: $e");
      }
    }
    setState(() => _isCheckingBuddy = false);
  }

  void _submitBuddyCode() async {
    final String inputCode = _codeController.text.trim().toUpperCase();

    if (inputCode.isEmpty) {
      _showSnackBar('Please enter a 6-character UID.', isError: true); 
      return;
    }

    if (inputCode.length != 6) {
      _showSnackBar('The buddy UID must be exactly 6 characters.', isError: true); 
      return;
    }

    setState(() => _isSubmittingCode = true);

    try {
      await authService.value.linkWithBuddy(inputCode);
      
      _codeController.clear(); 
      
      _showSnackBar('Successfully linked with your buddy!');
      _checkBuddyStatus();
    } catch (e) {
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      _showSnackBar(errorMsg, isError: true);
    } finally {
      setState(() => _isSubmittingCode = false);
    }
  }

  void _unlinkBuddy() async {
    if (_currentBuddyUid == null) return;

    try {
      await authService.value.unlinkBuddy(_currentBuddyUid!);
      
      _showSnackBar('Successfully unlinked from buddy.');
      
      setState(() {
        _currentBuddyUid = null;
      });
    } catch (e) {
      _showSnackBar('Failed to unlink. Please try again.', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? warningRed : primaryBrown,
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingBuddy) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryBrown)),
        ),
      );
    }

    Widget bodyContent;

    if (_currentBuddyUid != null) {
  bodyContent = FutureBuilder<List<dynamic>>(
    future: Future.wait([
      FirebaseFirestore.instance.collection('users').doc(authService.value.currentUser!.uid).get(),
      FirebaseFirestore.instance.collection('users').doc(_currentBuddyUid!).get(),
      FirebaseFirestore.instance.collection('users').doc(authService.value.currentUser!.uid).collection('streaks').doc('main').get(),
      FirebaseFirestore.instance.collection('users').doc(_currentBuddyUid!).collection('streaks').doc('main').get(),
    ]),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryBrown)));
      }

      final myDoc = snapshot.data![0];
      final buddyDoc = snapshot.data![1];
      final myStreakDoc = snapshot.data![2];
      final buddyStreakDoc = snapshot.data![3];

      final myData = myDoc.data() as Map<String, dynamic>?;
      final buddyData = buddyDoc.data() as Map<String, dynamic>?;
      final myStreakData = myStreakDoc.data() as Map<String, dynamic>?;
      final buddyStreakData = buddyStreakDoc.data() as Map<String, dynamic>?;

      final myDates = myStreakDoc.exists && myStreakData != null
          ? (myStreakData['dates'] as List<dynamic>?) ?? []
          : [];
      final buddyDates = buddyStreakDoc.exists && buddyStreakData != null
          ? (buddyStreakData['dates'] as List<dynamic>?) ?? []
          : [];

      return BuddiesPage(
        currentUserName: myData?['username'] ?? 'Me',
        currentUserPfpBase64: myData?['photoUrl'],
        currentUserStreak: myDates.length, // This now pulls the actual count
        buddyName: buddyData?['username'] ?? 'Buddy',
        buddyPfpBase64: buddyData?['photoUrl'],
        buddyStreak: buddyDates.length,    // This now pulls the actual count
        recentActivity: const [],
        onUnlink: _unlinkBuddy,
      );
    },
  );
    } else {
      bodyContent = SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 150),
              const Icon(Icons.people_alt_rounded, size: 80, color: primaryBrown),
              const SizedBox(height: 24),
              const Text(
                'Connect with a Friend',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryBrown),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter your buddy\'s unique 6-character UID below to link your habit trackers together!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: primaryBrown, height: 1.4),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _codeController,
                      maxLength: 6,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBrown, letterSpacing: 4),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'X7R2A9',
                        hintStyle: TextStyle(color: primaryBrown.withValues(alpha: 0.4), letterSpacing: 4),
                        counterText: '',
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSubmittingCode ? null : _submitBuddyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBrown,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmittingCode
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Link Buddy',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: bodyContent,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: lightBrown,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, 
  
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: "Habits"),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "Buddy"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
            );
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HabitsPage()),
            );
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
      ),
    );
  }
}