import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crumb/services/auth_service.dart';
import 'package:crumb/screens/welcome_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // capture typing inputs for password changes
  final TextEditingController controllerEmail = TextEditingController();
  final TextEditingController controllerPassword = TextEditingController();

  final TextEditingController controllerCurrentPassword =
      TextEditingController();
  final TextEditingController controllerNewPassword = TextEditingController();

  final TextEditingController controllerCurrentEmail = TextEditingController();
  final TextEditingController controllerNewEmail = TextEditingController();

  static const Color backgroundColor = Color(0xFFECEAE0);
  static const Color primaryBrown = Color(0xFF6F5643);
  static const Color cardColor = Color(0xFFCBB28A);
  static const Color warningRed = Color(0xFFB45B52);

  void logout() async {
    try {
      await authService.value.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(e.message);
    }
  }

  void updatePassword() async {
    try {
      await authService.value.resetPasswordFromCurrentPassword(
        currentPassword: controllerCurrentPassword.text.trim(),
        newPassword: controllerNewPassword.text.trim(),
        email: controllerEmail.text.trim(),
      );
      showSnackBarSuccess('Password changed successfully!');

      // Clean up controllers after a successful password change
      controllerCurrentPassword.clear();
      controllerNewPassword.clear();
    } catch (e) {
      showSnackBarFailure(
        'Failed to update password. Please check your credentials.',
      );
    }
  }

  void updateEmail() async {
    try {
      await authService.value.changeEmail(
        currentEmail: controllerCurrentEmail.text.trim(),
        newEmail: controllerNewEmail.text.trim(),
        password: controllerPassword.text.trim(),
      );
      showSnackBarSuccess(
        'A verification link has been sent to your new email address. Please verify to complete the change.',
      );

      controllerEmail.clear();
      controllerCurrentPassword.clear();
      controllerNewPassword.clear();
    } catch (e) {
      showSnackBarFailure(
        'Failed to update email. Please check your credentials.',
      );
    }
  }

  void showSnackBarSuccess(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // 💡 Removed 'const' here because message changes dynamically
        backgroundColor: primaryBrown,
        behavior: SnackBarBehavior.floating,
        content: Text(
          message, // 🔄 Now uses the passed-in custom string!
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        showCloseIcon: true,
      ),
    );
  }

  void showSnackBarFailure(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // 💡 Removed 'const' here too
        backgroundColor: warningRed,
        behavior: SnackBarBehavior.floating,
        content: Text(
          message, // 🔄 Now uses the passed-in custom string!
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        showCloseIcon: true,
      ),
    );
  }

  void _showPasswordChangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: const Text(
            'Change Password',
            style: TextStyle(color: primaryBrown, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controllerEmail,
                decoration: const InputDecoration(
                  labelText: 'Confirm Email',
                  labelStyle: TextStyle(color: primaryBrown),
                ),
              ),
              TextField(
                controller: controllerCurrentPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: primaryBrown),
                ),
              ),
              TextField(
                controller: controllerNewPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: primaryBrown),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: primaryBrown),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBrown),
              onPressed: () {
                Navigator.pop(context); // Close dialog window overlay
                updatePassword(); // Fire off your Firebase execution method!
              },
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEmailChangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: const Text(
            'Change Email',
            style: TextStyle(color: primaryBrown, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controllerCurrentEmail,
                decoration: const InputDecoration(
                  labelText: 'Current Email',
                  labelStyle: TextStyle(color: primaryBrown),
                ),
              ),
              TextField(
                controller: controllerNewEmail,
                decoration: const InputDecoration(
                  labelText: 'New Email',
                  labelStyle: TextStyle(color: primaryBrown),
                ),
              ),
              TextField(
                controller: controllerPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: primaryBrown),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: primaryBrown),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBrown),
              onPressed: () {
                Navigator.pop(context);
                updateEmail(); // Calls your existing logic
              },
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    controllerEmail.dispose();
    controllerPassword.dispose();
    controllerCurrentPassword.dispose();
    controllerNewPassword.dispose();
    controllerCurrentEmail.dispose();
    controllerNewEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // HEADER ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.menu, size: 32, color: primaryBrown),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryBrown,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E332E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 4),
                        Text(
                          '24',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // AVATAR
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryBrown, width: 8),
                  image: const DecorationImage(
                    image: NetworkImage('https://placehold.co/150'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // USERNAME
              const Text(
                'User888',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: primaryBrown,
                ),
              ),
              const SizedBox(height: 24),

              // MENU OPTIONS CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    _buildMenuRow('Update Username', () {
                      // Add username change dialog here later
                    }),
                    const Divider(
                      color: primaryBrown,
                      thickness: 1,
                      height: 24,
                    ),

                    // LINKED RIGHT HERE: Triggering the change password overlay popup!
                    _buildMenuRow('Change Password', _showPasswordChangeDialog),

                    const Divider(
                      color: primaryBrown,
                      thickness: 1,
                      height: 24,
                    ),
                    _buildMenuRow('Change Email', _showEmailChangeDialog),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: 140,
                child: ElevatedButton(
                  onPressed: logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF6F5643,
                    ), // Your primary brown
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warningRed,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF8B6B4A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildMenuRow(String title, VoidCallback onUpdatePressed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        ElevatedButton(
          onPressed:
              onUpdatePressed, // Runs the specific function when clicked!
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBrown,
            foregroundColor: cardColor,
            shape: const StadiumBorder(),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          child: const Text(
            'Update',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
