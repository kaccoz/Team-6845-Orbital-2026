import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crumb/services/auth_service.dart';
import 'package:crumb/screens/welcome_page.dart';
import 'package:crumb/screens/habits_page.dart';
import 'package:crumb/screens/home_page.dart';
import 'package:crumb/screens/connect_buddy_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // capture typing inputs for password changes
  final TextEditingController controllerEmail = TextEditingController();
  final TextEditingController controllerPassword = TextEditingController();

  final TextEditingController controllerCurrentPassword = TextEditingController();
  final TextEditingController controllerNewPassword = TextEditingController();

  final TextEditingController controllerCurrentEmail = TextEditingController();
  final TextEditingController controllerNewEmail = TextEditingController();

  final TextEditingController controllerCurrentUsername = TextEditingController();
  final TextEditingController controllerNewUsername = TextEditingController();

  File? _profileImage;
  String? _dbBase64Image;
  bool _isUploading = false;
  bool _hasProfilePicture = false;
  String? _myLinkUID;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkExistingProfilePicture();
  }

  static const Color backgroundColor = Color(0xFFECEAE0);
  static const Color primaryBrown = Color(0xFF6F5643);
    static const Color lightBrown = Color(0xFF8B6B4A);
  static const Color cardColor = Color(0xFFCBB28A);
  static const Color warningRed = Color(0xFFB45B52);

  Future<void> _checkExistingProfilePicture() async {
    final user = authService.value.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _myLinkUID = doc.data()?['linkUID'] ?? doc.data()?['linkCode'];
          
          if (doc.data()?['photoUrl'] != null) {
            _hasProfilePicture = true; 
            _dbBase64Image = doc.data()?['photoUrl'];
          }
        });
      }
    }
  }

  Future<void> _chooseImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: primaryBrown),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage();
                },
              ),
              if (_hasProfilePicture) 
                ListTile(
                  leading: const Icon(Icons.delete, color: warningRed),
                  title: const Text('Remove Current Photo', style: TextStyle(color: warningRed)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 25,
        maxWidth: 300,
        maxHeight: 300,
      );
      
      if (pickedFile != null) {
        setState(() => _isUploading = true);

        final bytes = await pickedFile.readAsBytes();
        final String base64Image = base64Encode(bytes);

        await authService.value.updateProfilePicture(base64Image);
        
        setState(() {
          _profileImage = File(pickedFile.path);
          _hasProfilePicture = true; 
        });

        if (mounted) showSnackBarSuccess('Profile picture updated!');
      }
    } catch (e) {
      if (mounted) showSnackBarFailure('Failed to update profile picture.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _removeImage() async {
    try {
      setState(() => _isUploading = true);

      await authService.value.deleteProfilePicture();

      setState(() {
        _profileImage = null; 
        _dbBase64Image = null;
        _hasProfilePicture = false; // Photo removed! Flip flag to false
      });

      if (mounted) showSnackBarSuccess('Profile picture removed.');
    } catch (e) {
      if (mounted) showSnackBarFailure('Failed to remove profile picture.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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
  
  Future<void> updatePassword() async {
    try {
    
      await authService.value.resetPasswordFromCurrentPassword(
        currentPassword: controllerCurrentPassword.text.trim(),
        newPassword: controllerNewPassword.text.trim(),
        email: controllerCurrentEmail.text.trim(),
      );
      showSnackBarSuccess('Password changed successfully!');

      // clean up after successful password change
      controllerCurrentEmail.clear();
      controllerCurrentPassword.clear();
      controllerNewPassword.clear();
    } catch (e) {
      showSnackBarFailure(
        'Failed to update password. Please check your credentials.',
      );
    }
  }

  Future<void> updateEmail() async {
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

  void updateUsername() async {
    try {
      await authService.value.updateUsername(
        username: controllerNewUsername.text.trim(),
      );
      showSnackBarSuccess('Username updated successfully!');

      controllerNewUsername.clear();
    } catch (e) {
      showSnackBarFailure(
        'Failed to update username. Please try again.',
      );
  }
  }

  void showSnackBarSuccess(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: primaryBrown,
        behavior: SnackBarBehavior.floating,
        content: Text(
          message, 
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
        backgroundColor: warningRed,
        behavior: SnackBarBehavior.floating,
        content: Text(
          message, 
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
                controller: controllerCurrentEmail, // 💡 Make sure this matches!
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
              onPressed: () {
                controllerCurrentEmail.clear();
                controllerCurrentPassword.clear();
                controllerNewPassword.clear();
                
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: primaryBrown),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBrown),
              onPressed: () async {
                if (controllerCurrentEmail.text.trim().isNotEmpty &&
                    controllerCurrentPassword.text.trim().isNotEmpty &&
                    controllerNewPassword.text.trim().isNotEmpty) {
                      await updatePassword();

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } else {
                      showSnackBarFailure('Please fill in all fields.');
                    }
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
              onPressed: () { 
                controllerCurrentEmail.clear();
                controllerNewEmail.clear();
                controllerPassword.clear();
                
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: primaryBrown),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBrown),
              onPressed: () async {
                if (controllerCurrentEmail.text.trim().isNotEmpty &&
                    controllerNewEmail.text.trim().isNotEmpty &&
                    controllerPassword.text.trim().isNotEmpty) {
                      await updateEmail();

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } else {
                      showSnackBarFailure('Please fill in all fields.');
                    }
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

  void _showUsernameUpdateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: const Text(
            'Update Username',
            style: TextStyle(color: primaryBrown, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controllerNewUsername,
                decoration: const InputDecoration(
                  labelText: 'New Username',
                  labelStyle: TextStyle(color: primaryBrown),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                controllerNewUsername.clear();

                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: primaryBrown),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBrown),
              onPressed: () async {
                String newUsername = controllerNewUsername.text.trim();
                if (newUsername.isNotEmpty) {
                  try {
                    await authService.value.updateUsername(username: newUsername);
                    await authService.value.currentUser!.reload(); 

                    if (context.mounted) {
                      setState(() {
                      });
                      Navigator.pop(context);
                      showSnackBarSuccess('Username updated successfully!');
                    }
                  } catch (e) {
                    debugPrint(e.toString());
                    showSnackBarFailure('Failed to update username. Please try again.');
                  }
                }
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: const Text(
            'Delete Account',
            style: TextStyle(color: warningRed, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WARNING: This action is permanent and cannot be undone. All of your user and habit data will be deleted.',
                style: TextStyle(color: primaryBrown, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controllerEmail,
                decoration: const InputDecoration(
                  labelText: 'Confirm Email',
                  labelStyle: TextStyle(color: primaryBrown),
                ),
              ),
              TextField(
                controller: controllerPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(color: primaryBrown),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                controllerEmail.clear();
                controllerPassword.clear();
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: primaryBrown),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: warningRed),
              onPressed: () async {
                final email = controllerEmail.text.trim();
                final password = controllerPassword.text.trim();

                if (email.isNotEmpty && password.isNotEmpty) {
                  try {
                    await authService.value.deleteAccount(email: email, password: password);
                    
                    controllerEmail.clear();
                    controllerPassword.clear();

                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const WelcomePage()),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    showSnackBarFailure('Failed to delete account. Check your credentials.');
                  }
                } else {
                  showSnackBarFailure('Please enter both email and password.');
                }
              },
              child: const Text(
                'Delete Permanently',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  ImageProvider? _getProfileImageProvider() {
    if (_profileImage != null) {
      return FileImage(_profileImage!); 
    }
    if (_dbBase64Image != null && _dbBase64Image!.isNotEmpty) {
      return MemoryImage(base64Decode(_dbBase64Image!));
    }
    return null; 
  }

  @override
  void dispose() {
    controllerEmail.dispose();
    controllerPassword.dispose();
    controllerCurrentPassword.dispose();
    controllerNewPassword.dispose();
    controllerCurrentEmail.dispose();
    controllerNewEmail.dispose();
    controllerCurrentUsername.dispose();
    controllerNewUsername.dispose();
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
              
              SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryBrown,
                      ),
                    ),

                    const Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.menu, size: 32, color: primaryBrown),
                  ),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E332E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
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
                  ),
                ],
                ),
              ),

              const SizedBox(height: 15),

              // AVATAR
              GestureDetector(
                onTap: _chooseImage,
                child: CircleAvatar(
                  radius: 88,
                  backgroundColor: primaryBrown,
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: cardColor,
                    backgroundImage: _getProfileImageProvider(), 
                    child: _isUploading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(primaryBrown),
                          )
                        : (!_hasProfilePicture && _profileImage == null)
                            ? const Icon(Icons.camera_alt, size: 35, color: primaryBrown)
                            : null,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // USERNAME
              Text(
                authService.value.currentUser?.displayName ?? 'Username',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: primaryBrown,
                ),
              ),

              const SizedBox(height: 8),

              // LINK UID
              Text(
                _myLinkUID != null ? "Your UID: $_myLinkUID" : "Loading UID...",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryBrown,
                  letterSpacing: 1.1,
                ),
              ),

              const SizedBox(height: 32),


            
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
                    _buildMenuRow('Update Username', _showUsernameUpdateDialog),
                    const Divider(
                      color: primaryBrown,
                      thickness: 1,
                      height: 24,
                    ),

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
                  onPressed: _showDeleteAccountDialog,
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
        backgroundColor: lightBrown,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 3, 
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
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ConnectBuddyPage()),
            );
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
          onPressed: onUpdatePressed,
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
