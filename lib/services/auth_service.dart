import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  String _generateLinkCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    
    User? newUSer = userCredential.user;

    if (newUSer != null) {
      String defaultUsername = email.split('@')[0];
      await newUSer.updateDisplayName(defaultUsername);
      await newUSer.reload();

      String uniqueCode = _generateLinkCode();
      await FirebaseFirestore.instance.collection('users').doc(newUSer.uid).set({
        'username': defaultUsername,
        'email': email,
        'linkCode': uniqueCode,
        'buddyUid': null, 
        'createdAt': FieldValue.serverTimestamp(),
      });    
    }

    return userCredential;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> resetPassword({
    required String email,
  }) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUsername ({
    required String username,
  }) async {
    await currentUser!.updateDisplayName(username);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .update({'username': username});
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
    await currentUser!.reauthenticateWithCredential(credential);

    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).delete();

    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = 
        EmailAuthProvider.credential(email: email, password: currentPassword);
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

 Future<void> changeEmail({
    required String currentEmail,
    required String newEmail,
    required String password,
  }) async {
    AuthCredential credential = 
        EmailAuthProvider.credential(email: currentEmail, password: password);
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.verifyBeforeUpdateEmail(newEmail); 

    await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser!.uid)
      .update({'email': newEmail});
  }

  Future<void> updateProfilePicture(String base64String) async {
  if (currentUser == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser!.uid)
      .set({
        'photoUrl': base64String,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
  }

  Future<void> deleteProfilePicture() async {
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .update({
          'photoUrl': FieldValue.delete(),
        });
  }

  Future<void> unlinkBuddy(String buddyUid) async {
    if (currentUser == null) return;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    batch.update(firestore.collection('users').doc(currentUser!.uid), {
      'buddyUid': null,
    });

    batch.update(firestore.collection('users').doc(buddyUid), {
      'buddyUid': null,
    });

    await batch.commit();
  }
}