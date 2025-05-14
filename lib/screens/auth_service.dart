import 'package:firebase_auth/firebase_auth.dart';
import 'package:mini_ui/screens/screen_login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import for Firestore

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } catch (e) {
      print('Error creating user: $e');
    }
    return null;
  }

  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      return cred.user;
    } catch (e) {
      print('Error logging in: $e');
    }
    return null;
  }

  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();

    // Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    // Navigate to login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LogInScreen()),
    );
  }

  Future<String> resetPassword(String email, BuildContext context) async {
    try {
      // Check if the email exists in any of the collections
      final collections = [
        "homebounds",
        "volunteers",
        "guardians",
        "organizations"
      ];
      bool emailExists = false;

      for (String collection in collections) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection(collection)
            .where('email', isEqualTo: email.trim())
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          emailExists = true;
          break;
        }
      }

      if (!emailExists) {
        // Clear any existing SnackBars before showing a new one
        return 'Email not found';
      }

      // Proceed with sending the password reset email
      await _auth.sendPasswordResetEmail(email: email);
      return 'Password reset email sent. Please check your inbox.';
    } catch (e) {
      return 'Failed to send password reset email. Please try again.';
    }
  }
}
