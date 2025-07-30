import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  Future<String> signUpUser({
    required String email,
    required String password,
    required String name,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty || password.isNotEmpty || name.isNotEmpty) {
        // Create user with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Save user data to Firestore
        await _firestore.collection("Users").doc(cred.user!.uid).set({
          "Name": name,
          "Email": email,
          "Id": cred.user!.uid,
          "Wallet": "0",
        });

        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> signInUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty || password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<String> resetPassword(String email) async {
    String res = "Some error occurred";
    try {
      await _auth.sendPasswordResetEmail(email: email);
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> deleteuser() async {
    String res = "Some error occurred";
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.delete();
        res = "success";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<void> SignOut() async {
    try {
      // Sign out from Firebase Auth
      await _auth.signOut();

      // Clear all user data from SharedPreferences
      await SharedPreferenceHelper().saveUserName("");
      await SharedPreferenceHelper().saveUserEmail("");
      await SharedPreferenceHelper().saveUserWallet("");
      await SharedPreferenceHelper().saveUserId("");
      await SharedPreferenceHelper().saveUserProfile("");

      print("User signed out successfully and data cleared");
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
